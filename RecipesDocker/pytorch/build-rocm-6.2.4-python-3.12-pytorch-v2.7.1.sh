#!/bin/bash -eux 
set -o pipefail

PYTHON_VERSION='3.12'
PYTORCH_VERSION='2.7.1+rocm6.2.4'
APEX_VERSION='4b03581'
TORCHVISION_VERSION='0.22.1+rocm6.2.4'
TORCHDATA_VERSION='0.10.0'
TORCHTEXT_VERSION='0.18.0'
TORCHAUDIO_VERSION='2.7.1+rocm6.2.4'
DEEPSPEED_VERSION='0.17.4'
FLASH_ATTENTION_VERSION='v2.8.3'
VLLM_VERSION='v0.10.1'
CUPY_VERSION='13.6.0'
MPI4PY_VERSION='4.1.0'
RCCL_VERSION='e72b592'
TRITON_VERSION='96316ce' # Check .ci/docker/ci_commit_pins/triton.txt in Pytorch
TE_VERSION='e7a7f6d'
MEGATRON_VERSION='856c36d'
AITER_VERSION='f6a5384'
AITER_VERSION='e95fb1a'
 
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
  --build-arg FLASH_ATTENTION_VERSION=$FLASH_ATTENTION_VERSION \
  --build-arg AITER_VERSION=$AITER_VERSION \
  -t $TAG . 2>&1 | tee $LOG

echo "$TAG" > $RES
