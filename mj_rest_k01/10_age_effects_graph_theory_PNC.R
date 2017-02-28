library(ggplot2)
library(lme4)

# read in data
data_table<-read.delim(file='/Users/mariaj/Dropbox/Pitt/K01/Aim_01/gordon/PNC/txt/PNC_PC_pos.txt',sep=',',header=F)
PNC_IDs   <-read.delim(file='/Users/mariaj/Dropbox/Pitt/K01/Aim_01/gordon/PNC/scripts/PNC_IDs_fmri_wpheno_outrm.txt',header=F)
Ci_names  <-read.delim(file='/Users/mariaj/Dropbox/Pitt/K01/Aim_01/gordon/gordon_labels_wnumbers.txt',header=T)
PNC_info  <-read.csv(file="/Users/mariaj/Dropbox/Pitt/K01/Aim_01/gordon/PNC/scripts/PNC_dx.csv",sep=" ")
# transformations

#need to transpose the data frame
tdata_table<-t(data_table)
tdata_table<-as.data.frame(tdata_table)


# ## WF read in data
# PNC_IDs     <-read.delim(file='txt/PNC_IDs_fmri_wpheno_outrm.txt',header=F)
# PNC_info    <-read.table('txt/PNC_dx.csv',sep=" " )
# tdata_table <-read.table('txt/PNC_PC_pos.txt',sep=",",h=F) %>% t %>% as.data.frame()
# Ci_names    <-read.delim(file='txt/gordon_labels_wnumbers.txt',header=T)

# rename columns and rows
rownames(tdata_table)<-PNC_IDs$V1
colnames(tdata_table)<-Ci_names$Community


# data and info together 
tdata_table_age<-merge(tdata_table,PNC_info,by.x="row.names",by.y="ID",all=FALSE)
# add more age 
tdata_table_age$inv_age<-1/tdata_table_age$revised_age.x
tdata_table_age$quad_age<-tdata_table_age$revised_age.x*tdata_table_age$revised_age.x

tdata_table_age_con<-tdata_table_age[tdata_table_age$final_dx=="control",]


networks<-c("Default","SMmouth")
#"Visual", "FrontoParietal","Auditory","None","CinguloParietal"#,"RetrosplenialTemporal","CinguloOperc","VentralAttn","Salience","DorsalAttn")

PNCavg <- writeoutnetworks(tdata_table_age_con,'Row.names','revised_age.x',c("final_dx","inv_age","quad_age"),networks,"PNC")


writeoutnetworks <- function(table_data,ycolname,xcolname,keepcolumns,networks,datasourcename="PNC") {
  ## aggragate values
  # will build per person average measure
  average_measure=as.data.frame(matrix(NA, ncol=0,nrow=nrow(table_data)))
  # all roi t,p,fdr values
  allnetworkresults <-data.frame()

  # for each network, grab the columns corresponding to that network
  for (n in networks ) {

     ## find what indexes to keep
     # all the columns that match our network
     keep_network  <- grep(n,names(table_data))
     # all the columns that have useful info
     all_info_cols <- c(ycolname,xcolname,keepcolumns)
     keep_info     <- match(all_info_cols,names(table_data))
     # both those columns sorted
     keep_all<-sort(c(keep_network,keep_info))

     ## subset the data based on the columns we care about
     network_data <- table_data[,keep_all]
     # add average
     network_data$average<-apply(table_data[,keep_network], MARGIN=1, mean)

     ## for the new dataset, the columns we want to analys are 
     #  'average' and 
     #  all the columns that match the network we're currently looking at
     newgrep<-paste(sep="|",n,'average')
     keep_foranalysis<-grep(newgrep,names(network_data))
  
     ## for each roi, run a model and store t and p
     # inititilze a vector for tval and pval
     tval<-matrix(NA,ncol=1,nrow=length(keep_foranalysis))
     pval<- matrix(NA,ncol=1,nrow=length(keep_foranalysis))
     #want to tell it I only want 42 analyses to run
     for (i in 1:length(keep_foranalysis)) {
         #referring back up to the column index in PNC
         colindex=keep_foranalysis[i]
         print(colnames(network_data)[colindex])
         model<-lm(network_data[[colindex]]~network_data[[xcolname]],data=network_data)
         msc <- summary(model)$coefficients
         pval[i]<- msc[2,4]
         tval[i]<- msc[2,3]
     }

     ## build another model w/ id ~ age  (why?)
     #e.g. ycolname= Row.names
     #     xcolname= revised_age.x
     model<-lm(network_data[[ycolname]]~network_data[[xcolname]],data=table_data)
     print(summary(model))

     # put all pval and tval  into a dataframe
     pval<-as.data.frame(pval)
     tval<-as.data.frame(tval)
     results<-cbind(tval,pval)
     colnames(results)<-c("tval","pval")

     results$fdr<-p.adjust(results$pval,method="fdr",length(results$pval))
     row.names(results)<-colnames(network_data)[keep_foranalysis]
     #paste0 sep equals nothing
     filename=paste0("/users/mariaj/",n,"_",datasourcename,"_results_PC_pos_controls.txt")

     # TODO: UNCOMMENT
     #write.table(results,filename)
  
  
     #mag data frame of the average values
     foravg=network_data$average
     foravg=as.data.frame(foravg)
     colnames(foravg)=n
     average_measure=cbind(average_measure,foravg)
     averageout=sprintf("/Users/mariaj/%s_average_measures_PC_pos_controls.txt",datasourcename)
     
     # all network+roi in one dataframe
     results$network <- n
     allnetworkresults <- rbind( allnetworkresults, results)
  }
  # TODO: UNCOMMENT
  #write.table(average_measure,file=averageout)

  # if you want to see what the values are, uncomment this to drop into console before leaving function
  #browser()
  #return(results)
  #return(average_measure)
  return(allnetworkresults)
}


