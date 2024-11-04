#!/bin/sh

set -xue

TPATH="${FIXlandda}/FV3_fix_tiled/C${RES}"
YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

FILEDATE=${YYYY}${MM}${DD}.${HH}0000

JEDI_STATICDIR=${JEDI_INSTALL}/jedi-bundle/fv3-jedi/test/Data
JEDI_EXECDIR=${JEDI_INSTALL}/build/bin

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

YAML_DA=construct
GFSv17="NO"
B=30 # back ground error std for LETKFOI

# Import input files
for itile in {1..6}
do
  cp ${DATA_SHARE}/${FILEDATE}.sfc_data.tile${itile}.nc .
done
ln -nsf ${COMIN}/obs/*_${YYYY}${MM}${DD}${HH}.nc .

# update coupler.res file
settings="\
  'yyyy': !!str ${YYYY}
  'mm': !!str ${MM}
  'dd': !!str ${DD}
  'hh': !!str ${HH}
  'yyyp': !!str ${YYYP}
  'mp': !!str ${MP}
  'dp': !!str ${DP}
  'hp': !!str ${HP}
" # End of settings variable

fp_template="${PARMlandda}/templates/template.coupler.res"
fn_namelist="${DATA}/${FILEDATE}.coupler.res"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

################################################
# CREATE BACKGROUND ENSEMBLE (LETKFOI)
################################################

if [[ ${DAtype} == "letkfoi_snow" ]]; then

  if [ $GFSv17 == "YES" ]; then
    SNOWDEPTHVAR="snodl"
  else
    SNOWDEPTHVAR="snwdph"
    # replace field overwrite file
    cp ${PARMlandda}/jedi/gfs-land.yaml ${DATA}/gfs-land.yaml
  fi
  # FOR LETKFOI, CREATE THE PSEUDO-ENSEMBLE
  for ens in pos neg
  do
    if [ -e $DATA/mem_${ens} ]; then
      rm -r $DATA/mem_${ens}
    fi
    mkdir -p $DATA/mem_${ens}
    cp ${FILEDATE}.sfc_data.tile*.nc ${DATA}/mem_${ens}
    cp ${DATA}/${FILEDATE}.coupler.res ${DATA}/mem_${ens}/${FILEDATE}.coupler.res
  done

  echo 'do_landDA: calling create ensemble'

  # using ioda mods to get a python version with netCDF4
  ${USHlandda}/letkf_create_ens.py $FILEDATE $SNOWDEPTHVAR $B
  if [[ $? != 0 ]]; then
    echo "letkf create failed"
    exit 10
  fi
fi

################################################
# DETERMINE REQUESTED JEDI TYPE, CONSTRUCT YAMLS
################################################

do_DA="YES"
do_HOFX="NO"
RESP1=$((RES+1))

mkdir -p output/DA/hofx
# if yaml is specified by user, use that. Otherwise, build the yaml
if [[ $do_DA == "YES" ]]; then 

  if [[ $YAML_DA == "construct" ]];then  # construct the yaml
    cp ${PARMlandda}/jedi/${DAtype}.yaml ${DATA}/letkf_land.yaml
    for obs in "${OBS_TYPES[@]}";
    do 
      cat ${PARMlandda}/jedi/${obs}.yaml >> letkf_land.yaml
    done
  else # use specified yaml 
    echo "Using user specified YAML: ${YAML_DA}"
    cp ${PARMlandda}/jedi/${YAML_DA} ${DATA}/letkf_land.yaml
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
    'tstub': ${TSTUB}
    'tpath': ${TPATH}
    'res': ${RES}
    'resp1': ${RESP1}
    'driver_obs_only': false
  " # End of settings variable

  fp_template="${DATA}/letkf_land.yaml"
  fn_namelist="${DATA}/letkf_land.yaml"
  ${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"
fi

if [[ $do_HOFX == "YES" ]]; then 

  if [[ $YAML_HOFX == "construct" ]];then  # construct the yaml
    cp ${PARMlandda}/jedi/${DAtype}.yaml ${DATA}/hofx_land.yaml
    for obs in "${OBS_TYPES[@]}";
    do 
      cat ${PARMlandda}/jedi/${obs}.yaml >> hofx_land.yaml
    done
  else # use specified yaml 
    echo "Using user specified YAML: ${YAML_HOFX}"
    cp ${PARMlandda}/jedi/${YAML_HOFX} ${DATA}/hofx_land.yaml
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
    'tstub': ${TSTUB}
    'tpath': ${TPATH}
    'res': ${RES}
    'resp1': ${RESP1}
    'driver_obs_only': true
  " # End of settings variable

  fp_template="${DATA}/hofx_land.yaml"
  fn_namelist="${DATA}/hofx_land.yaml"
  ${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"
fi

if [[ "$GFSv17" == "NO" ]]; then
  cp ${PARMlandda}/jedi/gfs-land.yaml ${DATA}/gfs-land.yaml
else
  cp ${JEDI_INSTALL}/jedi-bundle/fv3-jedi/test/Data/fieldmetadata/gfs_v17-land.yaml ${DATA}/gfs-land.yaml
fi

################################################
# RUN JEDI
################################################

if [[ ! -e Data ]]; then
  ln -nsf $JEDI_STATICDIR Data 
fi

echo 'do_landDA: calling fv3-jedi'

if [[ $do_DA == "YES" ]]; then
  export pgm="fv3jedi_letkf.x"
  . prep_step
  ${RUN_CMD} -n ${NPROCS_ANALYSIS} ${JEDI_EXECDIR}/$pgm letkf_land.yaml >>$pgmout 2>errfile
  export err=$?; err_chk
  cp errfile errfile_jedi_letkf
  if [[ $err != 0 ]]; then
    echo "JEDI DA failed"
    exit 10
  fi
fi 
if [[ $do_HOFX == "YES" ]]; then
  export pgm="fv3jedi_letkf.x"
  . prep_step
  ${RUN_CMD} -n ${NPROCS_ANALYSIS} ${JEDI_EXECDIR}/$pgm hofx_land.yaml >>$pgmout 2>errfile
  export err=$?; err_chk
  cp errfile errfile_jedi_hofx
  if [[ $err != 0 ]]; then
    echo "JEDI hofx failed"
    exit 10
  fi
fi 

################################################
# Apply Increment to UFS sfc_data files
################################################

if [[ $do_DA == "YES" ]]; then 

  if [[ $DAtype == "letkfoi_snow" ]]; then 

cat << EOF > apply_incr_nml
&noahmp_snow
 date_str=${YYYY}${MM}${DD}
 hour_str=$HH
 res=$RES
 frac_grid=$GFSv17
 orog_path="$TPATH"
 otype="$TSTUB"
/
EOF

    echo 'do_landDA: calling apply snow increment'

    export pgm="apply_incr.exe"
    . prep_step
    # (n=6) -> this is fixed, at one task per tile (with minor code change, could run on a single proc). 
    ${RUN_CMD} -n 6 ${EXEClandda}/$pgm >>$pgmout 2>errfile
    export err=$?; err_chk
    cp errfile errfile_apply_incr
    if [[ $err != 0 ]]; then
      echo "apply snow increment failed"
      exit 10
    fi
  fi

  for itile in {1..6}
  do
    cp -p ${DATA}/${FILEDATE}.xainc.sfc_data.tile${itile}.nc ${COMOUT}
  done

fi 

for itile in {1..6}
do
  cp -p ${DATA}/${FILEDATE}.sfc_data.tile${itile}.nc ${COMOUT}
done

if [[ -d output/DA/hofx ]]; then
  cp -p output/DA/hofx/* ${COMOUThofx}
  ln -nsf ${COMOUThofx}/* ${DATA_HOFX}
fi

# WE2E test
if [[ "${WE2E_TEST}" == "YES" ]]; then
  path_fbase="${FIXlandda}/test_base/we2e_com/${RUN}.${PDY}"
  fn_sfc="${FILEDATE}.sfc_data.tile"
  fn_inc="${FILEDATE}.xainc.sfc_data.tile"
  fn_hofx="letkf_hofx_ghcn_${PDY}${cyc}.nc"
  we2e_log_fp="${LOGDIR}/${WE2E_LOG_FN}"
  if [[ ! -e "${we2e_log_fp}" ]]; then
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
