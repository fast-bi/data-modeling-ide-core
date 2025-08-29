#!/bin/bash
#

set -o errexit
catch() {
    echo 'catching!'
    if [ "$1" != "0" ]; then
    # error handling goes here
    echo "Error $1 occurred on $2"
    fi
}

trap 'catch $? $LINENO' EXIT

docker buildx build . \
  --pull \
  --tag europe-central2-docker.pkg.dev/fast-bi-common/bi-platform/tsb-ide-coder-server-core:v4.103.2-focal \
  --platform linux/amd64 \
  --push
