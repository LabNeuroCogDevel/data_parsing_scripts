 #!/usr/bin/env bash

 perl -lne 'BEGIN{@m=qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec); for(@m){$m{$_}=sprintf("%02d",++$i)} } s/"//g;($id,$date,$yeartime,@j)=split/,/; @d=split(/ /,$date.$yeartime); print "${id}_$d[2]$m{$d[0]}".sprintf("%02d",$d[1])' <  /mnt/B/bea_res/Data/CantabArchives/csv/CANTAB_2005_20160809.csv > indata.txt

 perl -slane 'print "$F[0].*_",substr($F[1],0,4)' <  missing_subj_date.tsv |xargs -n1 -I{} grep '{}' indata.txt 
