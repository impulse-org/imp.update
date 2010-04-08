#!/bin/bash

if [ $# -ne 1 ]; then
    echo "$0 feature"
    exit 0
fi

feature=$1

svn ls http://dev.eclipse.org/svnroot/technology/org.eclipse.imp/tags/features/$feature
