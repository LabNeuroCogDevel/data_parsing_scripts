# written Dec2013, explored again Dec2016
# 2013 subject status 
# https://docs.google.com/spreadsheet/ccc?key=0An1eY3RXeRiJdHA0U2pGTjdzakhjQ1YwdkVya0EtT1E#gid=0

library(plyr)
library(dplyr)
library(magrittr)
library(ggplot2)

inrange <- function(x,a,b){x>=a&x<=b}
headoff <- function(d,off=0,n=10) { 
 l<-dim(d)[1];
 b<-min(off,l);
 e<-min(l,off+n);
 print(d[b:e,])
}

# make text of eyd using perl
mktxt <- function(id) {
  eydparser <- '/mnt/v1/home/foranw/src/score/dataFromAnyEyd.pl'
  globpat <- sprintf('rawdata/%d/%d*.eyd',id,id)
  eyd <- Sys.glob(globpat)
  if(length(eyd)==0L) {
   warning('no file matcching ',globpat)
   return(NULL)
  }

  txt <- file.path('txt',basename(gsub('eyd$','txt',eyd)))
  if(!file.exists(txt) ) {
    system(sprintf('%s %s > %s',eydparser,eyd,txt))
  }

  return(txt)
}

readtxt <- function(txt){

  if(!file.exists(txt) ) return(NULL)

  # read in and kill junk bits
  d<-read.table(sep="\t",header=T,file=txt)
  names(d) <- c('xdat','pup','horz','vert')

  # kill all data before first fixation, first xdat of 9
  r <- rle(d$xdat)
  idxs<-cumsum(r$lengths)
 
  firstfix <- first(which(r$values==8))
  lastfix  <- last(which(r$values==9))
  if(is.na(firstfix) || firstfix==lastfix ) { warning(txt,' does not has no or only one "9" xdat!'); return(NULL)}

  
  # truncate data to only 
  startidx <- idxs[firstfix]
  endidx   <- idxs[lastfix-1]
  #print(startidx)
  #print(endidx)
  #print(nrow(d))
  d<-d[ c(startidx:endidx), ]

  d$t <- 1:nrow(d)/60
  d$event.type <- floor(log(d$xdat,base=10))
  d$subj=gsub('.*/([0-9]+).*','\\1',txt)
  d$sampleno <- 1:nrow(d)

  return(d)
}

quickplot <- function(d) {
  d %>% 
   filter(horz<300,vert<300,horz+vert>0) %>% 
   ggplot() + 
   aes(x=horz,y=vert,color=as.factor(xdat),group=xdat) + 
   geom_path() +
   facet_grid(event.type~.) +
   theme_bw()
}

eyeusable <- function(d){
d %>% mutate(
      usable='good',
      usable=ifelse(horz>300|vert>300,'offscreen',usable),
      usable=ifelse(horz==0|vert==0,'blink',usable)
      # ignoring pupil==0, previously included that
   )
}
calcgood <- function(d) {

 cnt <-
   eyeusable(d) %>% 
   #filter(event.type==1) %>% # only want to look at memory
   group_by(subj,usable) %>%
   summarise(n=n()) %>% mutate(t=n/60,n=n/sum(n)) %>%
   # make long
   gather(metric,val,-subj,-usable) %>% 
   unite(type,usable,metric) %>% 
   spread(type,val) 

 # make old names
 nidx <- grep('_n',names(cnt))
 names(cnt)[nidx] <- gsub('_n','',names(cnt)[nidx])

 return(cnt)
}


getsubjinfo <- function() {
	subjinfo <- 
	  read.table('CFMTEyeSubList_20161207.csv',sep=',',h=T) %>% 
	  set_colnames(c('subj','cohort','agegrp','gender','age')) %>%
	  mutate( cohort=factor(cohort,levels=1:2,labels=c('TD','ASD')),
				 agegrp=factor(agegrp,levels=1:3,labels=c('kids','ado','adult')),
				 gender=factor(gender,levels=1:2,labels=c('F','M')))
}



alltxtfiles <- function() {
	allids <- strsplit(Sys.glob('rawdata/*/'),'/')  %>%
	 sapply(FUN='[',2 ) %>%
	 #gsub(pattern='-',replace='.') %>%
	 as.numeric %>% na.omit

	# make all ids
	alltxt <- unlist( lapply(allids,mktxt) )
}

