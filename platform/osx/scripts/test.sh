#!/usr/bin/env bash

set -e
set -o pipefail
set -u

OSX_SDK_VERSION=`xcrun --sdk macosx --show-sdk-version`
OSX_PROJ_PATH=./build/osx-x86_64/platform/osx/platform.xcodeproj

export BUILDTYPE=${BUILDTYPE:-Release}

mkdir -p "${OSX_PROJ_PATH}/xcshareddata/xcschemes"
cp platform/osx/scripts/osxtest.xcscheme "${OSX_PROJ_PATH}/xcshareddata/xcschemes/osxtest.xcscheme"

xcodebuild test \
    -verbose \
    -sdk macosx${OSX_SDK_VERSION} \
    -project "${OSX_PROJ_PATH}" \
    -scheme osxtest
