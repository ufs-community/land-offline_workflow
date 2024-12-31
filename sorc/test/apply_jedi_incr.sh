#!/bin/bash
set -xe
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2

# Export runtime env. variables
source ${project_source_dir}/test/runtime_vars.sh ${project_binary_dir} ${project_source_dir}

# set extra paths
RSTDIR=$project_source_dir/../fix/test_base/sfc_data
INCDIR=$project_binary_dir/test

# set executables
TEST_EXEC="apply_incr.exe"
NPROC=6

# move to work directory
cd $WORKDIR

# Clean test files created during a previous test#
[[ -e apply_incr_nml ]] && rm apply_incr_nml
[[ -e ana/restarts/tile ]] && rm -rf ana/restarts/tile
for i in ./${FILEDATE}.sfc_data.tile*.nc;
do
  [[ -e $i ]] && rm $i
done

cat << EOF > apply_incr_nml
&noahmp_snow
 date_str=${YY}${MM}${DD}
 hour_str=$HH
 res=$RES
 frac_grid=$GFSv17
 orog_path="$TPATH"
 otype="$fn_orog"
/
EOF

# stage restarts
for i in ${RSTDIR}/${FILEDATE}.sfc_data.tile*.nc;
do
  cp $i .
done

echo "============================= calling apply snow increment"
#
${MPIRUN} -n $NPROC ${EXECDIR}/${TEST_EXEC}

# move ana tile to ./restarts/ana/tile
mkdir -p ana/restarts/tile
mv ${FILEDATE}.sfc_data.tile*.nc ana/restarts/tile
