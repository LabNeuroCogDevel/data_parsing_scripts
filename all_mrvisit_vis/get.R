#!/usr/bin/env Rscript

library(dplyr)     # %>%,mutate,select,etc
library(ggplot2)   # ggplot
library(xlsx)      # read.xlsx
library(lubridate) # yms
require("RPostgreSQL")

## DB settings
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "lncddb",
                 host = "arnold.wpic.upmc.edu", port = 5432,
                 user = "postgres")

## fetch data
sqlquery <- " select * from visit natural join visit_study natural join person where vtype not like 'Behavioral';"
r<-dbSendQuery(con,sqlquery)
d<-fetch(r,n=-1)
dbClearResult(r)

# get pet data

petage  <- 
  read.xlsx('../pet_demo/pet.xlsx',sheetName="Top") %>%    # sheet 1
  mutate(age= as.numeric(ymd(date) -  ymd(dob) )/365.25 ) %>%
  mutate(study='PET') %>%
  select(age,study,pid=ID)

## make id's ranked by
givid <- function(ids) { sapply(FUN=function(x) {which(x == unique(ids))[1]}, ids) }
d.agerank <- 
  d %>% 
  select(age,study,pid) %>%
  rbind(petage) %>%
  # remove r01 and r21 from study names
  mutate(study=gsub('R[02]1','',study)) %>%
  # only look at long. studies where we have reasonable data (age in approp. range)
  filter(age>8 & age< 50 & study %in% c('Cog','Reward','PET')) %>%
  # make id order by age of first visit
  group_by(pid) %>% 
  mutate(firstage=min(age)) %>% 
  ungroup %>% 
  arrange(firstage) %>% 
  mutate(agerankid=firstage * 10000 + pid)  %>% 
  group_by(study) %>%
  mutate(id=givid(agerankid))

## plot
p<-
  ggplot(d.agerank) +
  aes(y=id,x=age,color=study) +
  geom_point() +
  geom_line(aes(group=id))  +
  theme_bw() +
  facet_grid(study~.) 

ggsave(p,file="longStudies.png")


## summary stats printed out
d.agerank %>% 
  # first count how many times each subject has been in
  # also get thier min and max ages
  group_by(study,id) %>% 
  summarize(y=min(age),o=max(age),n=n()) %>% 
  # now get min/max and count stats for the study
  group_by(study) %>% 
  summarise(y=min(y),o=max(o),min(n),mean(n),max(n)) %>% 
  # show it
  print.data.frame(row.names=F)

