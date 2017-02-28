library(dplyr)
library(tidyr)
library(xlsx)
library(curl)

gsurl<- 'https://docs.google.com/spreadsheets/d/1Sk5I09hybI-4VJKd_6ST1d_J76fVd1D8zVjZ9vBLYd0/pub?output=xlsx'
curl_download(gsurl,'pet.xslx')

sex  <- read.xlsx('pet.xlsx',sheetName="PreTest")    # sheet 3
demo <- read.xlsx('pet.xlsx',sheetName="Demographic")# sheet 7

#demo <- read.table('demo.txt',sep="\t",quote=NULL,header=T)
#sex <- read.table('sex.txt',sep="\t",quote=NULL,header=T)

eth <-
 demo %>%
 select(PETROWID,hispanic,american_indian,asian,black,hawaiian,white) %>% 
 gather('eth','ethbool',-PETROWID) %>%
 filter(ethbool==T) %>%
 group_by(PETROWID) %>%
 filter(!PETROWID==1) %>%  # remove redudant row 1 and 100
 summarise(eth=paste(collapse=",",sort(eth)))

# merge the two together and save file
ethsex <- merge(eth,sex[,c('ID','PETROWID','sex')],by='PETROWID')  %>% select(ID,eth,sex,PETROWID)
write.table(ethsex,file="eth_sex.csv",sep=',',quote=F,row.names=F)

# # subset just what nathian wants
# nr.list<-c('11482','11484','11228','11486','11468','11487','11489','11275','11490','11491','11425','11492','11493','11248','11495','11496','11497','11370','11498','11393','11499','11501','11502','11503','11504','10195','11506','11507','11488','11509','11510','11512','11395','11513','11508','11514','11515','11516','10985','11517','11518','11519','11520','11338','11521','11522','11524','11434','11526','11527','11528','11529','11530','11531','11533','11535','11536','11537','11538','11540','11541','11542','11543','11544','11546','10880','11547','11048','11548','11549','11550','11551','11554','11555','11557','11558','11560','11561','11562','11564','11565','11270','11568','11570','11571','11573','11574','11575','11576','11577','11578','11579','10982','11581','11582','11589')
# ethsex.sub <- ethsex %>% filter(ID %in% nr.list)
# nr.list [ ! nr.list %in% ethsex.sub$ID ]
# write.table(ethsex.sub,file="eth_sex_sub.csv",sep=',',quote=T,row.names=F)

# check no lunaid repeated
repeatIDs <- ethsex %>% group <- by(ID) %>% summarise(n=n()) %>% filter(n>1)
if(nrow(repeatIDs) > 0L) stop('have repeat IDs! -- not  1-to-1 PETROWID-lunaid')


# count by eth+gender
count <- 
 ethsex %>% 
 select(-ID) %>%
 group_by(eth,sex) %>% 
 summarise(n=n()) %>% 
 spread(sex,n)

count.nonwhite <-
 count %>% 
 ungroup %>% 
 mutate(eth=ifelse(eth=="white","white-only","non-white")) %>% 
 group_by(eth) %>% 
 summarise_each(funs(sum(.,na.rm=T)))
