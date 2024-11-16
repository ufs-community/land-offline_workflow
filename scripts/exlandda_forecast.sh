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

export MPI_TYPE_DEPTH=20
export OMP_STACKSIZE=512M
# shellcheck disable=SC2125
export OMP_NUM_THREADS=1
export ESMF_RUNTIME_COMPLIANCECHECK=OFF:depth=4
export ESMF_RUNTIME_PROFILE=ON
export ESMF_RUNTIME_PROFILE_OUTPUT="SUMMARY"
export PSM_RANKS_PER_CONTEXT=4
export PSM_SHAREDCONTEXTS=1

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYYMMDD=${PDY}
nYYYY=${NTIME:0:4}
nMM=${NTIME:4:2}
nDD=${NTIME:6:2}
nHH=${NTIME:8:2}

HHsec=$(( HH * 3600 ))
HHsec_5d=$(printf "%05d" "${HHsec}")
nHHsec=$(( nHH * 3600 ))
nHHsec_5d=$(printf "%05d" "${nHHsec}")

FILEDATE=${YYYY}${MM}${DD}.${HH}0000

# Copy input namelist data files
cp -p "${PARMlandda}/templates/template.noahmptable.tbl" noahmptable.tbl
cp -p "${PARMlandda}/templates/template.${APP}.fd_ufs.yaml" fd_ufs.yaml
if [ "${APP}" = "LND" ]; then
  cp -p "${PARMlandda}/templates/template.${APP}.datm_in" datm_in
  cp -p "${PARMlandda}/templates/template.${APP}.datm.streams" datm.streams
  cp -p "${PARMlandda}/templates/template.${APP}.data_table" data_table
elif [ "${APP}" = "ATML" ]; then
  cp -p "${PARMlandda}/templates/template.${APP}.field_table" field_table
fi

