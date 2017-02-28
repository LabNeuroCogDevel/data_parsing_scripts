library(dplyr)
library(tidyr)
library(magrittr)
library(lubridate)

# ugly hack to separate the protocol name from the fov in something like 'under_score_name_fieldxview'
# SHOULD HAVE gsub'ed
lastunder <- function(str) {
 sapply( FUN=function(x) {x[length(x)]}, strsplit(as.character(str),'_') )
}
allbutlastunder <- function(str) {
 sapply( FUN=function(x) {paste(collapse="_",x[ifelse(length(x)==1,1,-length(x))])},strsplit(as.character(str),'_') )
}

d<-
 read.table('abcd.info') %>%
 set_colnames(c('id','age','sex','proto','runum','start','end','ndcm')) %>%
 mutate(age=gsub('0*([^0][0-9]?)[A-Z]','\\1',age)) %>%
 mutate_each(funs(ymd_hm),start,end) %>%
 mutate(dur=end-start) %>%
 mutate(fov=lastunder(proto)) %>%
 mutate(proto=allbutlastunder(proto)) 

d.noqa <- 
 d %>%
 filter(!grepl('daily|abcd|phantom',id,ignore.case=T)) 

bysubj <-
 d.noqa %>%
 group_by(id,age,sex) %>%
 summarise(
  start=min(start),
  end=max(end),
  dur=(end-start)/(60^2),
  nproto=n(),
  ntask=length(grep('task',proto)),
  nrest=length(grep('rest',proto)),
  nMIcomp=length(which(grepl('ncentive',proto)&ndcm==411)),
  nStopcomp=length(which(grepl('task_Stop',proto)&ndcm==445)),
  nNBcomp=length(which(grepl('n-back',proto)&ndcm==370)),
  nrestcomp=length(which(grepl('rest',proto)&ndcm==383))
  )

bssave <- bysubj %>% select(-start,-end) %>% arrange(age) 
bssave %>% print.data.frame(row.names=F)
write.table(bssave,file="subjs.txt",sep="\t",row.names=F,quote=F)

#lm(data=bysubj,dur~age) %>% summary %>% print


byproto <-
 d.noqa %>%
 group_by(proto) %>%
 #summarise_each(funs(mean),runum,ndcm,dur)
 summarise(protonum=mean(runum),ndcm=mean(ndcm),dur=mean(dur),nsubjs=length(unique(id)),nfov=length(unique(fov)),n=n(),avgpp=n/nsubjs)

bpsave <- byproto %>% filter(n>40) 
bpsave %>% print.data.frame(row.names=F)
write.table(bpsave,file="protos.txt",sep="\t",row.names=F,quote=F)
