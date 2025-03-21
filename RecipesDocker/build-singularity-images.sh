#!/bin/bash -eux

mkdir -p /tmp/singularity-images
export SINGULARITY_TMPDIR=/tmp/singularity-images

mkdir -p /pfs/lustrep4/scratch/project_462000475/containers-ci/staging-area/lumi
cd /pfs/lustrep4/scratch/project_462000475/containers-ci/staging-area

