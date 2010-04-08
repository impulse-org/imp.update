#!/bin/bash

usageMsg="Usage: $0 [--test] feature qualifier project1 project2 ..."

baseURL=https://dev.eclipse.org/svnroot/technology/org.eclipse.imp

if [ "$1" == "--test" ]; then
    echo=echo
    shift
fi

if [ $# -lt 3 ]; then
    echo "$usageMsg"
    exit 1
fi

feature=$1; shift
qualifier=$1; shift

version=$(grep version ../$feature.feature/feature.xml | head -2 | tail -1 | sed -e 's/ *version="\(.*\).qualifier"/\1/')

echo "-----------------------------------"
echo "--- Feature version is $version ---"
echo "-----------------------------------"

while [ $# -gt 0 ]; do
    project=$1; shift

    echo "Tagging $project..."
    $echo svn copy --parents -m 'Tagged for new feature release' $baseURL/trunk/$project $baseURL/tags/features/$feature/$version.$qualifier/$project
done
