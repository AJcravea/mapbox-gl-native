#!/usr/bin/env bash

set -e
set -o pipefail
set -u

export TRAVIS_REPO_SLUG=mapbox-gl-native
export PUBLISH_VERSION=$1
BINARY_DIRECTORY=$2

echo "Deploying version ${PUBLISH_VERSION}..."
 
make clean && make distclean

buildPackageStyle() {
    local package=$1 style=""     
    if [[ ${#} -eq 2 ]]; then
        style="$2"
    fi            
    echo "make ${package} ${style}"
    make ${package}
    echo "publish ${package} with ${style}"
    if [ -z ${style} ] 
    then
        ./platform/ios/scripts/publish.sh "${PUBLISH_VERSION}"
        echo "Downloading the package from s3... to ${BINARY_DIRECTORY}"
        wget -P ${BINARY_DIRECTORY} http://mapbox.s3.amazonaws.com/mapbox-gl-native/ios/builds/mapbox-ios-sdk-${PUBLISH_VERSION}.zip        
    else
        ./platform/ios/scripts/publish.sh "${PUBLISH_VERSION}" ${style}
        echo "Downloading the package from s3... to ${BINARY_DIRECTORY}"
        wget -P ${BINARY_DIRECTORY} http://mapbox.s3.amazonaws.com/mapbox-gl-native/ios/builds/mapbox-ios-sdk-${PUBLISH_VERSION}-${style}.zip
    fi            
}

buildPackageStyle "ipackage" "symbols"
buildPackageStyle "ipackage-strip"
buildPackageStyle "iframework" "symbols-dynamic"
buildPackageStyle "iframework SYMBOLS=NO" "dynamic"
buildPackageStyle "ifabric" "fabric"
