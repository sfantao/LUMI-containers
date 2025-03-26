#!/bin/bash -e

# Upstream and test images.
#
if [ -z $LUMI_TIMESTAMP ] ; then
  LUMI_TIMESTAMP="time-$(date +'%s')"
fi

LUMI_TESTED_CONTAINERS_FOLDER="/pfs/lustrep4/scratch/project_462000475/containers-ci/tested-containers"
LUMI_FAILED_CONTAINERS_FOLDER="/pfs/lustrep4/scratch/project_462000475/containers-ci/failed-containers"
LUMI_TEST_FOLDER="/pfs/lustrep4/scratch/project_462000475/containers-ci/staging-area/$LUMI_TIMESTAMP"
SINGULARITY_BUILD_MAX_TIME="1:00:00"

Nodes=4
echo "test.sbatch" > .all-test-files
cat > test.sbatch << EOF
#!/bin/bash -e
#SBATCH -J lumi-container-test
#SBATCH -p standard-g
#SBATCH --threads-per-core 1
#SBATCH --exclusive 
#SBATCH -N $Nodes 
#SBATCH --gpus $((Nodes*8)) 
#SBATCH -t 0:30:00 
#SBATCH --mem 0
#SBATCH -o test.out
#SBATCH -e test.err

cd $LUMI_TEST_FOLDER/runtests

set -o pipefail

#
# Execute examples
#

c=fe
#
# Bind mask for one and  thread per core
#
MYMASKS1="0x\${c}000000000000,0x\${c}00000000000000,0x\${c}0000,0x\${c}000000,0x\${c},0x\${c}00,0x\${c}00000000,0x\${c}0000000000"
MYMASKS2="0x\${c}00000000000000\${c}000000000000,0x\${c}00000000000000\${c}00000000000000,0x\${c}00000000000000\${c}0000,0x\${c}00000000000000\${c}000000,0x\${c}00000000000000\${c},0x\${c}00000000000000\${c}00,0x\${c}00000000000000\${c}00000000,0x\${c}00000000000000\${c}0000000000"

export MASTER_ADDR=\$(scontrol show hostname "\$SLURM_NODELIST" | head -n1)

export SCMD="srun \
  -N $Nodes \
  -n $((Nodes*8)) \
  --cpu-bind=mask_cpu:\$MYMASKS1 \
  --gpus $((Nodes*8)) \
  singularity exec \
    -B /var/spool/slurmd \
    -B /opt/cray \
    -B /usr/lib64/libcxi.so.1"
EOF

echo "build-singularity-images.sh" >> .all-test-files
cat > build-singularity-images.sh << EOF
#!/bin/bash -eux

mkdir -p /tmp/singularity-images
export SINGULARITY_TMPDIR=/tmp/singularity-images
export SINGULARITY_NOHTTPS=true

mkdir -p $LUMI_TEST_FOLDER/lumi
cd $LUMI_TEST_FOLDER

EOF

target=$1
files="${TARGET_FILE}"

if [[ "$files" == '' ]] ; then
  if [[ "$target" == "all" ]] ; then
    files=$(ls -1 */build-*.done)
  else
    files=$(ls -1 $target/build-*.done)
  fi
fi

