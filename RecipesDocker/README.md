# LUMI containers - Docker recipes and building/testing infrastructure.

This folder contains Docker recipes for container images tailored for LUMI for some of the most popular workloads that run on the machine and can leverage containers well.

The images use the Docker format and the included logic allows to build them and generate the corresponding [Singularity](https://docs.sylabs.io/guides/3.5/user-guide/introduction.html) images. 
Also, there are tests that can be used as examples on how to use these containers. 
Typically, these images are prepared to be run like:
```
#
# If GPU-aware MPI is needed
#
export MPICH_GPU_SUPPORT_ENABLED=1

#
# Script to set the application environemnt inside the container.
#
cat > run.sh << EOF
#!/bin/bash -e
cd /myrun
\$WITH_CONDA
set -x
./myapp
EOF
chmod +x run.sh 

#
# For 8 GPUs per node
#
MYMASKS="0xfe000000000000,0xfe00000000000000,0xfe0000,0xfe000000,0xfe,0xfe00,0xfe00000000,0xfe0000000000"
srun \
  -N $Nodes \
  -n $((Nodes*8)) \
  --cpu-bind=mask_cpu:\$MYMASKS \
  --gpus $((Nodes*8)) \
  singularity exec \
    -B /var/spool/slurmd \
    -B /opt/cray \
    -B /usr/lib64/libcxi.so.1 \
    -B $(pwd):/myrun \
    image.sif \
    /myrun/run.sh
```
We recommend using a proxy script to set your environment (e.g. select which GPUs to use per rank). 
The images' Python implementation is provided by [Miniconda](https://docs.conda.io/projects/miniconda/en/latest/).

LUMI is a CrayEX machine that uses the Cray proprietary programming environment and fabric. 
Therefore, these images are being built against that environment to ensure maximum compatibility between the enviroments inside and outside the containers.
However, given the proprietary nature of the environemnt the images do not store any files from the Cray environment. 

Instead, the build logic makes the relevant files available through a helper image, and the relevant bits are copied when needed and removed as part of the same Docker step. 
It is up to the user to make sure they have the right access and licensing in place to use these files and make them available under `helper-files` for the builds. In particular the script `cpe-*.sh` gathers the relevant parts of the Cray environment. 

Additionally, we are creating in the extent possible containers that build on top of open-source versions of libfabric and libcxi. This would allow dropping the system dependencies completely.

## Building the images.
Images can be build by invoking the script `lumi-containers-build.sh`. For example:
```
./lumi-containers-build.sh all 8
```
will build all images running up to 8 parallel builds. 

One can also target a specific application such as:
```
./lumi-containers-build.sh pytorch 1
```
to build the Pytorch images.

We can also build a specific image, e.g:
```
./lumi-containers-build.sh pytorch/build-rocm-6.2.4-python-3.12-pytorch-v2.6.0.done 1
```

This can be done in any machine where Docker is available and the `helper-files` are made available.

## Converting images to singularity and testing
The script `lumi-containers-transfer.sh` can be used to push the images to LUMI and create the scripts to create the singularity images. It is somewhat tailored for the CI currently in place, but it can be used with the proper changes to folder locations:
```
# Folder where the containers that passed the tests will be stored.
LUMI_TESTED_CONTAINERS_FOLDER="..."
# Folder where the containers that failed the tests will be stored.
LUMI_FAILED_CONTAINERS_FOLDER="..."
# Folder where the tests will be conducted.
LUMI_TEST_FOLDER="..."
# The docker registry local to LUMI.
LUMI_REGISTRY="<host>:<port>"
```

As hinted above, this script assumes there is a docker registry running on LUMI where the docker images can be pushed to. This avoids the burden of copying large docker images each time there is a change. Instead, only the changed layers need pushing to the registry. A registry based on the public Docker image can be started on LUMI, using local storage, with:
```
#!/bin/bash -ex

if [ ! -f registry.sif ] ; then
  mkdir -p /tmp/singularity-images
  export SINGULARITY_TMPDIR=/tmp/singularity-images
  singularity build registry.sif docker://registry:2
fi

mkdir -p storage

singularity run -B storage:/var/lib/registry registry.sif
``` 

This script also makes the assumption that there is a SSH configuration called `lumi` that connects to LUMI and opens the tunnel between `127.0.0.1:5000` and `$LUMI_REGISTRY`.

### Testing
Each image comes with a test associated. Look for `*.test`.

When the script `lumi-containers-transfer.sh` is executed is going to upload the tests, build scripts and a submission script to `$LUMI_TEST_FOLDER/runtests`. Then, to run the tests one has to:
```
cd $LUMI_TEST_FOLDER/runtests

# Create image under $LUMI_TEST_FOLDER/lumi
./build-singularity-images.sh

sbatch < test.sbatch
```
The tests can be done interactively with:
```
N=4 ; salloc -p standard-g  --threads-per-core 1 --exclusive -N $N --gpus-per-node 8  -t 0:30:00 --mem 0
# Run tests and copy image to LUMI_TESTED_CONTAINERS_FOLDER or LUMI_FAILED_CONTAINERS_FOLDER
# depending on successful or unsuccessful run, respectively.
bash test.sbatch
```

We recommend setting in your environment the SLURM project you want to use for the build and testing, as well as moving the singularity cache out of your home folder, e.g.:
```
export SALLOC_ACCOUNT=project_<number>
export SBATCH_ACCOUNT=project_<number>
export SLURM_ACCOUNT=project_<number>
export SINGULARITY_CACHEDIR=/pfs/lustrep4/scratch/project_<number>/.singularity
```

Once the tests complete, test.out can be inspected for success or failures.

## Auxiliary scripts
The script `generate-workflow-deps.sh` can be used to generate the different CI jobs for the current images and tests, using the possible parallelism in the setup.

## Contributing to existing images

To contribute to a new image typically you want to add to the existing Docker file.

E.g. for Pytorch 2.6.0 built on top of ROCm 6.2.4, you can add to `pytorch/build-rocm-6.2.4-python-3.12-pytorch-v2.6.0.docker`. The docker building is driven from `pytorch/build-rocm-6.2.4-python-3.12-pytorch-v2.6.0.sh`. This file sets the versions of the components to be passed as build arguments and composes the Dockerfile from its own Dockerfile but also several components that can be common accross images: 
```
cat \
  ../common/Dockerfile.header \
  ../common/Dockerfile.rocm-6.2.4  \
  ../common/Dockerfile.rccl \                 # install recent RCCL
  ../common/Dockerfile.libfabric \            # install recent libfabric/CXI
  ../common/Dockerfile.aws-ofi-rccl \         # install RCCL plugin for improved comms
  ../common/Dockerfile.rccltest \             # have RCCL tests available in the image
  ../common/Dockerfile.miniconda \            # create a CONDA environment to provide Python instalation
  $DOCKERFILE \                               # this app specific Dockerfile 
  ../common/Dockerfile.cupy \                 # make cuPy available
  ../common/Dockerfile.mpi4py \               # make mpi4Py available
  ../common/Dockerfile.no-torch-libstdc++ \   # remove torch (older) libstdc++ - use container one
  ../common/Dockerfile.no-torch-rocm \        # remove torch ROCm libs - use container ones
  ../common/Dockerfile.rccl-env \             # setup RCCL environment
  ../common/Dockerfile.torch-extra-packages \ # install packages requested by users
  ../common/Dockerfile.conda-env-pytorch \    # Make conda environment default on container startup.
  ../common/Dockerfile.conda-env \            
  > $DOCKERFILE_TMP
```
All images typically start with `../common/Dockerfile.header` to define the base image and `../common/Dockerfile.rocm-6.2.4` to define a ROCm instalation, in this case 6.2.4. The sequence:

## Contributing to new image
Use an existing image as reference. You typically need to add a `*.docker` with the image specifics, a `*.sh` file to drive the build and `*.test` file with tests for this image. For these components you might symlink existing parts and you should aim at reusing the steps in `../common/`.

If the image refers to a framework that is not covered yet, create a new folder for it. Once you add your files, make sure an entry for those is added in the `Makefile` with the `*.done` suffix, e.g.:
```
my_amazing_app: my_amazing_app/build-rocm-6.2.4-python-3.12-my_amazing_app-0.1.2.3.done
```
