#!/bin/bash
backup() {

 ## account info
 # user:password
 credsfile=$(dirname ${BASH_SOURCE[0]})/ftp.cred
 [ ! -r "$credsfile" ] && echo "cannot find credentials file '$credsfile'" && return 1
 user="$(cut -f1 -d: $credsfile)"
 pass="$(cut -f2 -d: $credsfile)"
 [ -z "$user" ]      && echo "no username provided in '$credsfile'"      && return 1
 [ -z "$pass" ]      && echo "no password provided in '$credsfile'"      && return 1
 

 ## function input parse and test

 backupdir=$1
 [ -z "$backupdir" ]      && echo "bad backupdir '$backupdir'"                && return 1
 [ ! -d "$backupdir" ]    && echo "backupdir '$backupdir' must exist"         && return 1
 [[ "$backupdir" =~ /$ ]] && echo "do not put trailing slash in '$backupdir'" && return 1

 if [ -n "$2" ]; then
   [ "$(basename $2)" !=  "$(basename $1)" ] && echo "$1 and $2 should have matching endings" && return 1
 fi

 lftp -c "
  open -e \"set ftps:initial-prot ''; \
  set ftp:use-mdtm off; \
  set ftp:ssl-force true; \
  set ftp:ssl-protect-data true; \
  set cmd:parallel 1; \
  set net:connection-limit 10; \
  set cmd:queue-parallel 1; \
  open -u '$user,$pass' ftps://ftp.box.com:990; \
  mirror --ignore-time --no-symlinks --reverse --no-perms --verbose  \
    -x .DS_Store \
    -x .git \
    -x .Temp* \
    -x .fseventsd/ \
    -x .Trash* \
    -x .Spotlight* \
    -x .DocumentRevisions* \
    -x Backup \
  '$backupdir' backup/$2;\""
 # --parallel=2 --dry-run -c 
}
