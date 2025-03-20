#!/bin/bash

rm -rf generate-workflow-deps.out

all=''

for f in $(find . -iname 'build-rocm-*.sh') ; do

    d=$(dirname $f | sed 's#./##g')
    b=$(basename ${f%.sh})
    dep="Prepare-Build-Containers"
    all="$all $d-$b"

    rdep=$(echo $b | grep -Eo 'rocm-[0-9]+\.[0-9]+\.[0-9]+-')
    if [[ "$rdep" != "" ]] ; then
      dep="rocm-build-${rdep%-}"
    fi

    cat >> generate-workflow-deps.out << EOF
  $d-$b:
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

