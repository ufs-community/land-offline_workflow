#!/bin/bash
set -ex
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2

#
echo ${project_binary_dir}
echo ${project_source_dir}

#
TEST_NAME=datm_cdeps_lnd_gswp3
PATHRT=${project_source_dir}/ufs_model.fd/tests
FIXdir=${project_source_dir}/../fix

source ${project_source_dir}/../parm/detect_platform.sh
if [[ "${PLATFORM}" == "hera" ]]; then
  INPUTDATA_ROOT="/scratch2/NAGAPE/epic/UFS-WM_RT/NEMSfv3gfs/input-data-20240501"
elif [[ "${PLATFORM}" == "orion" ]] || [[ "${PLATFORM}" == "hercules" ]]; then
  INPUTDATA_ROOT="/work/noaa/epic/UFS-WM_RT/NEMSfv3gfs/input-data-20240501"
else
  echo "WARNING: input data path is not specified for this machine."
  INPUTDATA_ROOT=${FIXdir}
fi
export MACHINE_ID=${PLATFORM}
export RT_COMPILER=${RT_COMPILER:-intel}
export CREATE_BASELINE=false
export skip_check_result=false
export RTVERBOSE=false
export delete_rundir=false
export WLCLK=30
ATOL="1e-7"

source ${PATHRT}/rt_utils.sh
source ${PATHRT}/default_vars.sh
source ${PATHRT}/tests/$TEST_NAME
source ${PATHRT}/atparse.bash

RTPWD=${RTPWD:-$FIXdir/test_base/${TEST_NAME}_${RT_COMPILER}}

if [[ ! -d ${RTPWD} ]]; then
  echo "Error: cannot find RTPWD, please check!"
  exit 1
fi  

# create test folder
RUNDIR=${project_binary_dir}/test/${TEST_NAME}
[[ -d ${RUNDIR} ]] && echo "Warning: remove old test folder!" && rm -rf ${RUNDIR}
mkdir -p ${RUNDIR}
cd ${RUNDIR}

# FV3 executable:
cp ${project_binary_dir}/ufs_model.fd/src/ufs_model.fd-build/ufs_model ./ufs_model

#set multiple input files
for i in ${FV3_RUN:-fv3_run.IN}
do
  atparse < ${PATHRT}/fv3_conf/${i} >> fv3_run
done

if [[ $DATM_CDEPS = 'true' ]] || [[ $FV3 = 'true' ]] || [[ $S2S = 'true' ]]; then
  if [[ $HAFS = 'false' ]] || [[ $FV3 = 'true' && $HAFS = 'true' ]]; then
    atparse < ${PATHRT}/parm/${INPUT_NML:-input.nml.IN} > input.nml
  fi
fi

atparse < ${PATHRT}/parm/${MODEL_CONFIGURE:-model_configure.IN} > model_configure

#compute_petbounds_and_tasks
#atparse < ${PATHRT}/parm/${UFS_CONFIGURE:-ufs.configure} > ufs.configure

cp -p ${project_source_dir}/test/parm/ufs.configure .
NPROCS_FORECAST="13"

# diag table
if [[ "Q${DIAG_TABLE:-}" != Q ]] ; then
  atparse < ${PATHRT}/parm/diag_table/${DIAG_TABLE} > diag_table
fi
# Field table
if [[ "Q${FIELD_TABLE:-}" != Q ]] ; then
  cp ${PATHRT}/parm/field_table/${FIELD_TABLE} field_table
fi

# Field Dictionary
cp ${PATHRT}/parm/fd_ufs.yaml fd_ufs.yaml

# Set up the run directory
source ./fv3_run

if [[ $DATM_CDEPS = 'true' ]]; then
  atparse < ${PATHRT}/parm/${DATM_IN_CONFIGURE:-datm_in} > datm_in
  atparse < ${PATHRT}/parm/${DATM_STREAM_CONFIGURE:-datm.streams.IN} > datm.streams
fi

# NoahMP table file
cp ${PATHRT}/parm/noahmptable.tbl noahmptable.tbl

# start runs
echo "Start ufs-weather-model run with ${MPIRUN}"
${MPIRUN} -n ${NPROCS_FORECAST} ./ufs_model

#
echo "Now check model output with ufs-wm baseline!"
for filename in ${LIST_FILES}; do
  if [[ -f ${RUNDIR}/${filename} ]] ; then
    echo "Baseline check with ${RTPWD}/${TEST_NAME}/${filename}"
    ${project_source_dir}/test/compare.py ${RUNDIR}/${filename} ${RTPWD}/${filename} ${ATOL}
  fi
done
