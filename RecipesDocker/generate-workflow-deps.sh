#!/bin/bash

rm -rf generate-workflow-deps.out

all=''

# We need to process rocm entries first.
for f in \
    $(find rocm -iname 'build-rocm-*.sh') \
    $(find . -iname 'build-rocm-*.sh' -not -path "./rocm/*") \
    ; do

    d=$(dirname $f | sed 's#./##g')
    b=$(basename ${f%.sh})
    dep="Prepare-Build-Containers"
    tag=$(echo $d-$b | sed 's/\./_/g')
    all="$all $tag"

    rdep=$(echo $b | grep -Eo 'rocm-[0-9]+\.[0-9]+\.[0-9]+-')
    if [[ "$rdep" != "" ]] ; then
      dep=$(echo "rocm-build-${rdep%-}" | sed 's/\./_/g')
    fi

    cat >> generate-workflow-deps.out << EOF
  $tag:
    needs: $dep
    if: \${{ ! failure() && ! cancelled() }}
    runs-on: cpouta
    steps:
      - run: ./lumi-containers-build.sh ./$d/$b.done 1
        working-directory: /home/work/actions-runner-work/LUMI-containers/LUMI-containers/RecipesDocker
  trf-$tag:
    needs: $tag
    if: \${{ ! failure() && ! cancelled() }}
    runs-on: cpouta-trf
    steps:
      - run: LUMI_TIMESTAMP="gh-\${{ github.run_id }}/$d-$b" TARGET_FILE="./$d/$b.done" ./lumi-containers-transfer.sh
        working-directory: /home/work/actions-runner-work/LUMI-containers/LUMI-containers/RecipesDocker
  test-$tag:
    needs: trf-$tag
    if: \${{ ! failure() && ! cancelled() }}
    runs-on: cpouta-test
    steps:
      - name: build SIF image
        run: 
          ssh lumi \
            "bash -ex -c '\
              cd /pfs/lustrep4/scratch/project_462000475/containers-ci/staging-area/gh-\${{ github.run_id }}/$d-$b/runtests && \
              srun -p dev-g -c 56 -t 30:00 ./build-singularity-images.sh \
              '"
      - name: issue SIF image testing
        run: 
          ssh lumi \
            "bash -ex -c '\
              cd /pfs/lustrep4/scratch/project_462000475/containers-ci/staging-area/gh-\${{ github.run_id }}/$d-$b/runtests && \
              sbatch < test.sbatch \
              '"
        working-directory: /home/work/actions-runner-work/LUMI-containers/LUMI-containers/RecipesDocker
      - name: issue SIF image testing
        run: 
          ssh lumi \
            "bash -ex -c '\
              cd /pfs/lustrep4/scratch/project_462000475/containers-ci/staging-area/gh-\${{ github.run_id }}/$d-$b/runtests && \
              sbatch < test.sbatch |& tee jobid.info \
              '"
        working-directory: /home/work/actions-runner-work/LUMI-containers/LUMI-containers/RecipesDocker
EOF
done

# cat >> generate-workflow-deps.out << EOF
#   Transfer-Containers:
#     needs:
# EOF
# for i in $all ; do
#     echo "      - $i" >> generate-workflow-deps.out
# done
# cat >> generate-workflow-deps.out << EOF
#     if: \${{ ! failure() && ! cancelled() }}
#     runs-on: cpouta
#     steps:
#       - name: Transfer containers to LUMI
#         run: ./lumi-containers-transfer.sh 
#         working-directory: \${{ github.workspace }}/RecipesDocker
# EOF

