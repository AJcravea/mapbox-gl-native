#!/bin/bash

set -e
set -o pipefail

if [ ! -z "${AWS_ACCESS_KEY_ID}" ] && [ ! -z "${AWS_SECRET_ACCESS_KEY}" ] ; then
    aws s3 cp --recursive --acl public-read --exclude "*" --include "*/actual.png" test/fixtures \
        s3://mapbox/mapbox-gl-native/render-tests/$TRAVIS_JOB_NUMBER
fi
