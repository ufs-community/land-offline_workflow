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
[[ -e diags ]] && rm -rf diags
for i in ./${FILEDATE}.xainc.sfc_data.tile*.nc;
do
  [[ -e $i ]] && rm $i
done
mkdir -p obs
# prepare yaml files
cp $project_source_dir/../parm/jedi/jedi_letkf_snow.yaml letkf_land.yaml
for ii in "${!OBS_TYPES[@]}";
do
  echo "============================= ${OBS_TYPES[$ii]}" 
  cat $project_source_dir/../parm/jedi/${OBS_TYPES[$ii]}.yaml >> letkf_land.yaml

  # link ioda obs file
  # GHCN are time-stamped at 18. If assimilating at 00, need to use previous day's obs, so that
  # obs are within DA window.
  obs_fn="obs.t${HH}z.ghcn_snow.nc"
  [[ -e obs/${obs_fn} ]] && rm obs/${obs_fn}
  obs_file_orig=${OBSDIR}/${OBS_TYPES[$ii]}/${YY}/${OBS_TYPES[$ii],,}_snwd_ioda_${YY}${MP}${DP}${HP}.nc
  if [[ -e $obs_file_orig ]]; then
    echo "${OBS_TYPES[$ii]} observations found: $obs_file_orig"
  else
    echo "${OBS_TYPES[$ii]} observations not found: $obs_file_orig"
    exit 11
  fi
  ln -fs $obs_file_orig ./obs/${obs_fn}
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
  'NPZ': 64
  'res_p1': ${RESP1}
  'driver_obs_only': false
" # End of settins variable
fp_template="letkf_land.yaml"
fn_namelist="letkf_land.yaml"
${project_source_dir}/../ush/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

# create folder for hofx
mkdir -p ./diags

# link jedi static files
cp -rp $JEDI_STATICDIR .
ln -nsf $WORKDIR/Data/fv3files/akbk64.nc4 $WORKDIR/Data/fv3files/akbk.nc4

# copy gfs-land.yaml
cp $project_source_dir/../parm/jedi/gfs-land.yaml .

#
MPIRUN="${MPIRUN:-srun}"
echo "============================= calling ${JEDI_EXEC} with ${MPIRUN}"
${MPIRUN} -n $NPROC ${JEDI_EXEC} letkf_land.yaml

