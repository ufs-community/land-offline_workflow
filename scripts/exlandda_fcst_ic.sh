#!/bin/sh

set -xue


if [ "${APP}" = "LND" ]; then
  echo "This step is skipped for APP=LND because it is not necessary." 

elif [ "${APP}" = "ATML" ]; then

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

  if [ "${data_format}" = "nemsio" ]; then
    input_type="gaussian_nemsio"
    fn_atm_data="gfs.${cycle}.atmanl.nemsio"
    fn_sfc_data="gfs.${cycle}.sfcanl.nemsio"
  elif [ "${data_format}" = "netcdf" ]; then
    input_type="gaussian_netcdf"
    fn_atm_data="gfs.${cycle}.atmanl.nc"
    fn_sfc_data="gfs.${cycle}.sfcanl.nc"
  fi

  settings="
   'mosaic_file_target_grid': ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_mosaic.nc
   'fix_dir_target_grid': ${FIXlandda}/FV3_fix_tiled/C${RES}
   'orog_dir_target_grid': ${FIXlandda}/FV3_fix_tiled/C${RES}
   'sfc_files_input_grid': ${fn_sfc_data}
   'atm_files_input_grid': ${fn_atm_data}
   'data_dir_input_grid': ${COMINgfs}/${PDY}
   'vcoord_file_target_grid': ${FIXlandda}/FV3_fix_global/global_hyblev.l128.txt
   'cycle_mon': !!str ${MM}
   'cycle_day': !!str ${DD}
   'cycle_hour': !!str ${HH}
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

fi
