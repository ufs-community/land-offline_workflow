#!/bin/bash -l

# Set shell options.
set -u

# Set path
PARMdir="{{ parm_dir }}"
source ${PARMdir}/detect_platform.sh
workdir="{{ exp_case_path }}"

# Load rocoto
module purge
if [ "${MACHINE}" == "hera" ]; then
  module load rocoto
elif [ "${MACHINE}" == "orion" ]; then
  source ${PARMdir}/../versions/run.ver_${MACHINE}
  module use $modulepath_spack_stack
  module load stack-intel/$stack_intel_ver
  module load stack-python/$stack_python_ver
  module load contrib
  module load ruby/3.2.3
  module load rocoto/1.3.7
elif [ "${MACHINE}" == "hercules" ]; then
  module load contrib
  module load rocoto
else
  echo "FATAL ERROR: modules are not loaded"
fi

# Set file names.
WFLOW_XML_FN="{{ fn_xml_rocoto }}"
rocoto_xml_bn=$( basename "${WFLOW_XML_FN}" ".xml" )
rocoto_database_fn="${rocoto_xml_bn}.db"
WFLOW_LOG_FN="log.rocoto_launch"
LOG_FN_ROCOTO_RUN="log.rocoto_run"

# Initialize the default status of the workflow to "IN PROGRESS".
wflow_status="IN PROGRESS"

# crontab line
CRONTAB_LINE="*/2 * * * * cd ${workdir} && ./launch_rocoto_wflow.sh >> ${WFLOW_LOG_FN}"

if [ "$#" -eq 1 ] && [ "$1" == "add" ]; then
  msg="The crontab line is added:
  CRONTAB_LINE = \"${CRONTAB_LINE}\" 
  "

  ${PARMdir}/get_crontab_contents.py --add -m=${MACHINE} -l="${CRONTAB_LINE}" -d
  printf "%s" "$msg"
fi

cd "${workdir}"
rocotorun_cmd="rocotorun -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10"
eval ${rocotorun_cmd} > ${LOG_FN_ROCOTO_RUN} 2>&1

rocotostat_output=$( rocotostat -w ${WFLOW_XML_FN} -d ${rocoto_database_fn} )

while read -r line; do
  if echo "$line" | grep -q "DEAD"; then
    wflow_status="FAILURE"
    break
  fi
done <<< ${rocotostat_output}

# Print out rocotostat
printf "%s" "${rocotostat_output}" > ${WFLOW_LOG_FN}

# rocotostat with -s for cycle info
rocotostat_s_output=$( rocotostat -w ${WFLOW_XML_FN} -d ${rocoto_database_fn} -s )

regex_search="^[ ]*([0-9]+)[ ]+([A-Za-z]+)[ ]+.*"
cycle_str=()
cycle_status=()
i=0
while read -r line; do
  if [ $i -gt 0 ]; then
    im1=$((i-1))
    cycle_str[im1]=$( echo "$line" | sed -r -n -e "s/${regex_search}/\1/p" )
    cycle_status[im1]=$( echo "$line" | sed -r -n -e "s/${regex_search}/\2/p" )
  fi
  i=$((i+1))
done <<< "${rocotostat_s_output}"

# Get the number of cycles
num_cycles_total=${#cycle_str[@]}
num_cycles_completed=0
for (( i=0; i<=$((num_cycles_total-1)); i++ )); do
  if [ "${cycle_status[i]}" = "Done" ]; then
    num_cycles_completed=$((num_cycles_completed+1))
  fi
done

# Check whether all cycles are complete
if [ ${num_cycles_completed} -eq ${num_cycles_total} ]; then
  wflow_status="SUCCESS"
fi

# Print out result
printf "%s" "

Summary of workflow status:
=====================================================
  ${num_cycles_completed} out of ${num_cycles_total} cycles completed.
  Workflow status:  ${wflow_status}
=====================================================
" >> ${WFLOW_LOG_FN}

# Remove crontab line
if [ "${wflow_status}" = "SUCCESS" ] || [ "${wflow_status}" = "FAILURE" ]; then
  msg="The crontab line is removed:
  CRONTAB_LINE = \"${CRONTAB_LINE}\" "

  ${PARMdir}/get_crontab_contents.py --remove -m=${MACHINE} -l="${CRONTAB_LINE}" -d

  printf "%s" "$msg" >> ${WFLOW_LOG_FN}
fi
