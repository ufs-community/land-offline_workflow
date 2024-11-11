#!/bin/sh

set -xue


if [ "${APP}" = "LND" ]; then
  echo "This step is skipped for APP=LND because it is not necessary." 

elif ["${APP}" = "ATML" ]; then

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
  
  fn_atm="${EXTRN_MDL_FNS[0]}"
  fn_sfc="${EXTRN_MDL_FNS[1]}"
  tracers_input="[\"spfh\",\"clwmr\",\"o3mr\",\"icmr\",\"rwmr\",\"snmr\",\"grle\"]"
  tracers="[\"sphum\",\"liq_wat\",\"o3mr\",\"ice_wat\",\"rainwat\",\"snowwat\",\"graupel\"]"
  if [ "${data_format}" = "nemsio" ]; then
    input_type="gaussian_nemsio"
  elif [ "${data_format}" = "netcdf" ]; then
    input_type="gaussian_netcdf"
  fi
  
  settings="
   'cycle_mon': $((10#${MM}))
   'cycle_day': $((10#${DD}))
   'cycle_hour': $((10#${HH}))
   'atm_files_input_grid': ${fn_atm}
   'convert_atm': True
   'convert_nst': True
   'convert_sfc': True
   'data_dir_input_grid': ${DATA}
   'fix_dir_target_grid': ${FIXlam}
   'input_type': ${input_type}
   'mosaic_file_target_grid': ${FIXlam}/${CRES}_mosaic.halo4.nc
   'orog_dir_target_grid': ${FIXlam}
   'orog_files_target_grid': ${CRES}_oro_data.tile7.halo4.nc
   'sfc_files_input_grid': ${fn_sfc}
   'tracers': ${tracers}
   'tracers_input': ${tracers_input}
   'vcoord_file_target_grid': ${VCOORD_FILE}
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
  eval ${RUN_CMD} ${EXEClandda}/$pgm >>$pgmout 2>errfile
  export err=$?; err_chk

fi