# where (x,y,w,h) are the rois
readrois <- function() {
	aslx <-  (640)/261
	asly <-  (480) /240
	ROI.in <-
	 read.table('ROImatout.txt',header=T,comment.char="") %>% 
	 select(xdat=XDAT,cond,t=ttype,x,y,w,h,face=face.,roi=roi.)  %>%
	 mutate(fnum = round((x-199)/100) + (y>270)*10,
	  roi=factor(roi,levels=1:4,labels=c("face","mouth","nose","eyes")),
	  xmax=(x+w)/aslx,
	  ymax=(y+h)/asly,
	  x=x/aslx,
	  y=y/asly) 

	ROI <- 
	 ROI.in %>%
	 group_by(xdat,roi,fnum) %>% 
	 summarise(x=min(x),y=min(y),xmax=max(xmax),ymax=max(ymax)) %>%
	 ungroup() %>%
	 mutate(rid=1:n())
}

# read in a txt file 
# and give percent of time person was looking in an roi
subjroipcnt <- function(txt) {
 if(!file.exists(txt)){warning(txt, ' DNE?!'); return(NULL)}
 
 d<- readtxt(txt) %>% eyeusable 

 d %<>% 
   filter(usable=='good') %>%  # this step is questionalbe
   merge(ROI,by='xdat')
 if(nrow(d)==0) {warning(txt,' has no roi matching xdats'); return(NULL) }

 d %>%
  mutate(inroi=inrange(horz,x,xmax)&inrange(vert,y,ymax)) %>%
  group_by(subj,roi) %>% 
  summarise(r=sum(inroi)/length(unique(sampleno)))
}



######
# do stuff
######

## get all data

alltxt   <- alltxtfiles()
ROI      <- readrois()
alldata  <- lapply(alltxt,readtxt) %>% bind_rows()
subjinfo <- getsubjinfo()

###### Good/Bad Saccades
sacmetrics <- calcgood(alldata) %>%
  merge(subjinfo,all.x=T)

# drop 13/159 ?
dropsubjs <- sacmetrics %>% filter(is.na(gender)) 
sacmetrics %<>% filter(!is.na(gender))

# view
#keepcols <- c('subj',setdiff(names(sacmetrics),names(subjinfo)))
p.sacmet <- 
  sacmetrics %>% select(-blink_t,-good_t,-offscreen_t) %>%
  gather('metric','ratio',-subj,-gender,-agegrp,-cohort,-age) %>% 
  ggplot() + 
   aes(x=metric,y=ratio,color=cohort,shape=agegrp) +
   geom_point(position=position_dodge(.75)) +
   geom_line(aes(group=paste(subj)),position=position_dodge(.75),alpha=.1) +
   geom_boxplot(aes(size=NULL)) +
   theme_bw() + 
   ggtitle('eye tracking quality')  
print(p.sacmet)
ggsave('sacquality_color.png',p.sacmet)

p.sacgood <- 
  sacmetrics %>% 
  ggplot() + 
   aes(x=gender,y=good_t/60,color=agegrp,shape=cohort) +
   geom_boxplot(aes(size=NULL)) +
   geom_point(position=position_dodge(.75)) +
   theme_bw() + facet_grid(.~cohort) +
   ylab('minutes') +
   ggtitle('time with stable eyetracking durning memory')  
print(p.sacgood)
ggsave('sacgood_memonly.png',p.sacgood)

#lm(data=sacmetrics, good ~ cohort) %>% summary 
# slope: 0.00323; p-value: 0.003231
t.test(data=sacmetrics, good ~ cohort)
#
#        Welch Two Sample t-test
#
#data:  good by cohort
#t = 2.8863, df = 109.45, p-value = 0.004697
#alternative hypothesis: true difference in means is not equal to 0
#95 percent confidence interval:
# 0.01650607 0.08884839
#sample estimates:
# mean in group TD mean in group ASD 
#        0.9103313         0.8576541 


# 

########################

# inspect roi
roi.plot <- ROI %>% ggplot() +geom_rect(alpha=0) + aes(color=as.factor(fnum),xmin=x,ymin=y,xmax=xmax,ymax=ymax) + facet_wrap(~xdat)
roi.plot <- ROI.in %>% ggplot() +geom_rect(alpha=0) + aes(color=as.factor(fnum),xmin=x,ymin=y,xmax=xmax,ymax=ymax) + facet_wrap(~xdat)
print(roi.plot)

