#!/bin/sh

set -xue

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

FILEDATE=${YYYY}${MM}${DD}.${HH}0000

# copy restarts into work directory
for itile in {1..6}
do
  out_fn="ufs.cpld.lnd.out.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc"
  rst_fn="ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc"
  if [[ -e ${DATA_RESTART}/${out_fn} ]]; then
    cp ${DATA_RESTART}/${out_fn} ${rst_fn}
  elif [[ -e ${WARMSTART_DIR}/${out_fn} ]]; then
    cp ${WARMSTART_DIR}/${out_fn} ${rst_fn}
  else
    err_exit "Initial restart files do not exist"
  fi
  # copy restart to data share dir for post_anal
  cp -p ${rst_fn} ${DATA_SHARE}
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

fp_template="${PARMlandda}/templates/template.ufs2jedi"
fn_namelist="ufs2jedi.namelist"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

# submit tile2tile
export pgm="tile2tile_converter.exe"
. prep_step
${EXEClandda}/$pgm ufs2jedi.namelist >>$pgmout 2>errfile
cp errfile errfile_tile2tile
export err=$?; err_chk
if [[ $err != 0 ]]; then
  err_exit "tile2tile failed"
fi

#stage restarts for applying JEDI update to intermediate directory
for itile in {1..6}
do
  cp -p ${DATA}/${FILEDATE}.sfc_data.tile${itile}.nc ${DATA_SHARE}/${FILEDATE}.sfc_data.tile${itile}.nc
done

