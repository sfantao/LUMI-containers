#!/bin/bash -eux 
set -o pipefail

PYTHON_VERSION='3.12'
JAX_VERSION='0.5.1'
XLA_VERSION='rocm-jaxlib-v0.5.1'
JAXLIB_VERSION='rocm-jaxlib-v0.5.1'

cat \
  ../common/Dockerfile.header \
  ../common/Dockerfile.rocm-6.2.4  \
  ../common/Dockerfile.rccl \
  ../common/Dockerfile.libfabric \
  ../common/Dockerfile.aws-ofi-rccl \
  ../common/Dockerfile.rccltest \
  ../common/Dockerfile.miniconda \
  $DOCKERFILE \
  ../common/Dockerfile.jax-from-source \
  ../common/Dockerfile.no-torch-libstdc++ \
  ../common/Dockerfile.rccl-env \
  ../common/Dockerfile.conda-env-jax \
  ../common/Dockerfile.conda-env \
  > $DOCKERFILE_TMP

$DOCKERBUILD \
  -f $DOCKERFILE_TMP \
  --build-arg PYTHON_VERSION=$PYTHON_VERSION \
  --build-arg JAX_VERSION=$JAX_VERSION \
  --build-arg XLA_VERSION=$XLA_VERSION \
  --build-arg JAXLIB_VERSION=$JAXLIB_VERSION \
  -t $TAG . 2>&1 | tee $LOG

echo "$TAG" > $RES
