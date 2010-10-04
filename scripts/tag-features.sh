#!/bin/bash

#
# A simple script to SVN-tag a set of features using the given qualifier (build timestamp).
# If no features are given, all known features are tagged.
#

usageMsg="Usage: $0 [--help] [--test] qualifier [feature1 feature2 ...]"

if [[ "$1" == "--help" ]]; then
    echo "$usageMsg"
    exit 0
fi

if [ "$1" == "--test" ]; then
    test="--test"
    shift
fi

if [ $# -lt 1 ]; then
    echo "$usageMsg"
    exit 1
fi

qualifier=$1; shift

if [[ $# -gt 0 ]]; then
    features=$*
else
    features=$(echo org.eclipse.imp.{runtime,analysis,analysis.ui,java.hosted,formatting,metatooling,lpg})
fi

for feature in $features; do
    ./tag-feature.sh $test $feature $qualifier
done
