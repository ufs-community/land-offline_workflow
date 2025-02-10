#!/bin/bash
#SBATCH -o out.ctest

set -eux

source ../../versions/build.ver_hercules
module use ../../modulefiles
module load build_hercules_intel

export MPIRUN="srun"
export JEDI_PATH="/work/noaa/epic/UFS_Land-DA_v2.1/jedi_v8_ic_hercules"

ctest

wait

echo "ctest is done"
