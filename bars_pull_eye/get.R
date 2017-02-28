library(dplry)

##
# function to read in sacc file and add date column
readeyefile <- function(f) {
 finfo <- strsplit(basename(f),'\\.')[[1]]
 # we want to merge trial data, so make sure we have it
 tf <- gsub('\\.sac\\.','.trial.',f)
 if(! file.exists(tf)) { return(NULL) }
 # load the trial data
 trial <- read.table(tf,sep="\t",header=T) %>%
          mutate(date=finfo[2], subj=finfo[1], run=finfo[3])
 # load the saccade data
 sacc  <- read.table(f,header=T,sep="\t") %>% 
          mutate(date = finfo[2] )
 sacc.trial <-
  # combine saccade and trial data
  merge(sacc,trial,by=c('subj','date','run','trial')) %>% 
  # grab the first correct saccade latency
  group_by(subj,date,run,trial) %>% 
  mutate(lat.fc = round(onset[which(corside)[1]]*1000)) %>% 
  # select only neccessary columns and remove all but first trial row
  select(subj,date,run,trial,Count,lat,lat.fc,xdat=xdat.y) %>% 
  summarise_each(funs(first)) 
}

# where to find the files we care about
path <- '/Volumes/B/bea_res/Data/Tasks/BarsScan/Basic/'
# get a list of all the files
saccScoreFiles <- Sys.glob(sprintf('%s/%s',path,'*/*/Scored/txt/*.sac.txt'))

alldatalist <- lapply(saccScoreFiles,readsacfile) %>% bind_rows()
write.table(alldatalist,file="eyedata_with_firstcorrectlat.txt",sep="\t",quote=F,row.names=F)
