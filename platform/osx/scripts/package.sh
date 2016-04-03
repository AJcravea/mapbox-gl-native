#!/usr/bin/env bash

set -e
set -o pipefail
set -u

NAME=Mapbox
OUTPUT=build/osx/pkg
OSX_SDK_VERSION=`xcrun --sdk macosx --show-sdk-version`

if [[ ${#} -eq 0 ]]; then # e.g. "make xpackage"
    BUILDTYPE="Release"
    GCC_GENERATE_DEBUGGING_SYMBOLS="YES"
else # e.g. "make xpackage-strip"
    BUILDTYPE="Release"
    GCC_GENERATE_DEBUGGING_SYMBOLS="NO"
fi

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
trap finish EXIT

step "Creating build files..."
export MASON_PLATFORM=osx
export BUILDTYPE=${BUILDTYPE:-Release}
export PLATFORM=osx
make Xcode/osx

VERSION=${TRAVIS_JOB_NUMBER:-${BITRISE_BUILD_NUMBER:-0}}

step "Building OS X framework (build ${VERSION})..."
xcodebuild -sdk macosx${OSX_SDK_VERSION} \
    ARCHS="x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    GCC_GENERATE_DEBUGGING_SYMBOLS=${GCC_GENERATE_DEBUGGING_SYMBOLS} \
    CURRENT_PROJECT_VERSION=${VERSION} \
    -project ./build/osx-x86_64/platform/osx/platform.xcodeproj \
    -configuration ${BUILDTYPE} \
    -target osxsdk \
    -jobs ${JOBS}
