#!/usr/bin/env bash

avgfd(){
 perl -lne '$s+=$_; $i++; END{print $s/$i}' $1
}

[ ! -d txt ] && mkdir txt 

# get TotalGray volume from FS outputs
[ ! -r txt/allgray.txt ] &&
  grep TotalGray /Volumes/Phillips/*/FS*/*/stats/aseg.stats > txt/allgray.txt 

# parse TotalGray into just relevant bits
perl -lne 'print if s:.*/(.*)/FS/(\d{5})_(\d{8}).*, ([0-9.]+), mm\^3$:\2 \3 \4 \1:g' txt/allgray.txt > txt/GM.txt

# get all the fd file we can find
[ ! -r txt/fd_filelist.txt ] && 
cat txt/GM.txt | while read id date val study; do
  find /Volumes/Phillips/$study/sub*/$id*$date -iname fd.txt
done  |tee txt/fd_filelist.txt



