#!/bin/bash -eux 
set -o pipefail

cat \
  ../common/Dockerfile.header \
  ../common/Dockerfile.rocm-asan-6.2.4  \
  ../common/Dockerfile.rccl \
  ../common/Dockerfile.libfabric \
  ../common/Dockerfile.aws-ofi-rccl \
  ../common/Dockerfile.rccltest \
  $DOCKERFILE \
  ../common/Dockerfile.rccl-env \
> $DOCKERFILE_TMP

$DOCKERBUILD \
  -f $DOCKERFILE_TMP \
  -t $TAG . 2>&1 | tee $LOG

echo "$TAG" > $RES