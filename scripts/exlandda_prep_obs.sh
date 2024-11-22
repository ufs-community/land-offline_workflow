#!/bin/sh

set -xue

# Set other dates
PTIME=$($NDATE -${DATE_CYCLE_FREQ_HR} $PDY$cyc)

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

OBSDIR="${OBSDIR:-${FIXlandda}/DA_obs}"
DATA_GHCN_RAW="${DATA_GHCN_RAW:-${FIXlandda}/DATA_ghcn}"

# GHCN snow depth data
if [ "${OBS_GHCN}" = "YES" ]; then
  # GHCN are time-stamped at 18. If assimilating at 00, need to use previous day's obs, 
  # so that obs are within DA window.
  obs_fn="ghcn_snwd_ioda_${YYYP}${MP}${DP}${HP}.nc"
  obs_fp="${OBSDIR}/GHCN/${YYYY}/${obs_fn}"
  out_fn="GHCN_${YYYY}${MM}${DD}${HH}.nc"

  # check obs is available
  if [ -e $obs_fp ]; then
    echo "GHCN observation file: $obs_fp"
    cp -p $obs_fp ${COMOUTobs}/${out_fn}
  else
    input_ghcn_file="${DATA_GHCN_RAW}/${YYYP}.csv"
    output_ioda_file="${obs_fn}"
    ghcn_station_file="${DATA_GHCN_RAW}/ghcnd-stations.txt"

    ${USHlandda}/ghcn_snod2ioda.py -i ${input_ghcn_file} -o ${output_ioda_file} -f ${ghcn_station_file} -d ${YYYP}${MP}${DP}${HP} -m maskout
    if [ $? -ne 0 ]; then
      err_exit "Generation of GHCN obs file failed !!!"
    fi
    cp -p ${output_ioda_file} ${COMOUTobs}/${out_fn}

  fi
fi
