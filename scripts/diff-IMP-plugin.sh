#!/bin/bash

usageMsg="Usage: $0 [-h] feature version project"

while [ $# -gt 0 ]; do
    case $1 in
        -h)
            echo "$usageMsg"
            exit 0 ;;
        -*)
            echo "$usageMsg"
            exit 1 ;;
        *)
            break ;;
    esac
    shift
done

if [ $# -ne 3 ]; then
    echo "$usageMsg"
    exit 1
fi

feature=$1
version=$2
project=$3

baseURL=http://dev.eclipse.org/svnroot/technology/org.eclipse.imp

svn diff $baseURL/tags/features/$feature/$version/$project $baseURL/trunk/$project
