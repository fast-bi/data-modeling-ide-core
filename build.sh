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
  --tag europe-central2-docker.pkg.dev/fast-bi-common/bi-platform/tsb-ide-coder-server-core:v4.122.1-focal \
  --platform linux/amd64 \
  --push

docker buildx build . \
  --pull \
  --tag 4fastbi/data-modeling-ide-core:latest \
  --tag 4fastbi/data-modeling-ide-core:v0.2.1 \
  --tag 4fastbi/data-modeling-ide-core:0.2.1 \
  --platform linux/amd64 \
  --push
