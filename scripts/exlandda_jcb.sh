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


snow_window_begin="${YYYP}-${MP}-${DP}T${HP}:00:00Z"
snow_window_length="PT${DATE_CYCLE_FREQ_HR}H"
snow_bkg_time_fv3="${YYYP}${MP}${DP}_${HP}0000"

# update jcb-base yaml file
settings="\
  'PARMlandda': ${PARMlandda}
  'snow_window_begin': !!str ${snow_window_begin}
  'snow_window_length': ${snow_window_length}
  'snow_fv3jedi_files_path': ${DATA}/fv3jedi
  'snow_layout_x': test1
  'snow_layout_y': test2
  'snow_npx_anl': test3
  'snow_npy_anl': test4
  'snow_npz_anl': test5
  'snow_npx_ges': test6
  'snow_npy_ges': test7
  'snow_npz_ges': test9
  'FIXlandda': ${FIXlandda}
  'RES': ${RES}
  'snow_bkg_path': test10
  'snow_bkg_time_fv3': !!str ${snow_bkg_time_fv3}
  'snow_bkg_time_iso': !!str ${snow_window_begin}
  'snow_bump_data_dir': ${DATA}/berror
  'snow_obsdatain_path': test13
  'snow_obsdatain_prefix': test14
  'snow_obsdataout_path': test15
  'snow_obsdataout_prefix': test16
  'snow_obsdataout_suffix': test17
  'obs_from_jcb': test18
  'OBS_GHCN': ${OBS_GHCN}
  'OBS_IMS': ${OBS_IMS}
" # End of settings variable

template_fp="${PARMlandda}/jedi/jcb-base_snow.yaml.j2"
jcb_base_fn="jcb-base_snow.yaml"
jcb_base_fp="${DATA}/${jcb_base_fn}"
jcb_out_fn="jedi_snow.yaml"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${template_fp}" -o "${jcb_base_fp}"

${USHlandda}/jcb_setup.py -i "${jcb_base_fn}" -o "${jcb_out_fn}"
if [ $? -ne 0 ]; then
  err_exit "Generation of GHCN obs file failed !!!"
fi

cp -p ${jcb_out_fn} ${COMOUT}
