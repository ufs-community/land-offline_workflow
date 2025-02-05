#!/bin/sh

set -xue

# Set other dates
PTIME=$($NDATE -${DATE_CYCLE_FREQ_HR} $PDY$cyc)

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

FILEDATE=${YYYY}${MM}${DD}.${HH}0000

JEDI_STATICDIR=${JEDI_PATH}/jedi-bundle/fv3-jedi/test/Data
JEDI_EXECDIR=${JEDI_PATH}/build/bin

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

GFSv17="NO"
B=30 # back ground error std for LETKFOI

# copy sfc_data files into work directory
for itile in {1..6}
do
  sfc_fn="${FILEDATE}.sfc_data.tile${itile}.nc"
  if [ -f ${DATA_RESTART}/${sfc_fn} ]; then
    cp -p ${DATA_RESTART}/${sfc_fn} .
  elif [ -f ${WARMSTART_DIR}/${sfc_fn} ]; then
    cp -p ${WARMSTART_DIR}/${sfc_fn} .
  else
    err_exit "Initial sfc_data files do not exist"
  fi
  # copy sfc_data file for comparison
  cp -p ${sfc_fn} "${sfc_fn}_ini"
done
# Copy obserbation file to work directory
# TODO: Figure out if this var can be passed in through the yaml file
# TODO: same with this var at line 141 
TSTUB=C96.mx100_oro_data # oro_C96.mx100
if [ "${OBS_TYPE}" = "GHCN" ]; then
  ln -nsf ${COMIN}/obs/GHCN_${YYYY}${MM}${DD}${HH}.nc .
elif [ "${OBS_TYPE}" = "IMS" ]; then
  ln -nsf ${COMIN}/obs/ioda.IMSscf.${YYYY}${MM}${DD}.${TSTUB}.nc .
fi

# update coupler.res file
settings="\
  'coupler_calendar': ${COUPLER_CALENDAR}
  'yyyp': !!str ${YYYP}
  'mp': !!str ${MP}
  'dp': !!str ${DP}
  'hp': !!str ${HP}
  'yyyy': !!str ${YYYY}
  'mm': !!str ${MM}
  'dd': !!str ${DD}
  'hh': !!str ${HH}
" # End of settings variable

fp_template="${PARMlandda}/templates/template.coupler.res"
fn_namelist="${DATA}/${FILEDATE}.coupler.res"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

################################################
# CREATE BACKGROUND ENSEMBLE (LETKFOI)
################################################

if [ "${GFSv17}" = "YES" ]; then
  SNOWDEPTHVAR="snodl"
else
  SNOWDEPTHVAR="snwdph"
  # replace field overwrite file
  cp -p ${PARMlandda}/jedi/gfs-land.yaml ${DATA}/gfs-land.yaml
fi
# FOR LETKFOI, CREATE THE PSEUDO-ENSEMBLE
for ens in pos neg
do
  if [ -e $DATA/mem_${ens} ]; then
    rm -r $DATA/mem_${ens}
  fi
  mkdir -p $DATA/mem_${ens}
  cp -p ${FILEDATE}.sfc_data.tile*.nc ${DATA}/mem_${ens}
  cp -p ${DATA}/${FILEDATE}.coupler.res ${DATA}/mem_${ens}/${FILEDATE}.coupler.res
done

# using ioda mods to get a python version with netCDF4
${USHlandda}/letkf_create_ens.py $FILEDATE $SNOWDEPTHVAR $B
if [[ $? != 0 ]]; then
  err_exit "letkf create failed"
fi

################################################
# RUN JEDI
################################################

RESP1=$((RES+1))

mkdir -p output/DA/hofx

cp "${PARMlandda}/jedi/letkfoi_snow.yaml" "${DATA}/letkf_land.yaml"
if [ "${OBS_TYPE}" = "GHCN" ]; then
  cat ${PARMlandda}/jedi/GHCN.yaml >> letkf_land.yaml
elif [ "${OBS_TYPE}" = "IMS" ]; then
  cat ${PARMlandda}/jedi/IMS.yaml >> letkf_land.yaml
fi

# update jedi yaml file
settings="\
  'yyyy': !!str ${YYYY}
  'mm': !!str ${MM}
  'dd': !!str ${DD}
  'hh': !!str ${HH}
  'yyyymmdd': !!str ${PDY}
  'yyyymmddhh': !!str ${PDY}${cyc}
  'yyyp': !!str ${YYYP}
  'mp': !!str ${MP}
  'dp': !!str ${DP}
  'hp': !!str ${HP}
  'fn_orog': C${RES}_oro_data
  'datapath': ${FIXlandda}/FV3_fix_tiled/C${RES}
  'res': ${RES}
  'resp1': ${RESP1}
  'driver_obs_only': false
  'tstub': C96.mx100_oro_data
" # End of settings variable

fp_template="${DATA}/letkf_land.yaml"
fn_namelist="${DATA}/letkf_land.yaml"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

if [ "$GFSv17" = "NO" ]; then
  cp -p ${PARMlandda}/jedi/gfs-land.yaml ${DATA}/gfs-land.yaml
else
  cp -p ${JEDI_PATH}/jedi-bundle/fv3-jedi/test/Data/fieldmetadata/gfs_v17-land.yaml ${DATA}/gfs-land.yaml
fi

