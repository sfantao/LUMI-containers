#!/bin/bash -e

target=all
procs=4

#
# Change default target if that has been provided.
#
if [ $# -eq 2 ] ; then
  target=$1
  procs=$2
fi

# export  DOCKER_BUILDKIT=0
export BUILDKIT_STEP_LOG_MAX_SIZE=-1
export BUILDKIT_STEP_LOG_MAX_SPEED=-1
export DOCKERBUILD="docker build \
                      --ulimit nofile=32000:32000 \
                      --network=host "

#
# Build helper file container
#
if [ -z ${SKIP_HELPER_FILES} ] ; then
  (cd ./helper-files ; docker build -t h .)
fi

#
# Build recipes
#

echo "Starting image building..."
make -j$procs $target
echo "Done building images..."

#
# Close
#
echo " ------------------------------------ "
echo " Recipes build completed successfully "
echo " ------------------------------------ "
