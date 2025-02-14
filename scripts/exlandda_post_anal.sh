#!/bin/sh

set -xue

MACHINE_ID=${MACHINE}

# Set other dates
NTIME=$($NDATE ${DATE_CYCLE_FREQ_HR} $PDY$cyc)

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
nYYYY=${NTIME:0:4}
nMM=${NTIME:4:2}
nDD=${NTIME:6:2}
nHH=${NTIME:8:2}

FREQ=$((${FCSTHR}*3600))
RDD=$((${FCSTHR}/24))
RHH=$((${FCSTHR}%24))

FILEDATE=${YYYY}${MM}${DD}.${HH}0000
for itile in {1..6}
do
  cp -p ${COMIN}/${FILEDATE}.sfc_data.tile${itile}.nc .
done

#  convert back to UFS tile 
echo '************************************************'
echo 'calling tile2tile' 

# copy restarts into work directory
for itile in {1..6}
do
  rst_fn="ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc"
  if [ -f ${DATA_RESTART}/${rst_fn} ]; then
    cp ${DATA_RESTART}/${rst_fn} .
  elif [ -f ${WARMSTART_DIR}/${rst_fn} ]; then
    cp ${WARMSTART_DIR}/${rst_fn} .
  else
    err_exit "Initial restart files do not exist"
  fi
done

# update tile2tile namelist
settings="\
  'fix_landda': ${FIXlandda}
  'res': ${RES}
  'yyyy': !!str ${YYYY}
  'mm': !!str ${MM}
  'dd': !!str ${DD}
  'hh': !!str ${HH}
  'fn_orog': C${RES}_oro_data
" # End of settings variable

fp_template="${PARMlandda}/templates/template.jedi2ufs"
fn_namelist="jedi2ufs.namelist"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

export pgm="tile2tile_converter.exe"
. prep_step
${EXEClandda}/$pgm jedi2ufs.namelist >>$pgmout 2>errfile
export err=$?; err_chk
cp errfile errfile_tile2tile
if [[ $err != 0 ]]; then
  err_exit "tile2tile failed"
fi

# save analysis restart
for itile in {1..6}
do
  cp -p ${DATA}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc ${COMOUT}/ufs_land_restart.anal.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc
done

# WE2E test
if [ "${WE2E_TEST}" == "YES" ]; then
  path_fbase="${FIXlandda}/test_base/we2e_com/${RUN}.${PDY}"
  fn_res="ufs_land_restart.anal.${YYYY}-${MM}-${DD}_${HH}-00-00.tile"
  we2e_log_fp="${LOGDIR}/${WE2E_LOG_FN}"
  if [ ! -f "${we2e_log_fp}" ]; then
    touch ${we2e_log_fp}
  fi
  # restart files
  for itile in {1..6}
  do
    ${USHlandda}/compare.py "${path_fbase}/${fn_res}${itile}.nc" "${COMOUT}/${fn_res}${itile}.nc" ${WE2E_ATOL} ${we2e_log_fp} "POST_ANAL" ${FILEDATE} "ufs_land_restart.anal.tile${itile}"
  done
fi

