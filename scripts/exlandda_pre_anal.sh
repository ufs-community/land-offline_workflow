#!/bin/sh

set -xue

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}

FILEDATE=${YYYY}${MM}${DD}.${HH}0000

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
  cp -p ${DATA}/${FILEDATE}.sfc_data.tile${itile}.nc ${DATA_RESTART}/${FILEDATE}.sfc_data.tile${itile}.nc
done