# Set input.nml
if [ "${APP}" = "ATML" ]; then
  if [ "${COLDSTART}" = "YES" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCLE:0:10}" ]; then
    settings="\
      'atm_io_layout_x': ${ATM_IO_LAYOUT_X}
      'atm_io_layout_y': ${ATM_IO_LAYOUT_Y}
      'atm_layout_x': ${ATM_LAYOUT_X}
      'atm_layout_y': ${ATM_LAYOUT_Y}
      'ccpp_suite': ${CCPP_SUITE}
      'external_ic': '.true.'
      'make_nh': '.true.'
      'mountain': '.false.'
      'na_init': '1'
      'nggps_ic': '.true.'
      'nstf_name': '2,1,0,0,0'
      'warm_start': '.false.'
    " # End of settings variable
  else
    settings="\
      'atm_io_layout_x': ${ATM_IO_LAYOUT_X}
      'atm_io_layout_y': ${ATM_IO_LAYOUT_Y}
      'atm_layout_x': ${ATM_LAYOUT_X}
      'atm_layout_y': ${ATM_LAYOUT_Y}
      'ccpp_suite': ${CCPP_SUITE}
      'external_ic': '.false.'
      'make_nh': '.false.'
      'mountain': '.true.'
      'na_init': '0'
      'nggps_ic': '.false.'
      'nstf_name': '2,0,0,0,0'
      'warm_start': '.true.'
    " # End of settings variable
  fi
  fp_template="${PARMlandda}/templates/template.${APP}.input.nml.${CCPP_SUITE}"
  fn_namelist="input.nml"
  ${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"
else
  cp -p "${PARMlandda}/templates/template.${APP}.input.nml" input.nml
fi

# Set ufs.configure
if [ "${APP}" = "LND" ]; then
  atm_model="datm"
elif [ "${APP}" = "ATML" ]; then
  atm_model="fv3"
fi

if [ "${COLDSTART}" = "YES" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCLE:0:10}" ]; then
  allcomp_read_restart=".false."
  allcomp_start_type="startup"
else
  allcomp_read_restart=".true."
  allcomp_start_type="continue"
fi

nprocs_atm_m1=$(( NPROCS_FORECAST_ATM - 1 ))
nprocs_atm_lnd_m1=$(( NPROCS_FORECAST_ATM + NPROCS_FORECAST_LND - 1 ))

settings="\
  'allcomp_read_restart': ${allcomp_read_restart}
  'allcomp_start_type': ${allcomp_start_type}
  'atm_model': ${atm_model}
  'dt_runseq': ${DT_RUNSEQ}
  'lnd_calc_snet': ${LND_CALC_SNET}
  'lnd_ic_type': ${LND_IC_TYPE}
  'lnd_initial_albedo': ${LND_INITIAL_ALBEDO}
  'lnd_layout_x': ${LND_LAYOUT_X}
  'lnd_layout_y': ${LND_LAYOUT_Y}
  'lnd_output_freq_sec': ${LND_OUTPUT_FREQ_SEC}
  'med_coupling_mode': ${MED_COUPLING_MODE}
  'nprocs_atm_m1': ${nprocs_atm_m1}
  'nprocs_forecast_atm': ${NPROCS_FORECAST_ATM}
  'nprocs_atm_lnd_m1': ${nprocs_atm_lnd_m1}
" # End of settings variable

fp_template="${PARMlandda}/templates/template.ufs.configure"
fn_namelist="ufs.configure"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

# Set model_configure
settings="\
  'yyyy': !!str ${YYYY}
  'mm': !!str ${MM}
  'dd': !!str ${DD}
  'hh': !!str ${HH}
  'app': ${APP}
  'dt_atmos': ${DT_ATMOS}
  'fcsthr': ${FCSTHR}
  'fhrot': ${FHROT}
  'imo': ${IMO}
  'jmo': ${JMO}
  'output_fh': ${OUTPUT_FH}
  'restart_interval': ${RESTART_INTERVAL}
  'write_groups': ${WRITE_GROUPS}
  'write_tasks_per_group': ${WRITE_TASKS_PER_GROUP}
" # End of settings variable

fp_template="${PARMlandda}/templates/template.model_configure"
fn_namelist="model_configure"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

# set diag table
settings="\
  'yyyymmdd': !!str ${YYYYMMDD}
  'yyyy': !!str ${YYYY}
  'mm': !!str ${MM}
  'dd': !!str ${DD}
  'hh': !!str ${HH}
" # End of settings variable

fp_template="${PARMlandda}/templates/template.${APP}.diag_table"
fn_namelist="diag_table"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

if [ "${APP}" = "LND" ]; then
  # CDEPS restart and pointer files for DATM (LND)
  rfile2="ufs.cpld.datm.r.${YYYY}-${MM}-${DD}-${HHsec_5d}.nc"
  if [[ -e "${COMINm1}/${rfile2}" ]]; then
    ln -nsf "${COMINm1}/${rfile2}" .
  elif [[ -e "${WARMSTART_DIR}/${rfile2}" ]]; then
    ln -nsf "${WARMSTART_DIR}/${rfile2}" .
  else
    ln -nsf ${FIXlandda}/restarts/${ATMOS_FORC}/${rfile2} .
  fi
  ls -1 "${rfile2}">rpointer.atm
elif [ "${APP}" = "ATML" ]; then
  ln -nsf ${FIXlandda}/FV3_fix_global/* .
fi

###############################
# Set up RESTART directory
################################
mkdir -p RESTART

if [ "${COLDSTART}" != "YES" ] || [ "${PDY}${cyc}" != "${DATE_FIRST_CYCLE:0:10}" ]; then
  # NoahMP restart files
  for itile in {1..6}
  do
    ln -nsf ${COMIN}/ufs_land_restart.anal.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc RESTART/ufs.cpld.lnd.out.${YYYY}-${MM}-${DD}-${HHsec_5d}.tile${itile}.nc
  done

  # CMEPS restart and pointer files
  rfile1="ufs.cpld.cpl.r.${YYYY}-${MM}-${DD}-${HHsec_5d}.nc"
  if [[ -e "${COMINm1}/RESTART/${rfile1}" ]]; then
    ln -nsf "${COMINm1}/RESTART/${rfile1}" RESTART/.
  elif [[ -e "${WARMSTART_DIR}/${rfile1}" ]]; then
    ln -nsf "${WARMSTART_DIR}/${rfile1}" RESTART/.
  else
    err_exit "ufs.cpld.cpl.r file does not exist."
  fi
  ls -1 "./RESTART/${rfile1}">rpointer.cpl
fi

#############################
# Set up INPUT directory
#############################
mkdir -p INPUT
cd INPUT

sfc_fns=( "facsf" "maximum_snow_albedo" "slope_type" "snowfree_albedo" "soil_color" \
          "soil_type" "substrate_temperature" "vegetation_greenness" "vegetation_type" )
for ifn in "${sfc_fns[@]}" ; do
  for itile in {1..6};
  do
    cp -p "${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.${ifn}.tile${itile}.nc" .
  done
done

for itile in {1..6}
do
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_oro_data.tile${itile}.nc oro_data.tile${itile}.nc
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_grid.tile${itile}.nc .
done
ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_mosaic.nc .

if [ "${APP}" = "LND" ]; then
  for itile in {1..6}
  do
    ln -nsf ${FIXlandda}/NOAHMP_IC/ufs-land_C${RES}_init_fields.tile${itile}.nc C${RES}.initial.tile${itile}.nc
  done
elif [ "${APP}" = "ATML" ]; then
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_grid_spec.nc grid_spec.nc
  for itile in {1..6}
  do
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_oro_data_ls.tile${itile}.nc oro_data_ls.tile${itile}.nc
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_oro_data_ss.tile${itile}.nc oro_data_ss.tile${itile}.nc
  done
  # GFS IC files for cold start
  if [ "${COLDSTART}" = "YES" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCLE:0:10}" ]; then
    ln -nsf ${COMIN}/gfs_ctrl.nc .
    for itile in {1..6}
    do
      ln -nsf ${COMIN}/gfs_data.tile${itile}.nc .
      ln -nsf ${COMIN}/sfc_data.tile${itile}.nc .
    done
  fi
fi

cd -

if [ "${APP}" = "LND" ]; then
  mkdir -p INPUT_DATM
  ln -nsf ${FIXlandda}/DATM_input_data/${ATMOS_FORC}/* INPUT_DATM/.
fi

# start runs
echo "Start ufs-cdeps-land model run with TASKS: ${NPROCS_FORECAST}"
export pgm="ufs_model"
. prep_step
${RUN_CMD} -n ${NPROCS_FORECAST} ${EXEClandda}/$pgm >>$pgmout 2>errfile
export err=$?; err_chk
cp errfile errfile_ufs_model
if [[ $err != 0 ]]; then
  err_exit "ufs_model failed"
fi

###########################
# copy model ouput to COM
###########################

# Copy and link output file to restart for next cycle
for itile in {1..6}
do
  cp -p "${DATA}/ufs.cpld.lnd.out.${nYYYY}-${nMM}-${nDD}-${nHHsec_5d}.tile${itile}.nc" "${COMOUT}/RESTART/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile${itile}.nc"
  ln -nsf "${COMOUT}/RESTART/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile${itile}.nc" ${DATA_RESTART}/.
done

# Move land output to COMOUT
lnd_out_freq_hr=$(( LND_OUTPUT_FREQ_SEC / 3600 ))
lnd_fcst_hh=${lnd_out_freq_hr}
while [ ${lnd_fcst_hh} -le ${FCSTHR} ]; do
  lnd_out_date=$($NDATE $lnd_fcst_hh $PDY$cyc)
  lnd_out_yyyy=${lnd_out_date:0:4}
  lnd_out_mm=${lnd_out_date:4:2}
  lnd_out_dd=${lnd_out_date:6:2}
  lnd_out_hh=${lnd_out_date:8:2}
  lnd_out_hh_sec=$(( lnd_out_hh * 3600 ))
  lnd_out_hh_sec_5d=$(printf "%05d" "${lnd_out_hh_sec}")
  lnd_fcst_hh_3d=$(printf "%03d" "${lnd_fcst_hh}")
  # land output files
  for itile in {1..6}
  do
    cp -p "${DATA}/ufs.cpld.lnd.out.${lnd_out_yyyy}-${lnd_out_mm}-${lnd_out_dd}-${lnd_out_hh_sec_5d}.tile${itile}.nc" "${COMOUT}/${NET}.${cycle}.lnd.f${lnd_fcst_hh_3d}.c${RES}.tile${itile}.nc"
  done
  # ufs.cpld.cpl.r files
  cp -p "${DATA}/RESTART/ufs.cpld.cpl.r.${lnd_out_yyyy}-${lnd_out_mm}-${lnd_out_dd}-${lnd_out_hh_sec_5d}.nc" ${COMOUT}/RESTART/.

  lnd_fcst_hh=$(( lnd_fcst_hh + lnd_out_freq_hr ))
done

if [ "${APP}" = "LND" ]; then
  cp -p ${DATA}/ufs.cpld.datm.r.${nYYYY}-${nMM}-${nDD}-${nHHsec_5d}.nc ${COMOUT}/.
elif [ "${APP}" = "ATML" ]; then
  read -ra out_fh <<< "${OUTPUT_FH}"
  out_fh1="${out_fh[0]}"
  out_fh2="${out_fh[1]}"
  if [ "${out_fh2}" = "-1" ]; then
    list_out_fh=$(seq 0 ${out_fh1} ${FCSTHR})
  else
    list_out_fh=${OUTPUT_FH}
  fi
  for ihr in ${list_out_fh}
  do
    ihr_3d=$(printf "%03d" "${ihr}")
    for itile in {1..6}
    do
      cp -p "${DATA}/atmf${ihr_3d}.tile${itile}.nc" "${COMOUT}/${NET}.${cycle}.atm.f${ihr_3d}.c${RES}.tile${itile}.nc"
      cp -p "${DATA}/sfcf${ihr_3d}.tile${itile}.nc" "${COMOUT}/${NET}.${cycle}.sfc.f${ihr_3d}.c${RES}.tile${itile}.nc"
    done
  done
  # RESTART directory
  cp -p "${DATA}/RESTART/${nYYYY}${nMM}${nDD}.${nHH}0000.coupler.res" ${COMOUT}/RESTART/.
  cp -p "${DATA}/RESTART/${nYYYY}${nMM}${nDD}.${nHH}0000.fv_core.res.nc" ${COMOUT}/RESTART/.

  rst_fns=( "ca_data" "fv_core.res" "fv_srf_wnd.res" "fv_tracer.res" "phy_data" "sfc_data" )
  for ifn in "${rst_fns[@]}" ; do
    for itile in {1..6};
    do
      cp -p "${DATA}/RESTART/${nYYYY}${nMM}${nDD}.${nHH}0000.${ifn}.tile${itile}.nc" ${COMOUT}/RESTART/.
    done
  done
fi

# WE2E test
if [[ "${WE2E_TEST}" == "YES" ]]; then
  path_fbase="${FIXlandda}/test_base/we2e_com/${RUN}.${PDY}/RESTART"
  fn_res="ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile"
  we2e_log_fp="${LOGDIR}/${WE2E_LOG_FN}"
  
  if [[ ! -e "${we2e_log_fp}" ]]; then
    touch ${we2e_log_fp}
  fi
  # restart files
  for itile in {1..6}
  do
    ${USHlandda}/compare.py "${path_fbase}/${fn_res}${itile}.nc" "${COMOUT}/RESTART/${fn_res}${itile}.nc" ${WE2E_ATOL} ${we2e_log_fp} "FORECAST" ${FILEDATE} "ufs_land_restart.tile${itile}"
  done
fi

