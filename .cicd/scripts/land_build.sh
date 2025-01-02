#!/usr/bin/env bash
#
# A unified build script for the Land-DA_workflow application. This script is expected to
# build Land-DA_workflow model from source for all supported platforms.
#
# Usage:
#  UFS_PLATFORM=<platform> UFS_COMPILER=<compiler> .cicd/scripts/land_build.sh
#  .cicd/scripts/land_build.sh <platform> <compiler>
#
pwd
set +x
#echo "UFS_PLATFORM=${UFS_PLATFORM}"
#echo "UFS_COMPILER=${UFS_COMPILER}"
[[ -n $1 ]] && export UFS_PLATFORM=${1} && export machine=${1,,} || export machine=${UFS_PLATFORM,,}
[[ -n $2 ]] && export UFS_COMPILER=${2} && export compiler=${2} || export compiler=${UFS_COMPILER}
[[ -n ${WORKSPACE} ]] && export workspace=${WORKSPACE} || export workspace=$(pwd)
echo "machine=${machine}"
echo "compiler=${compiler}"
echo "workspace=${workspace}"

set -e -u -x

echo "UFS_PLATFORM=${UFS_PLATFORM}"
echo "UFS_COMPILER=${UFS_COMPILER}"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Get repository root from Jenkins WORKSPACE variable if set, otherwise, set
# relative to script directory.
declare workspace
if [[ -d "${WORKSPACE:=$(pwd)}/${UFS_PLATFORM}" ]]; then
    workspace="${WORKSPACE:=$(pwd)}/${UFS_PLATFORM}"
else
    workspace="$(cd -- "${script_dir}/../.." && pwd)"
fi

# Normalize Parallel Works cluster platform value.
declare platform
if [[ "${UFS_PLATFORM}" =~ ^(az|g|p)clusternoaa ]]; then
    platform='noaacloud'
else
    platform="${UFS_PLATFORM}"
fi

echo "ACCNR=${ACCNR:=}"

# Build
cd ${workspace}
pwd
set +e

git branch
git log -1 --oneline

echo "Pipeline Building Land-DA on ${UFS_PLATFORM} ${UFS_COMPILER} with Account=${ACCNR:=}."
/usr/bin/time -p \
	-o ${workspace}/${UFS_PLATFORM}-${UFS_COMPILER}-time-land_build.json \
	-f '{\n  "cpu": "%P"\n, "memMax": "%M"\n, "mem": {"text": "%X", "data": "%D", "swaps": "%W", "context": "%c", "waits": "%w"}\n, "pagefaults": {"major": "%F", "minor": "%R"}\n, "filesystem": {"inputs": "%I", "outputs": "%O"}\n, "time": {"real": "%e", "user": "%U", "sys": "%S"}\n}' \
	sorc/app_build.sh -p=${machine} -c=${compiler} --conda=off --build 2>&1 | tee ${workspace}/${UFS_PLATFORM}-${UFS_COMPILER}-build-log.txt
status=${PIPESTATUS[0]}
cat sorc/build/log.ecbuild sorc/build/log.make >> ${workspace}/${UFS_PLATFORM}-${UFS_COMPILER}-build-log.txt
echo "Pipeline Completed Land-DA build on ${UFS_PLATFORM} ${UFS_COMPILER}. status=$status"

ls -l sorc/build/bin/*.exe sorc/build/lib64/*.so
status=$?

git status -u
                                    
build_exit=$status
echo "STAGE_NAME=${STAGE_NAME:=manual}"
env | grep = | sort > ${workspace}/${UFS_PLATFORM}-${UFS_COMPILER}-env.txt
set -e
cd -
pwd

exit $build_exit