add.roi <- function(p,ROItable) {
   p + geom_rect(data=ROItable,
              aes(xmin=x,ymin=y,xmax=xmax,ymax=ymax,
                  x=NULL,y=NULL,fill=NULL,color=as.factor(roi)),alpha=0
            )
}


p <- (d<-readtxt(alltxt[2]) ) %>% quickplot


g1 <- 
  d %>% 
   filter(horz<300,vert<300,horz+vert>0) %>% 
   ggplot() + 
   aes(x=horz,y=vert,full=NULL) + 
   geom_rect(data=ROI,
              aes(xmin=x,ymin=y,xmax=xmax,ymax=ymax,
                  x=NULL,y=NULL,fill=NULL,color=as.factor(roi)),alpha=0
            )+
   geom_point(size=.5) +
   facet_wrap(~xdat) +
   theme_bw() 
print(g1)

ggsave(g1,file='alldata.png')


####

# roi should really be merged by trial not xdat.this is courser

# d <- alldata %>% filter(subj==102) %>% merge(ROI,by='xdat')%>% mutate(inroi=inrange(horz,x,xmax)&inrange(vert,y,ymax)) 
# 
# d %>% group_by(subj,xdat,roi) %>% summarise(r=sum(inroi)/length(unique(sampleno))) %>% filter(xdat==111)
# 
# there be dragons here:
#  there are often 3 faces each with a total of 4 rois  (12 total rois) that are parsed for each eye tracked position ("sample")
# l is the number of samples
# n is the number of comparisons (nsamlples*nrois for that xdat)
# d %>% group_by(subj,roi) %>% summarise(n=n(),l=length(unique(sampleno)),r=sum(inroi)/l)
# E.G.
#   subj    roi     n     l           r
#  <chr> <fctr> <int> <int>       <dbl>
#1   102   face 54502 17920 0.658593750

percentinROI <- lapply(alltxt,subjroipcnt) %>% bind_rows()


wholookwhat <- percentinROI %>% spread(roi,r) %>% merge(subjinfo,by='subj')
write.table(wholookwhat,file="wholookedatwhat.txt",sep="\t",row.names=F,quote=F)

p.noroi <-
 ggplot(wholookwhat) +
 aes(x=age,y=1-face,color=cohort,shape=gender) +
 geom_point() +
 geom_smooth(method='lm',aes(shape=NULL))   +
 ylab('out of roi') +
 theme_bw() +
 ggtitle('eyetracked not in roi')

ggsave('outofroi.png',p.noroi)

head(wholookwhat)

####
# what is the difference between rois

screenx <-  (1440)/261
screeny <-  (900) /240
ROI.screen <- ROI %>% mutate( x=x*screenx,xmax=xmax*screenx,y=y*screeny,ymax=y*screeny)
ggplot() %>% add.roi(ROI.screen)  + facet_wrap(~xdat)
head(ROI)

##########




#  viewsub <- function(id) {
#    # make txt file
#    txt<-mktxt(id) 
#    d<-readtxt(txt)
#    
#    # get rid of super large values or all zeros/negative
#    d.good <- subset(d,!((horz>400|vert>300|pup>200)|(horz<=0&vert<=0&pup<=0)))
#    
#    # label trials -- inefficent 
#    j<-1; d.good$trial <- j;
#    for(i in 1:(nrow(d.good)-1) ){
#     if( (d.good$xdat[i]==9) && (d.good$xdat[i+1]!=9) ){ j=j+1 }
#     d.good$trial[i+1] <- j
#    }
#    
#    # show number of samples and xdats in each trial
#    ddply(d.good,.(trial),function(dx){cbind(n=nrow(dx),xdats=length(rle(dx$xdat)$values))})
#  
#    # plot each trial
#    ddply(d.good,.(trial),function(dx){
#      print(ggplot(dx,aes(x=horz,y=vert)) + 
#                        geom_point(aes(color=as.factor(xdat),size=pup))+
#                        geom_path()+theme_bw() +
#                        scale_x_continuous(limits=c(0,400)) + scale_y_continuous(limits=c(0,250)) + 
#                        scale_size_continuous(limits=c(0,100)) +
#                        ggtitle(sprintf("trial %d - %d samples",dx$trial[1], nrow(dx))))
#      cat('any key for next window\n')
#      readline()
#    })
#  }

