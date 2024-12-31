#!/bin/bash
#SBATCH -o out.ctest

set -eux

module purge
source ../../versions/build.ver_hera
module use ../../modulefiles
module load build_hera_intel

export MPIRUN="srun"

ctest

wait

echo "ctest is done"
