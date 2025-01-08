#!/bin/bash
set -ex
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2

#
echo ${project_binary_dir}
echo ${project_source_dir}

#
TEST_NAME=datm_cdeps_lnd_gswp3
FIXlandda=${project_source_dir}/../fix

source ${project_source_dir}/../parm/detect_platform.sh
ATOL="1e-7"
RES="96"

# create test folder
RUNDIR=${project_binary_dir}/test/${TEST_NAME}
[[ -d ${RUNDIR} ]] && echo "Warning: remove old test folder!" && rm -rf ${RUNDIR}
mkdir -p ${RUNDIR}
cd ${RUNDIR}

# FV3 executable:
cp ${project_binary_dir}/ufs_model.fd/src/ufs_model.fd-build/ufs_model ./ufs_model

# Set input files
cp -p ${project_source_dir}/test/parm/ufs.configure .
cp -p ${project_source_dir}/test/parm/noahmptable.tbl .
cp -p ${project_source_dir}/test/parm/fd_ufs.yaml .
cp -p ${project_source_dir}/test/parm/datm_in .
cp -p ${project_source_dir}/test/parm/datm.streams .
cp -p ${project_source_dir}/test/parm/data_table .
cp -p ${project_source_dir}/test/parm/diag_table .
cp -p ${project_source_dir}/test/parm/input.nml .
cp -p ${project_source_dir}/test/parm/model_configure .
cp -p ${project_source_dir}/test/parm/rpointer.atm .
cp -p ${project_source_dir}/test/parm/rpointer.cpl .

# Set RESTART directory
mkdir -p RESTART
#ln -nsf ${FIXlandda}/DATA_RESTART/ufs.cpld.cpl.r.2000-01-05-00000.nc RESTART/.
#ln -nsf ${FIXlandda}/DATA_RESTART/ufs.cpld.datm.r.2000-01-05-00000.nc .
ln -nsf ${FIXlandda}/DATA_RESTART_new/ufs.cpld.cpl.r.2000-01-05-00000.nc RESTART/.
ln -nsf ${FIXlandda}/DATA_RESTART_new/ufs.cpld.datm.r.2000-01-05-00000.nc .
for itile in {1..6}
do
  ln -nsf ${FIXlandda}/DATA_RESTART/ufs_land_restart.2000-01-05_00-00-00.tile${itile}.nc RESTART/ufs.cpld.lnd.out.2000-01-05-00000.tile${itile}.nc
done

# Set INPUT directory
mkdir -p INPUT
cd INPUT

for itile in {1..6}
do
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.maximum_snow_albedo.tile${itile}.nc .
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.slope_type.tile${itile}.nc .
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.soil_type.tile${itile}.nc .
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.soil_color.tile${itile}.nc .
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.substrate_temperature.tile${itile}.nc .
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.vegetation_greenness.tile${itile}.nc .
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.vegetation_type.tile${itile}.nc .
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_oro_data.tile${itile}.nc oro_data.tile${itile}.nc
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_grid.tile${itile}.nc .
done

ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_grid_spec.nc C${RES}_mosaic.nc
for itile in {1..6}
do
  ln -nsf ${FIXlandda}/NOAHMP_IC/ufs-land_C${RES}_init_fields.tile${itile}.nc C${RES}.initial.tile${itile}.nc
done
cd -
# Set INPUT_DATM directory
mkdir -p INPUT_DATM
ln -nsf ${FIXlandda}/DATM_input_data/gswp3/* INPUT_DATM/.

NPROCS_FORECAST="13"
# start runs
MPIRUN="${MPIRUN:-srun}"
echo "Start ufs-weather-model run with ${MPIRUN}"
${MPIRUN} -n ${NPROCS_FORECAST} ./ufs_model

#
echo "Now check model output with ufs-wm baseline!"
path_fbase="${FIXlandda}/test_base/we2e_com/landda.20000105"
fn_out="ufs.cpld.lnd.out.2000-01-06-00000.tile"
fn_res="ufs_land_restart.2000-01-06_00-00-00.tile"

# restart files
for itile in {1..6}
do
  ${project_source_dir}/test/compare.py "${path_fbase}/RESTART/${fn_res}${itile}.nc" "${fn_out}${itile}.nc" ${ATOL}
done

