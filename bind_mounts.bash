#!/usr/bin/env

# code is stored on other drives or partions and git doesn't follow symlinks 
# so we'll use bindfs to pretend these files are all stored locally

bindfs /Volumes/Zeus/ABCD/abcd_scanstats abcd/abcd_scanstats
