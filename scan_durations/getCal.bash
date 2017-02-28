#!/usr/bin/env bash
# 20170207WF - get calendar date age and sex of schedulaed visits
set -e
trap 'e=$?;[ $e -ne 0 ]&&echo "$0 exited with error $e ($(pwd))" >&2' EXIT
 
#study=rescan
#studySearch="Rescan"

[ -z "$2" ] && echo "USAGE: $0 study SearchString;\n$0 rescan 'Rescan'" && exit 1
study="$1"
studySearch="$2"

[ ! -d txt/$study/ ] && mkdir -p txt/$study

gcalcli search "$studySearch" 2013-12-01 $(date +%F)  --calendar "Luna Lab" --nocolor |
 tee txt/$study/full.cal |
  perl -lne '
    next if m/cancelled|rescheduling/i;
      if(m/(?<date>[0-9-]{10})
           [^0-9]+
           (?<h>\d+):(?<m>\d+)(?<tod>[amp]{2})
           .*-[^0-9]+
           (?<age>[0-9]{1,3})
           .*
           yo(?<sex>[mf])
       /xi){

         $h=$+{h};
         $h+=12 if $+{tod} eq "pm" and $+{h} != 12;
         $h=sprintf("%02d",$h);
         print "$+{date}\t$h:$+{m}\t$+{age}\t$+{sex}" 
      }' |
  tee > txt/$study/$study.txt
