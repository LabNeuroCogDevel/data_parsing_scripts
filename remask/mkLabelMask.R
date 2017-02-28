#!/usr/bin/env Rscript
####
#
# given an roi mask replace roi value with that specified by 'labels'
# expect to be loaded like: source('mkLabelMask.R')
#
# 2016-12-01 WF for BTC
####

mkLabelMask <- function(labels,output.file='commlabels',roimask.file='/Volumes/Phillips/CogRest/atlas/Parcels_MNI_111_warped.nii.gz') {
   require(oro.nifti)

   riomask.data <- readNIfTI(roimask.file)
   mask <-  riomask.data@.Data

   # what are the rois
   roi.i <- sort(unique(as.vector(mask)))
   # 0 isn't an roi
   roi.i <- roi.i[-which(roi.i==0)]
   # total number of rois
   nroi <- length(roi.i)

   # check
   if( length(labels) != nroi ) stop(sprintf('nroi (%d) in mask != labels (%d)',length(labels),nroi))

   # TODO: check roi labels?
   # assume labels are sorted the same as the roi values

   # list of vector for each roi: indexes that match each roi value
   # takes surprisingly long: 20s
   # need two steps b/c
   #  sequentioal change mask value 3=>4 then change all 4=>3
   #  ends up with no 4s and only 3s
   idxs <- lapply(roi.i,function(x) { which(mask==x) } )

   #masks[idxs] <- labels
   # maybe use Map to not have to use a for loop :)
   for(i in 1:length(labels) ){
    mask[idxs[[i]]] <- labels[i]
   }


   riomask.data@.Data <- mask

   writeNIfTI(riomask.data,output.file)
}
