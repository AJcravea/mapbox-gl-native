#!/usr/bin/env bash

set -e
set -o pipefail

CMD=$@
shift

# install test server dependencies
if [ ! -d "test/node_modules/express" ]; then
    (cd test; npm install express@4.11.1)
fi

if command -v gdb >/dev/null 2>&1; then
    gdb -batch -return-child-result -ex 'set print thread-events off' \
        -ex 'run' -ex 'thread apply all bt' --args ${CMD} ;
else
    ${CMD} ;
fi
