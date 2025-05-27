#!/bin/bash

rm -rf generate-workflow-deps.out

all=''
allf=''

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
    allf="$allf $d-$b"

    rdep=$(echo $b | grep -Eo 'rocm-[0-9]+\.[0-9]+\.[0-9]+-')
    if [[ "$rdep" != "" ]] ; then
      dep=$(echo "rocm-build-${rdep%-}" | sed 's/\./_/g')
      dep="build-$dep"
    fi

    cat >> generate-workflow-deps.out << EOF
  build-$tag:
    needs: $dep
    if: \${{ ! failure() && ! cancelled() }}
    runs-on: cpouta
    steps:
      - run: ./lumi-containers-build.sh ./$d/$b.done 1
        working-directory: /home/work/actions-runner-work/LUMI-containers/LUMI-containers/RecipesDocker
  trf-$tag:
    needs: build-$tag
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
        run: |
          ssh lumi \\
            "bash -ex -c '\\
              cd /pfs/lustrep4/scratch/project_462000475/containers-ci/staging-area/gh-\${{ github.run_id }}/$d-$b/runtests && \\
              ./build-singularity-images.sh \\
              '"
      - name: issue SIF image testing
        run: |
          ssh lumi \\
            "bash -ex -c '\\
              cd /pfs/lustrep4/scratch/project_462000475/containers-ci/staging-area/gh-\${{ github.run_id }}/$d-$b/runtests && \\
              sbatch < test.sbatch |& tee jobid.info \\
              '"
        working-directory: /home/work/actions-runner-work/LUMI-containers/LUMI-containers/RecipesDocker
EOF
done

cat >> generate-workflow-deps.out << EOF
  Verify:
    needs:
EOF
for i in $all ; do
    echo "      - test-$i" >> generate-workflow-deps.out
done
cat >> generate-workflow-deps.out << EOF
    if: \${{ ! failure() && ! cancelled() }}
    runs-on: cpouta
    steps:
      - name: Wait for tests to complete.
        run: |
          while [ \$(ssh lumi 'bash -c "squeue --me -n lumi-container-test | wc -l"') -ne 1 ] ; do
            echo -n "."
            sleep 10
          done
          echo "Tests completed."
        working-directory: /home/work/actions-runner-work/LUMI-containers/LUMI-containers/RecipesDocker
EOF

for i in $allf ; do
  tag=$(echo $i | sed 's/\./_/g')
  cat >> generate-workflow-deps.out << EOF
      - name: Verify $tag
        if: always()
        run: |
          ssh lumi "grep 'Test success!!! -->' /pfs/lustrep4/scratch/project_462000475/containers-ci/staging-area/gh-\${{ github.run_id }}/$i/runtests/test.out"
        working-directory: /home/work/actions-runner-work/LUMI-containers/LUMI-containers/RecipesDocker
EOF
done