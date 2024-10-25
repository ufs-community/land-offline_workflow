#!/bin/bash
#SBATCH -o out.ctest

set -eux

source ../../versions/build.ver_hercules
module use ../../modulefiles
module load build_hercules_intel

export MPIRUN="srun"

ctest

wait

echo "ctest is done"
