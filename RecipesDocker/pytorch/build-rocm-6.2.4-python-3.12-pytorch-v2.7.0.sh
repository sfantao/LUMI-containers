#!/bin/bash -eux 
set -o pipefail

PYTHON_VERSION='3.12'
PYTORCH_VERSION='2.7.0+rocm6.2.4'
APEX_VERSION='8870f33104efb9f7f307ee1374151b365d6823d4'
APEX_VERSION='86fff10'
APEX_VERSION='e5f4a5ec59578801aae9da7d2aa342ef1f4db7b0'
TORCHVISION_VERSION='0.22.0+rocm6.2.4'
TORCHDATA_VERSION='0.10.0'
TORCHTEXT_VERSION='0.18.0'
TORCHAUDIO_VERSION='2.7.0+rocm6.2.4'
DEEPSPEED_VERSION='0.15.1'
DEEPSPEED_VERSION='0.16.8'
VLLM_VERSION='v0.8.5+rocm'
CUPY_VERSION='13.2.0'
MPI4PY_VERSION='3.1.6'
RCCL_VERSION='85eb1f1'
TRITON_VERSION='96316ce' # Check .ci/docker/ci_commit_pins/triton.txt in Pytorch
TE_VERSION='e7a7f6d'
TE_VERSION='260a577'
MEGATRON_VERSION='10b7bc9'
MEGATRON_VERSION='f612bdf'
 
cat \
  ../common/Dockerfile.header \
  ../common/Dockerfile.rocm-6.2.4  \
  ../common/Dockerfile.rccl \
  ../common/Dockerfile.libfabric \
  ../common/Dockerfile.aws-ofi-rccl \
  ../common/Dockerfile.rccltest \
  ../common/Dockerfile.miniconda \
  $DOCKERFILE \
  ../common/Dockerfile.no-torch-libstdc++ \
  ../common/Dockerfile.no-torch-rocm \
  ../common/Dockerfile.rccl-env \
  ../common/Dockerfile.torch-extra-packages \
  ../common/Dockerfile.conda-env-pytorch \
  ../common/Dockerfile.conda-env \
  > $DOCKERFILE_TMP

$DOCKERBUILD \
  -f $DOCKERFILE_TMP \
  --build-arg PYTHON_VERSION=$PYTHON_VERSION \
  --build-arg PYTORCH_VERSION=$PYTORCH_VERSION \
  --build-arg APEX_VERSION=$APEX_VERSION \
  --build-arg TORCHVISION_VERSION=$TORCHVISION_VERSION \
  --build-arg TORCHDATA_VERSION=$TORCHDATA_VERSION \
  --build-arg TORCHTEXT_VERSION=$TORCHTEXT_VERSION \
  --build-arg TORCHAUDIO_VERSION=$TORCHAUDIO_VERSION \
  --build-arg DEEPSPEED_VERSION=$DEEPSPEED_VERSION \
  --build-arg VLLM_VERSION=$VLLM_VERSION \
  --build-arg TRITON_VERSION=$TRITON_VERSION \
  --build-arg CUPY_VERSION=$CUPY_VERSION \
  --build-arg MPI4PY_VERSION=$MPI4PY_VERSION \
  --build-arg PYTORCH_DEBUG=0 \
  --build-arg PYTORCH_RELWITHDEBINFO=0 \
  --build-arg RCCL_VERSION=$RCCL_VERSION \
  --build-arg TE_VERSION=$TE_VERSION \
  --build-arg MEGATRON_VERSION=$MEGATRON_VERSION \
  -t $TAG . 2>&1 | tee $LOG

echo "$TAG" > $RES
