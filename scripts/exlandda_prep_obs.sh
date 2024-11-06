#!/bin/sh

set -xue


YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

################################################
# 2. PREPARE OBS FILES
################################################
OBSDIR="${OBSDIR:-${FIXlandda}/DA_obs}"
for obs in "${OBS_TYPES[@]}"; do
  # get the obs file name
  if [ "${obs}" == "GTS" ]; then
    OBSDIR_SUBDIR="${OBSDIR_SUBDIR:-snow_depth/GTS/data_proc}"
    obsfile="${OBSDIR}/${OBSDIR_SUBDIR}/${YYYY}${MM}/adpsfc_snow_${YYYY}${MM}${DD}${HH}.nc4"
  elif [ "${obs}" == "GHCN" ]; then
    # GHCN are time-stamped at 18. If assimilating at 00, need to use previous day's obs, so that
    # obs are within DA window.
    if [ "${ATMOS_FORC}" == "era5" ]; then
      OBSDIR_SUBDIR="${OBSDIR_SUBDIR:-snow_depth/GHCN/data_proc/v3}"
      obsfile="${OBSDIR}/${OBSDIR_SUBDIR}/${YYYY}/ghcn_snwd_ioda_${YYYP}${MP}${DP}_jediv7.nc"
    elif [ "${ATMOS_FORC}" == "gswp3" ]; then
      OBSDIR_SUBDIR="${OBSDIR_SUBDIR:-snow_depth/GHCN/data_proc/v3}"
      obsfile="${OBSDIR}/${OBSDIR_SUBDIR}/${YYYY}/ghcn_snwd_ioda_${YYYP}${MP}${DP}.nc"
    fi
  elif [ ${obs} == "SYNTH" ]; then
    OBSDIR_SUBDIR="${OBSDIR_SUBDIR:-synthetic_noahmp}"
    obsfile="${OBSDIR}/${OBSDIR_SUBDIR}/IODA.synthetic_gswp_obs.${YYYY}${MM}${DD}${HH}.nc"
  else
    echo "do_landDA: Unknown obs type requested ${obs}, exiting"
    exit 1
  fi

  # check obs are available
  if [[ -e $obsfile ]]; then
    echo "do_landDA: $obs observations found: $obsfile"
    cp -p $obsfile ${COMOUTobs}/${obs}_${YYYY}${MM}${DD}${HH}.nc
  else
    echo "${obs} observations not found: $obsfile"
  fi
done
