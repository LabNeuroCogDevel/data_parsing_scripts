#!/usr/bin/env Rscript

library(dplyr)
library(lubridate)
library(ggplot2)

difmin <- function(start,end) { as.numeric(seconds(end-start))/60 }

readtimes <-function(f,studyname) {
 read.table(f) %>% 
 `colnames<-`(c('date','age','sex','calstart','mrstart','mrend','id')) %>%
 mutate_each(funs(hms),calstart,mrstart,mrend) %>%
 mutate( totaltime=difmin(calstart,mrend),
         scantime=difmin(mrstart,mrend),
         tilscan=difmin(calstart,mrstart),
         study=studyname)
}

d<- rbind(
 readtimes('txt/rescan/times.txt','rescan') ,
 readtimes('txt/p5/times.txt','p5')
)


## view summary
d.smry <- 
   d %>% 
   group_by(study) %>% 
   summarise(
     m=mean(scantime),
     sd=sd(scantime),
     mx=max(scantime),
     mn=min(scantime),
     n=n()) 
d.smry %>% print.data.frame(row.names=F)
write.table(d.smry,file="txt/summary.txt",row.names=F,quote=F,sep="\t")

## plot
p <- 
  ggplot(d) +
  aes(x=study,y=scantime) +
  geom_violin() +
  geom_point(alpha=.4) +
  theme_bw() +
  ggtitle('scan durations')

ggsave(p,file='img/scanduration.png')
