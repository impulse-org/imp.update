#!/bin/bash

#
# A simple script that shows the "last changed date" from the SVN info for the given set of
# projects, to help decide which features need a version update.
#

usageMsg="Usage: $0 [--help] project1 project2 ..."

if [[ "$1" == "--help" ]]; then
    echo "$usageMsg"
    exit 0
fi

for proj in *; do 
    (cd $proj >/dev/null;
     if [[ -d ./.svn ]]; then
         echo -n $proj":   "
         svn info -R | fgrep 'Last Changed Date' | sort | tail -1
         echo
     fi)
done
