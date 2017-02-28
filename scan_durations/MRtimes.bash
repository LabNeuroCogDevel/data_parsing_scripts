#!/usr/bin/env bash
dir=$1
[ -z "$dir" -o ! -d "$dir" ] && exit 1

for d in $dir/*; do 
  lastdcm=$(find -L  $d -iname 'MR*'|sed -n '$p')
  #[ -z "$lastdcm" ] && warn "no mr for $d" && continue
  [ -z "$lastdcm" ] && continue

  dicom_hinfo -tag 0008,0032 -tag 0008,0033 $lastdcm |
   awk -v d=$dir '{print d,$2,$3}';
done 
