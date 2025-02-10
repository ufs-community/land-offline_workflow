#!/bin/bash
#SBATCH -o out.ctest

set -eux

module purge
source ../../versions/build.ver_hera
module use ../../modulefiles
module load build_hera_intel

export MPIRUN="srun"
export JEDI_PATH="/scratch2/NAGAPE/epic/UFS_Land-DA_v2.1/jedi_v8_ic"

ctest

wait

echo "ctest is done"
