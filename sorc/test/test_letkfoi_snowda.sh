#!/bin/bash
set -ex
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2

# Export runtime env. variables
source ${project_source_dir}/test/runtime_vars.sh ${project_binary_dir} ${project_source_dir}

# set extra paths
OROG_PATH=$TPATH
OBSDIR="${FIXlandda}/DA_obs"

# set executables
JEDI_EXEC=${JEDI_EXEC:-$JEDI_EXECDIR/fv3jedi_letkf.x}
NPROC=6

# move to work directory
cd $WORKDIR

# Clean test files created during a previous test
[[ -e letkf_land.yaml ]] && rm letkf_land.yaml
[[ -e output/DA/hofx ]] && rm -rf output/DA/hofx
for i in ./${FILEDATE}.xainc.sfc_data.tile*.nc;
do
  [[ -e $i ]] && rm $i
done

# prepare yaml files
cp $project_source_dir/../parm/jedi/${DAtype}.yaml letkf_land.yaml
for ii in "${!OBS_TYPES[@]}";
do
  echo "============================= ${OBS_TYPES[$ii]}" 
  cat $project_source_dir/../parm/jedi/${OBS_TYPES[$ii]}.yaml >> letkf_land.yaml

  # link ioda obs file
  # GHCN are time-stamped at 18. If assimilating at 00, need to use previous day's obs, so that
  # obs are within DA window.
  [[ -e ${OBS_TYPES[$ii]}_${YY}${MP}${DP}${HP}.nc ]] && rm ${OBS_TYPES[$ii]}_${YY}${MP}${DP}${HP}.nc
  obs_file=${OBSDIR}/snow_depth/${OBS_TYPES[$ii]}/data_proc/v3/${YY}/${OBS_TYPES[$ii],,}_snwd_ioda_${YY}${MP}${DP}.nc
  if [[ -e $obs_file ]]; then
    echo "${OBS_TYPES[$ii]} observations found: $obs_file"
  else
    echo "${OBS_TYPES[$ii]} observations not found: $obs_file"
    exit 11
  fi
  ln -fs $obs_file ./${OBS_TYPES[$ii]}_${YY}${MM}${DD}${HH}.nc 
done

RESP1=$((RES+1))
yyyymmdd="${YY}${MM}${DD}"
yyyymmddhh="${yyyymmdd}${HH}"
# update jedi yaml file
settings="\
  'yyyy': !!str ${YY}
  'mm': !!str ${MM}
  'dd': !!str ${DD}
  'hh': !!str ${HH}
  'yyyymmdd': !!str ${yyyymmdd}
  'yyyymmddhh': !!str ${yyyymmddhh}
  'yyyp': !!str ${YP}
  'mp': !!str ${MP}
  'dp': !!str ${DP}
  'hp': !!str ${HP}
  'fn_orog': C${RES}_oro_data
  'datapath': ${FIXlandda}/FV3_fix_tiled/C${RES}
  'res': ${RES}
  'resp1': ${RESP1}
  'driver_obs_only': false
" # End of settins variable
fp_template="letkf_land.yaml"
fn_namelist="letkf_land.yaml"
${project_source_dir}/../ush/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

# create folder for hofx
mkdir -p ./output/DA/hofx

# link jedi static files
ln -fs $JEDI_STATICDIR ./

# copy gfs-land.yaml
cp $project_source_dir/../parm/jedi/gfs-land.yaml .

#
MPIRUN="${MPIRUN:-srun}"
echo "============================= calling ${JEDI_EXEC} with ${MPIRUN}"
${MPIRUN} -n $NPROC ${JEDI_EXEC} letkf_land.yaml
