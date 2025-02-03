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
  out_fn="ghcn_snow_${PDY}${cyc}.nc"

  # check obs is available
  if [ -f "${obs_fp}" ]; then
    echo "GHCN observation file: ${obs_fp}"
    cp -p "${obs_fp}" .
    cp -p "${obs_fp}" "${COMOUTobs}/${out_fn}"
  else
    input_ghcn_file="${DATA_GHCN_RAW}/${YYYP}.csv"
    if [ ! -f "${input_ghcn_file}" ]; then
      echo "GHCN raw data path: ${DATA_GHCN_RAW}"
      echo "GHCN raw data file: ${YYYP}.csv"
      err_exit "GHCN raw data file does not exist in designated path !!!"
    fi
    ghcn_station_file="${DATA_GHCN_RAW}/ghcnd-stations.txt"

    ${USHlandda}/ghcn_snod2ioda.py -i ${input_ghcn_file} -o ${obs_fn} -f ${ghcn_station_file} -d ${YYYP}${MP}${DP}${HP} -m maskout
    if [ $? -ne 0 ]; then
      err_exit "Generation of GHCN obs file failed !!!"
    fi
    cp -p "${obs_fn}" "${COMOUTobs}/${out_fn}"
  fi

  ############################################################
  # Observation File Plot
  ############################################################

  out_title_base="Land-DA::Obs::GHCN::${PDY}::"
  out_fn_base="landda_obs_ghcn_${PDY}_"

  cat > plot_obs_ghcn.yaml <<EOF
work_dir: '${DATA}'
fn_input: '${obs_fn}'
out_title_base: '${out_title_base}'
out_fn_base: '${out_fn_base}'
cartopy_ne_path: '${FIXlandda}/NaturalEarth'
EOF

  ${USHlandda}/plot_obs_ghcn.py
  if [ $? -ne 0 ]; then
    err_exit "Observation file plot failed"
  fi

  # Copy result file to COMOUT
  cp -p ${out_fn_base}* ${COMOUTplot}

fi
