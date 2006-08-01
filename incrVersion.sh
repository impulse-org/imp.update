#!/bin/bash

[ ! -r features.list ] && (echo "Can't find features.list!"; exit 1)

features=$(cat features.list)

echo "#########"
echo "Features:"
echo "#########"
for feature in ${features}; do echo "  ${feature}"; done

incrMajor=0
incrMinor=0
incrRelease=1

excludePlugins="com.ibm.shrike org.eclipse.pde.core"

for feature in ${features}; do
    echo "######################"
    echo "Processing ${feature}:"
    echo "######################"

    featureXML=../${feature}.feature/feature.xml

    oldVersion=$(grep 'version=' ${featureXML} | tail +2 | head -1)

    oldVersion=$(echo $oldVersion | sed -e 's/version="\([0-9]\+\.[0-9]\+\.[0-9]\+\)"/\1/')
#   echo "${feature} => ${oldVersion}"

    oldMajor=$(echo $oldVersion | sed -e 's/\([0-9]\+\)\.[0-9]\+\.[0-9]\+/\1/')
    oldMinor=$(echo $oldVersion | sed -e 's/[0-9]\+\.\([0-9]\+\)\.[0-9]\+/\1/')
    oldRelease=$(echo $oldVersion | sed -e 's/[0-9]\+\.[0-9]\+\.\([0-9]\+\)/\1/')

    echo "Old version = ${oldMajor}.${oldMinor}.${oldRelease}"

    newMajor=${oldMajor}
    newMinor=${oldMinor}
    newRelease=${oldRelease}

    [ ${incrMajor} -gt 0 ] && let newMajor=oldMajor+1
    [ ${incrMinor} -gt 0 ] && let newMinor=oldMinor+1
    [ ${incrRelease} -gt 0 ] && let newRelease=oldRelease+1

    newVersion="${newMajor}.${newMinor}.${newRelease}"

    echo "New version = ${newVersion}"

    # Bump version number in feature.xml
    # N.B. Need to bump versions of plugins referenced in the feature.xml too.
    # This actually makes the task easier, since all matching "version" attributes
    # must be rewritten.
    sed -i -e "s/version=\"${oldVersion}\"/version=\"${newVersion}\"/" ${featureXML}

    # Discard the first "ID"; it will be the feature itself
    plugins=$(sed -e 's/id="\(.\+\)"/\1/p
1,$d' < ${featureXML} | tail +2)

    echo Feature ${feature} contains plugins:
    for plugin in ${plugins}; do echo "   ${plugin}"; done

    for plugin in ${plugins}; do
        found=""
	for excPlug in ${excludePlugins}; do
            [ ${excPlug} = ${plugin} ] && found=1
	done
	if [ -n "${found}" ]; then continue; fi
	echo "  Incrementing version of plugin ${plugin}..."

	manifest=../${plugin}/META-INF/MANIFEST.MF

        # Bump version number in manifest
	sed -i -e "s/Bundle-Version: \(.\+\)/Bundle-Version: ${newVersion}/" ${manifest}
    done

    echo "Adding new feature version to site.xml..."
    echo "   <feature url=\"features/${feature}_${newVersion}.jar\" id=\"${feature}\" version=\"${newVersion}\"/>" >> site.xml
done

echo ""
echo "Done with all features."
