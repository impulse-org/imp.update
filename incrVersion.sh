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

# Pre-flight check w/ no modifications
for feature in ${features}; do
    echo "######################################"
    echo "Checking ${feature}:"
    echo "######################################"

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

    # Need to check versions of plugins referenced in the feature.xml.
    pluginVersions=($(grep 'version=' ${featureXML} | grep -v '<import' | tail +3 | sed -e 's/version="\(.\+\)"\(\/>\)\?/\1/'))

    # Discard the first "ID"; it will be the feature itself
    plugins=($(sed -e 's/id="\(.\+\)"/\1/p
1,$d' < ${featureXML} | tail +2))

    echo Feature ${feature} contains plugins:
    for plugin in ${plugins[*]}; do echo "   ${plugin}"; done
    echo ""

    errors=""

    N=${#plugins[*]}
    for((i=0; i < ${N}; i++)); do
	plugin=${plugins[$i]}
	pluginVersion=${pluginVersions[$i]}

#	echo ${plugin}
#	echo ${pluginVersion}

	# Is this an excluded plugin? If so, skip it
        found=""
	for excPlug in ${excludePlugins}; do
            [ ${excPlug} = ${plugin} ] && found=1
	done
	if [ -n "${found}" ]; then echo "Skipping plugin ${plugin}"; continue; fi
	
	echo Checking plugin ${plugin} version ${pluginVersion} ...

	[ ${pluginVersion} = ${oldVersion} ] || (echo "  Plugin version mismatch in feature.xml"; errors="1")

	manifest=../${plugin}/META-INF/MANIFEST.MF

	manifestVersion=$(sed -e 's/Bundle-Version: \(.\+\)/\1/p
1,$d' ${manifest})
	[ ${manifestVersion} = ${oldVersion} ] || (echo "  Plugin version mismatch in manifest"; errors="1")
    done

#    echo "Checking version of feature ${feature} in site.xml..."
#    siteXML=site.xml
#    featureVersion=$(grep "id=\"${feature}\"" ${siteXML} | grep "version=\"${oldVersion}\"")
#    echo ${featureVersion}
#    [ -n "${featureVersion}" ] || (echo "Feature version mismatch in feature.xml"; errors="1")
done

[ -n "${errors}" ] && (echo "Checking failed; aborting."; exit 1)

echo '######################################################'
echo "All checks succeeded; proceeding to increment version."
echo '######################################################'

exit 0

for feature in ${features}; do
    echo "######################"
    echo "Processing ${feature}:"
    echo "######################"

    featureXML=../${feature}.feature/feature.xml

    oldVersion=$(grep 'version=' ${featureXML} | tail +2 | head -1)
    oldVersion=$(echo $oldVersion | sed -e 's/version="\([0-9]\+\.[0-9]\+\.[0-9]\+\)"/\1/')

    oldMajor=$(echo $oldVersion | sed -e 's/\([0-9]\+\)\.[0-9]\+\.[0-9]\+/\1/')
    oldMinor=$(echo $oldVersion | sed -e 's/[0-9]\+\.\([0-9]\+\)\.[0-9]\+/\1/')
    oldRelease=$(echo $oldVersion | sed -e 's/[0-9]\+\.[0-9]\+\.\([0-9]\+\)/\1/')

    newMajor=${oldMajor}
    newMinor=${oldMinor}
    newRelease=${oldRelease}

    [ ${incrMajor} -gt 0 ] && let newMajor=oldMajor+1
    [ ${incrMinor} -gt 0 ] && let newMinor=oldMinor+1
    [ ${incrRelease} -gt 0 ] && let newRelease=oldRelease+1

    newVersion="${newMajor}.${newMinor}.${newRelease}"

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

sed -i -e 's/<\/site>//' site.xml
echo "</site>" >> site.xml

echo ""
echo "Done with all features."
