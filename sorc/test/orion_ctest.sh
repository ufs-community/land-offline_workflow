#!/bin/bash
#SBATCH -o out.ctest

set -eux

source ../../versions/build.ver_orion
module use ../../modulefiles
module load build_orion_intel

export MPIRUN="srun"

ctest

wait

echo "ctest is done"
