#!/bin/sh

set -xue


case $MACHINE in
  "hera")
    RUN_CMD="srun"
    ;;
  "orion")
    RUN_CMD="srun"
    ;;
  "hercules")
    RUN_CMD="srun"
    ;;
  *)
    RUN_CMD=`which mpiexec`
    ;;
esac

# Set OpenMP variables.
export KMP_AFFINITY="scatter"
export OMP_NUM_THREADS="1"
export OMP_STACKSIZE="1024m"

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}

if [ "${PDY}${cyc}" -ge "2021032100" ]; then
  data_format="netcdf"
else
  data_format="nemsio"
fi

if [ "${IC_DATA_MODEL}" = "GFS" ] || [ "${IC_DATA_MODEL}" = "gfs" ]; then
  fn_data_prefix="gfs"
  data_dir_input_grid="${COMINgfs}/${PDY}${cyc}"
elif [ "${IC_DATA_MODEL}" = "GDAS" ] || [ "${IC_DATA_MODEL}" = "gdas" ]; then
  fn_data_prefix="gdas"
  data_dir_input_grid="${COMINgdas}/${PDY}${cyc}"
fi

if [ "${data_format}" = "nemsio" ]; then
  input_type="gaussian_nemsio"
  fn_atm_data="${fn_data_prefix}.${cycle}.atmanl.nemsio"
  fn_sfc_data="${fn_data_prefix}.${cycle}.sfcanl.nemsio"
elif [ "${data_format}" = "netcdf" ]; then
  input_type="gaussian_netcdf"
  fn_atm_data="${fn_data_prefix}.${cycle}.atmanl.nc"
  fn_sfc_data="${fn_data_prefix}.${cycle}.sfcanl.nc"
fi

mkdir -p fix_sfc
sfc_fns=( "facsf" "maximum_snow_albedo" "slope_type" "snowfree_albedo" "soil_color" \
          "soil_type" "substrate_temperature" "vegetation_greenness" "vegetation_type" )
for ifn in "${sfc_fns[@]}" ; do
  for itile in {1..6}
  do
    ln -nsf "${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.${ifn}.tile${itile}.nc" "fix_sfc/C${RES}.${ifn}.tile${itile}.nc"
  done
done

mkdir -p fix_oro
ln -nsf "${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_mosaic.nc" fix_oro/.
for itile in {1..6}
do
  ln -nsf "${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_grid.tile${itile}.nc" fix_oro/.
  ln -nsf "${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_oro_data.tile${itile}.nc" fix_oro/.
done

settings="
 'mosaic_file_target_grid': ${DATA}/fix_oro/C${RES}_mosaic.nc
 'fix_dir_target_grid': ${DATA}/fix_sfc
 'orog_dir_target_grid': ${DATA}/fix_oro
 'sfc_files_input_grid': ${fn_sfc_data}
 'atm_files_input_grid': ${fn_atm_data}
 'data_dir_input_grid': ${data_dir_input_grid}
 'vcoord_file_target_grid': ${FIXlandda}/FV3_fix_global/global_hyblev.l128.txt
 'cycle_mon': ${MM}
 'cycle_day': ${DD}
 'cycle_hour': ${HH}
 'input_type': ${input_type}
 'res': ${RES}
"

fp_template="${PARMlandda}/templates/template.chgres_cube"
fn_namelist="fort.41"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

#
#-----------------------------------------------------------------------
#
# Run chgres_cube.
#
#-----------------------------------------------------------------------
#
export pgm="chgres_cube"

. prep_step
eval ${RUN_CMD} -n ${NPROCS_FCST_IC} ${EXEClandda}/$pgm >>$pgmout 2>errfile
export err=$?; err_chk

cp -p ${DATA}/gfs_ctrl.nc ${COMOUT}
for itile in {1..6}
do
  cp -p ${DATA}/out.atm.tile${itile}.nc ${COMOUT}/gfs_data.tile${itile}.nc
  cp -p ${DATA}/out.sfc.tile${itile}.nc ${COMOUT}/sfc_data.tile${itile}.nc
done

