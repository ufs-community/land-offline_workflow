#!/bin/bash
set -ex
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2

# Export runtime env. variables
source ${project_source_dir}/test/runtime_vars.sh ${project_binary_dir} ${project_source_dir}

# set extra paths
RSTDIR=$project_source_dir/../fix/test_base/sfc_data

# set executables
TEST_EXEC="${project_source_dir}/../ush/letkf_create_ens.py"
NPROC=1

# move to work directory
cd $WORKDIR

if [[ ${DAtype} == 'letkfoi_snow' ]]; then

  # FOR LETKFOI, CREATE THE PSEUDO-ENSEMBLE
  for ens in pos neg
  do
    #clean results from previous test
    if [ -e $WORKDIR/mem_${ens} ]; then
      rm -rf $WORKDIR/mem_${ens}
    fi

    mkdir -p $WORKDIR/mem_${ens}

    for i in ${RSTDIR}/${FILEDATE}.sfc_data.tile*.nc;
    do
      cp $i ${WORKDIR}/mem_${ens}
    done

    # update coupler.res file
    settings="\
      'yyyy': !!str ${YY}
      'mm': !!str ${MM}
      'dd': !!str ${DD}
      'hh': !!str ${HH}
      'yyyp': !!str ${YP}
      'mp': !!str ${MP}
      'dp': !!str ${DP}
      'hp': !!str ${HP}
    " # End of settins variable
    fp_template="${project_source_dir}/../parm/templates/template.coupler.res"
    fn_namelist="${WORKDIR}/mem_${ens}/${FILEDATE}.coupler.res"
    ${project_source_dir}/../ush/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"
  done

  echo "============================= calling create ensemble"
  ${MPIRUN} -n $NPROC $PYTHON_EXEC ${TEST_EXEC} $FILEDATE $SNOWDEPTHVAR $B 
fi
