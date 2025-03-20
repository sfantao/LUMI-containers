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
      dep="rocm-build-${rdep%-}"
    fi

    cat >> generate-workflow-deps.out << EOF
  $tag:
    needs: $dep
    if: \${{ ! failure() && ! cancelled() }}
    runs-on: cpouta
    steps:
      - name: Check out repository code
        uses: actions/checkout@v4
      - run: ./lumi-containers-build.sh ./$d/$b.done 1
        working-directory: \${{ github.workspace }}/RecipesDocker
EOF
done

cat >> generate-workflow-deps.out << EOF
  Transfer-Containers:
    needs:
EOF
for i in $all ; do
    echo "      - $i" >> generate-workflow-deps.out
done
cat >> generate-workflow-deps.out << EOF
    if: \${{ ! failure() && ! cancelled() }}
    runs-on: cpouta
    steps:
      - name: Transfer containers to LUMI
        run: ./lumi-containers-transfer.sh 
        working-directory: \${{ github.workspace }}/RecipesDocker
EOF