if [[ ! -e Data ]]; then
  ln -nsf $JEDI_STATICDIR Data 
fi

export pgm="fv3jedi_letkf.x"
. prep_step
${RUN_CMD} -n ${NPROCS_ANALYSIS} ${JEDI_EXECDIR}/$pgm letkf_land.yaml >>$pgmout 2>errfile
export err=$?; err_chk
cp errfile errfile_jedi_letkf
if [[ $err != 0 ]]; then
  err_exit "JEDI DA failed"
fi

# save intermediate sfc_data files
for itile in {1..6}
do
  sfc_fn="${FILEDATE}.sfc_data.tile${itile}.nc"
  cp -p ${sfc_fn} "${sfc_fn}_old"
done

################################################
# Apply Increment to UFS sfc_data files
################################################
if [ "${GFSv17}" = "NO" ]; then
  frac_grid=".false."
else
  frac_grid=".true."
fi
orog_path="${FIXlandda}/FV3_fix_tiled/C${RES}"
orog_fn_base="C${RES}_oro_data"

cat << EOF > apply_incr_nml
&noahmp_snow
 date_str=${YYYY}${MM}${DD}
 hour_str=${HH}
 res=${RES}
 frac_grid=${frac_grid}
 rst_path="${DATA}"
 inc_path="${DATA}"
 orog_path="${orog_path}"
 otype=${orog_fn_base}
 ntiles=6
 ens_size=1
/
EOF

export pgm="apply_incr.exe"
. prep_step
# (n=6): this is fixed, at one task per tile (with minor code change). 
${RUN_CMD} -n 6 ${EXEClandda}/$pgm >>$pgmout 2>errfile
export err=$?; err_chk
cp errfile errfile_apply_incr
if [[ $err != 0 ]]; then
  err_exit "apply snow increment failed"
fi

for itile in {1..6}
do
  cp -p ${DATA}/${FILEDATE}.xainc.sfc_data.tile${itile}.nc ${COMOUT}
done 

for itile in {1..6}
do
  cp -p ${DATA}/${FILEDATE}.sfc_data.tile${itile}.nc ${COMOUT}
done

if [ -d output/DA/hofx ]; then
  cp -p output/DA/hofx/* ${COMOUThofx}
  ln -nsf ${COMOUThofx}/* ${DATA_HOFX}
fi


############################################################
# Comparison plot of sfc_data by JEDI increment
############################################################
DO_PLOT_SFC_COMP="YES"
if [ "${DO_PLOT_SFC_COMP}" = "YES" ]; then

  fn_sfc_base="${FILEDATE}.sfc_data.tile"
  fn_inc_base="${FILEDATE}.xainc.sfc_data.tile"
  out_title_base="Land-DA::SFC-DATA::${PDY}::"
  out_fn_base="landda_comp_sfc_${PDY}_"
  # zlevel_number is valid only for 3-D fields such as stc/smc/slc
  zlevel_number="1"

  cat > plot_comp_sfc.yaml <<EOF
work_dir: '${DATA}'
fn_sfc_base: '${fn_sfc_base}'
fn_inc_base: '${fn_inc_base}'
orog_path: '${orog_path}'
orog_fn_base: '${orog_fn_base}'
out_title_base: '${out_title_base}'
out_fn_base: '${out_fn_base}'
fix_dir: '${FIXlandda}'
zlevel_number: '${zlevel_number}'
EOF

  ${USHlandda}/plot_comp_sfc_data.py
  if [ $? -ne 0 ]; then
    err_exit "sfc_data comparison plot failed"
  fi

  # Copy result file to COMOUT
  cp -p ${out_fn_base}* ${COMOUTplot}

fi


###########################################################
# WE2E test
###########################################################
if [ "${WE2E_TEST}" == "YES" ]; then
  path_fbase="${FIXlandda}/test_base/we2e_com/${RUN}.${PDY}"
  fn_sfc="${FILEDATE}.sfc_data.tile"
  fn_inc="${FILEDATE}.xainc.sfc_data.tile"
  fn_hofx="letkf_hofx_ghcn_${PDY}${cyc}.nc"
  we2e_log_fp="${LOGDIR}/${WE2E_LOG_FN}"
  if [ ! -f "${we2e_log_fp}" ]; then
    touch ${we2e_log_fp}
  fi
  # surface data tiles
  for itile in {1..6}
  do
    ${USHlandda}/compare.py "${path_fbase}/${fn_sfc}${itile}.nc" "${COMOUT}/${fn_sfc}${itile}.nc" ${WE2E_ATOL} ${we2e_log_fp} "ANALYSIS" ${FILEDATE} "sfc_data.tile${itile}"
  done
  # increment tiles
  for itile in {1..6}
  do
    ${USHlandda}/compare.py "${path_fbase}/${fn_inc}${itile}.nc" "${COMOUT}/${fn_inc}${itile}.nc" ${WE2E_ATOL} ${we2e_log_fp} "ANALYSIS" ${FILEDATE} "xinc.tile${itile}"
  done
  # H(x)
  ${USHlandda}/compare.py "${path_fbase}/hofx/${fn_hofx}" "${COMOUT}/hofx/${fn_hofx}" ${WE2E_ATOL} ${we2e_log_fp} "ANALYSIS" ${FILEDATE} "HofX"
fi
