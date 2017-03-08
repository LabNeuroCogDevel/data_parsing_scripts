#!/usr/bin/env Rscript

library(dplyr)
library(tidyr)
library(igraph)

## read in adj matrix. zero out diag + lower tri
readadjmat <- function(f){
 # read in data and make a matrix
 d<-read.table(f) %>% as.matrix %>% unname
 # zero the columns we dont care about
 d[!upper.tri(d)] <- 0
 return(d)
}

# load all the data
mkbig3d <- function() {
  ## find all reward
  allrewardlist <- Sys.glob('/Volumes/Phillips/Finn/Reward_Rest/subjs/1*/preproc/1*_power264.txt')
  # limit to just the first visit we have
  firstreward <-
   data.frame(path=allrewardlist) %>% 
   mutate(iddate=gsub('.*subjs/([0-9_]+).*','\\1',path)) %>% 
   separate(iddate,c('id','date')) %>% 
   group_by(id) %>% 
   mutate(r=rank(date)) %>% 
   filter(r==1) %>% 
   ungroup
  
  # read in all adj matricies
  reward.3d <- sapply(firstreward$path %>% as.character(),FUN=readadjmat,simplify = 'array')
  
  ## read in pnc
  pnc.f<-"/Volumes/Zeus/PNC_brenden/dxwithrestfor_fsubmission_03082017.txt"
  pnc.d<-read.table(pnc.f,header=T)
  
  pncpath <- function(x) paste0(collapse="",'/Volumes/Zeus/preproc/PNC_rest/MHRest/',x,'/preproc/',x,'_power264.txt')
  pnc.flist <- sapply(pnc.d$sub,pncpath)
  pnc.3d <- sapply(pnc.flist,FUN=readadjmat,simplify = 'array')
  
  big3d <- abind(reard.3d,pnc.3d)
}

# given a 3d matrix get communties for the meaned graph
meangraphcom <- function(m,cutoff) {
 d <- apply(m,1:2,mean)
 #cutoff<-quantile(d,quant)
 d[d<cutoff] <-0
 d %>% 
  graph_from_adjacency_matrix(weighted=T,mode='undirected') %>% 
  cluster_infomap
}

### mean and nmi
compWithIdx <- function(mats,idx.1,cutoff) {
  idx.2 <- setdiff(1:dim(mats)[3],idx.1)
  c.1 <- meangraphcom(mats[,,idx.1],cutoff)
  c.2 <- meangraphcom(mats[,,idx.2],cutoff)
  compare(c.1, c.2, method ="nmi")
}

# shuffle labels and computer nmi
permnmi <- function(mat,n.1) {
  nall <- dim(mat)[3]
  # shuffle all the indexes and grab the first n.1 of them
  permidx <- sample( 1:nall )[1:n.1]
  # get nmi of this label shuffle
  perm1 <- compWithIdx(big3d,permidx,cutoff)
}

######### 

big3d <- mkbig3d()
cutoff <- quantile(big3d,.9)

## actual nmi value for real labels
nreward <-dim(reward.3d)[3]
rewardidxs<-1:nreward
actual.nmi <- compWithIdx(big3d,rewardidxs,cutoff)

# run tests
nreps=3
dist <- sapply(1:nreps,function(x){permnmi(big3d,nreward)})
