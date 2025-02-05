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
echo "ptime=$PTIME"
echo "pdy=$PDY"

OBSDIR="${OBSDIR:-${FIXlandda}/DA_obs}"
DATA_GHCN_RAW="${DATA_GHCN_RAW:-${FIXlandda}/DATA_ghcn}"


#TODO: figure out if spack-stack can build this
# set pythonpath for ioda converters
PYTHONPATH=$PYTHONPATH:/scratch2/NCEPDEV/land/data/DA/GDASApp/sorc/iodaconv/src/:/scratch2/NCEPDEV/land/data/DA/GDASApp/build/lib/python3.10

# IMS snow cover data
if [ "${OBS_TYPE}" == "IMS" ]; then
  # TODO: figure out if these variables can be sourced
  RES=96 #FV3 resolution
  TSTUB=C96.mx100_oro_data #oro_C96.mx100
  DOY=$(date -d "${YYYY}-${MM}-${DD}" +%j)
  echo "DOY is ${DOY}"
  # TODO: the date seems to be for the next day. Need to figure out if this impacts the ghcn case

  if [[ ${PDY}${cyc} -gt 2014120200 ]]; then
    ims_vsn=1.3
    imsformat=2 # nc
    imsres="4km"
    fsuf="nc"
    ascii=""
  elif [[ ${PDY}${cyc} -gt 2004022400 ]]; then
    ims_vsn=1.2
    imsformat=2 # nc
    imsres="4km"
    fsuf="nc"
    ascii=""
  else # TODO: switch back when we get obs data for 2000 or use a new case
    ims_vsn=1.3 #1.1
    imsformat=2 #1 # asc
    imsres="4km" #"24km"
    fsuf="nc" #"asc"
    ascii="" #"ascii"
  fi
  
  obs_fn="ims${YYYY}${DOY}_${imsres}_v${ims_vsn}.${fsuf}"
  # TODO: figure out which data is needed and stage them
  #obs_fp="${OBSDIR}/snow_ice_cover/IMS/${YYYY}"
  obs_fp="/scratch1/NCEPDEV/stmp4/Edward.Snyder/IMS_snowcover_obs/git-repo/ims_case_data/"
  out_fn="ioda.IMSscf.${YYYY}${MM}${DD}.${TSTUB}.nc"

   # check obs is available
  if [ -f "${obs_fp}" ]; then
    echo "IMS observation file: ${obs_fp}"
    cp -p "${obs_fp}" .
    cp -p "${obs_fp}" "${COMOUTobs}/${out_fn}"
  fi

  # pre-process and call IODA converter for IMS obs
  if [[ -f fims.nml ]]; then
        rm -rf fims.nml
  fi
# TODO: update fcst_path when we find the right case data
cat >> fims.nml << EOF
 &fIMS_nml
  idim=$RES, jdim=$RES,
  otype=${TSTUB},
  jdate=${YYYY}${DOY},
  yyyymmddhh=${YYYY}${MM}${DD}.${HH},
  fcst_path="/scratch1/NCEPDEV/stmp4/Edward.Snyder/IMS_snowcover_obs/land-DA_update/jedi/restarts/",
  imsformat=${imsformat},
  imsversion=${ims_vsn},
  imsres=${imsres},
  IMS_OBS_PATH="${obs_fp}/",
  IMS_IND_PATH="${obs_fp}/",
  /
EOF
  echo "calling fIMS"
  
  # TODO: Do we need to run with mpiexec?
  ${EXEClandda}/calcfIMS.exe
  if [[ $? != 0 ]]; then
    echo "fIMS failed"
    exit 10
  fi

  #IMS_IODA=imsfv3_scf2iodaTemp.py # 2024-07-12 temporary until GDASApp ioda converter updated.
  #cp ${LANDDADIR}/jedi/ioda/${IMS_IODA} $JEDIWORKDIR

  echo "calling ioda converter"
  # TODO: create input_fn var
  ${USHlandda}/imsfv3_scf2iodaTemp.py -i IMSscf.${YYYY}${MM}${DD}.${TSTUB}.nc -o ${out_fn}
  if [[ $? != 0 ]]; then
    echo "IMS IODA converter failed"
    exit 10
  fi
  cp -p "${out_fn}" "${COMOUTobs}/${out_fn}"
fi

# GHCN snow depth data
if [ "${OBS_TYPE}" = "GHCN" ]; then
  # GHCN are time-stamped at 18. If assimilating at 00, need to use previous day's obs, 
  # so that obs are within DA window.
  obs_fn="ghcn_snwd_ioda_${YYYP}${MP}${DP}${HP}.nc"
  obs_fp="${OBSDIR}/GHCN/${YYYY}/${obs_fn}"
  out_fn="GHCN_${YYYY}${MM}${DD}${HH}.nc"

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
