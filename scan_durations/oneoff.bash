for d in $(cat julia2.lst); do echo -n "$d "; ./MRtimes.bash /Volumes/Phillips/Raw/MRprojects/mMRDA-dev/[^m]*/$d | cut -d' ' -f 2- | tr ' ' '\n' | sort |sed -n '1p;$p'|  perl -pe 's/\d{2}/$&:/g;s/:\..*//'| tr '\n' ' ';echo; done

