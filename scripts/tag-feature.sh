#!/bin/bash

#
# A simple script to SVN-tag a set of projects in the given feature with the given qualifier.
# If no projects are specified, all projects (including the feature project itself) are tagged.
#

usageMsg="Usage: $0 [--help] [--test] feature qualifier [project1 project2 ...]"

baseURL=https://dev.eclipse.org/svnroot/technology/org.eclipse.imp

if [[ "$1" == "--help" ]]; then
    echo "$usageMsg"
    exit 0
fi

if [ "$1" == "--test" ]; then
    echo=echo
    shift
fi

if [ $# -lt 2 ]; then
    echo "$usageMsg"
    exit 1
fi

feature=$1; shift
qualifier=$1; shift

featureXMLSuffix=$feature.feature/feature.xml

featureXML=../../$featureXMLSuffix # Valid if we start in the same directory as this script

if [[ ! -r $featureXML ]]; then
    featureXML=../$featureXMLSuffix # Valid if we start in org.eclipse.imp.update
fi

if [[ ! -r $featureXML ]]; then
    featureXML=./$featureXMLSuffix # Valid if we start at the workspace root
fi

if [[ ! -r $featureXML ]]; then
    echo "Feature manifest $featureXML not found."
    exit 1
fi

version=$(grep version $featureXML | head -2 | tail -1 | sed -e 's/ *version="\(.*\).qualifier"/\1/')

if [[ $# -gt 0 ]]; then
    projects=$*
else
    # Read the list of contained projects from the feature manifest.
    # The first sed invocation that follows extracts lines containing '<plugin' followed by the
    # subsequent line that invariably reads 'id="..."'. The second sed invocation just strips
    # the plugin ID from the second line.
    projects=$(sed -n -e '/<plugin$/,/id="/p' < $featureXML | sed -E -n -e 's/ *id="(.+)"/\1/p' | tr '\n' ' ')
    projects="$projects $feature.feature"
fi

echo "-----------------------------------------------"
echo "--- Feature ID is $feature ---"
echo "--- Feature version is $version ---"
echo "--- Feature projects: $projects ---"
echo "-----------------------------------------------"

for project in $projects; do
    echo "--- Tagging $project..."
    $echo svn copy --parents -m 'Tagged for new feature release' $baseURL/trunk/$project $baseURL/tags/features/$feature/$version.$qualifier/$project
done