for i in $files ; do
  while read -r line; do 
    echo "Preparing $line"

    project=$(dirname $i)
    filename=$(basename $i)
    test_filename=${filename%.done}.test
    local_tag=$line
    remote_tag="127.0.0.1:5000/$local_tag"
    lumi_tag="uan03:5000/$local_tag"

    #
    # Remote names
    #

    if [ $(docker images $local_tag | wc -l) -ne 2 ] ; then
      echo "Tag $local_tag can't be found."
      false
    fi

    docker tag $local_tag $remote_tag
    docker push $remote_tag

    hash=$(docker images $local_tag | head -n2 | tail -n1 | awk '{print $3;}')
    fname=$(echo $local_tag | sed 's/:/-/g' )
    tarf="${fname}-dockerhash-$hash.tar"
    sif="${fname}-dockerhash-$hash.sif"

    #
    # Add entry to test script.
    #
    echo "$project/$test_filename" >> .all-test-files
    cat >> test.sbatch << EOF


    test=\$(realpath $project/$test_filename)
    sif=\$(realpath $LUMI_TEST_FOLDER/$sif)

    chmod +x \$test

    cd $project
    
    set +e
    \$test \$sif |& tee $test_filename.log
    ret=\$?
    set -e
    
    if [ \$ret -eq 0 ] ; then
      echo "-------------------"
      echo "Test success!!! --> $local_tag (\$sif)"
      echo "-------------------"

      if [[ "\$sif" == "$LUMI_TESTED_CONTAINERS_FOLDER"* ]] ; then
        echo "-------------------"
        echo "No need to post image - existed before. --> \$sif"
        echo "-------------------"
      else
        echo "-------------------"
        echo "Posting singularity image --> \$sif"
        echo "-------------------"
        mkdir -p $LUMI_TESTED_CONTAINERS_FOLDER/lumi
        rm -rf $LUMI_TESTED_CONTAINERS_FOLDER/${fname}-dockerhash-*.sif
        mv \$sif $LUMI_TESTED_CONTAINERS_FOLDER/lumi
      fi
    else
      echo "###################"
      echo "###################"
      echo "###################"
      echo "Test FAILED!!! --> $local_tag (\$sif)"
      echo "###################"
      echo "###################"
      echo "###################"
      if [[ "\$sif" == "$LUMI_FAILED_CONTAINERS_FOLDER"* ]] ; then
        echo "-------------------"
        echo "Posting skipped - failed in the past --> \$sif"
        echo "-------------------"
      else
        echo "-------------------"
        echo "Posting failed singularity image --> \$sif"
        echo "-------------------"
        mkdir -p $LUMI_FAILED_CONTAINERS_FOLDER/lumi
        rm -rf $LUMI_FAILED_CONTAINERS_FOLDER/${fname}-dockerhash-*.sif
        mv \$sif $LUMI_FAILED_CONTAINERS_FOLDER/lumi
      fi
    fi
    cd -
EOF

    #
    # Add entry to build script
    #
    cat >> build-singularity-images.sh << EOF

    # Build singularity images if it does exist or if the image is broken.
    if [ -f $sif ] && $sif ls ; then
      echo "SIF image \$(realpath $sif) already exists in this test!"
    elif [ -f $LUMI_TESTED_CONTAINERS_FOLDER/$sif ] && $LUMI_TESTED_CONTAINERS_FOLDER/$sif ls ; then 
      echo "SIF image \$(realpath $LUMI_TESTED_CONTAINERS_FOLDER/$sif) already exists - reusing!"
      rm -rf $sif
      ln -s $LUMI_TESTED_CONTAINERS_FOLDER/$sif $sif
    elif [ -f $LUMI_FAILED_CONTAINERS_FOLDER/$sif ] && $LUMI_FAILED_CONTAINERS_FOLDER/$sif ls ; then 
      echo "SIF image \$(realpath $LUMI_FAILED_CONTAINERS_FOLDER/$sif) already exists - reusing!"
      rm -rf $sif
      ln -s $LUMI_FAILED_CONTAINERS_FOLDER/$sif $sif
    else
      echo Building "SIF image \$(realpath $sif)..."
      rm -rf $fname-*.sif
      
      srun -p standard-g -N 1 -n 1 -c 56 -t $SINGULARITY_BUILD_MAX_TIME \\
        bash -ex -c 'mkdir -p \$SINGULARITY_TMPDIR ; \
                    singularity build \
                      --fix-perms \
                      $sif \
                      docker://${lumi_tag}'
    fi
EOF
  chmod +x build-singularity-images.sh

  done < $i
done

rm -rf test.tar 
tar -h -cf test.tar $(cat .all-test-files)
ssh lumi "bash -c 'rm -rf $LUMI_TEST_FOLDER/runtests ; mkdir -p $LUMI_TEST_FOLDER/runtests'"
scp test.tar lumi:$LUMI_TEST_FOLDER/runtests
ssh lumi "bash -c 'cd $LUMI_TEST_FOLDER/runtests ; tar -xf test.tar'"


# #ssh lumi "bash -c 'set -ex ; cd $LUMI_TEST_FOLDER; rm -rf runtests ; mkdir runtests ; cd runtests; tar -xf ../test.tar'"
# ssh lumi "bash -c 'set -ex ; cd $LUMI_TEST_FOLDER; rm -rf runtests ; mkdir runtests ; cd runtests; tar -xf ../test.tar ; sbatch < test.sbatch'"
