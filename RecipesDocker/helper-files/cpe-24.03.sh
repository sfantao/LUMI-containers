#!/bin/bash -e

if [ ! -f cpe-24.03.tar ] ; then

  ssh lumi 'bash -c -xe "cd / ; tar -cf - \
    opt/cray/libfabric/1.15.2.0/ \
    opt/cray/pe/mpich/8.1.29/ofi/crayclang/17.0/ \
    opt/cray/pe/mpich/8.1.29/gtl/lib/libmpi_gtl_hsa.* \
    usr/lib64/libcxi.so*"' | cat > cpe-24.03.tar

fi
