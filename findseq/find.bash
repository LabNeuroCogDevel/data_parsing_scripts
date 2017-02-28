find  /mnt/B/bea_res/Personal/Miya/ -iname '*seq*'  |tee PMiya.txt


find  /mnt/B/bea_res/Data/ -iname '*seq*'  |tee Data.txt

find  /mnt/B/bea_res/ -iname '*seq*'  |tee AllB.txt

find  /data/Luna1/Raw/ -iname '*seq*'  -type d  |tee Luna1RawDir.txt

find  /data/Luna2/Projects/ -iname '*seq*' |tee Luna2Projects.txt

find  /data/Luna2/perl_raterwil/ -iname '*seq*'   |tee Luna2raterwil.txt
