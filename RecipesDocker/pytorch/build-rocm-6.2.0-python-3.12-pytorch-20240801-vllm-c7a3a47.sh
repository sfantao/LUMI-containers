#!/bin/bash -eux 
set -o pipefail

PYTHON_VERSION='3.12'
PYTORCH_VERSION='f0da167' # 2024-08-01 nightly release
TORCHVISION_VERSION='61bd547' # 2024-08-03 nightly release
FLASH_ATTENTION_VERSION='23a2b1c'
TRITON_VERSION='c7a3a47' 

cat \
  ../common/Dockerfile.header \
  ../common/Dockerfile.rocm-6.2.0  \
  ../common/Dockerfile.rccl \
  ../common/Dockerfile.libfabric \
  ../common/Dockerfile.aws-ofi-rccl \
  ../common/Dockerfile.rccltest \
  ../common/Dockerfile.miniconda \
  $DOCKERFILE \
  ../common/Dockerfile.no-torch-libstdc++ \
  ../common/Dockerfile.rccl-env \
  ../common/Dockerfile.conda-env-pytorch \
  ../common/Dockerfile.conda-env \
  > $DOCKERFILE_TMP

$DOCKERBUILD \
  -f $DOCKERFILE_TMP \
  --build-arg PYTHON_VERSION=$PYTHON_VERSION \
  --build-arg PYTORCH_VERSION=$PYTORCH_VERSION \
  --build-arg TORCHVISION_VERSION=$TORCHVISION_VERSION \
  --build-arg PYTORCH_DEBUG=0 \
  --build-arg PYTORCH_RELWITHDEBINFO=0 \
  -t $TAG . 2>&1 | tee $LOG

echo "$TAG" > $RES