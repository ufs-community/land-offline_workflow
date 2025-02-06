#!/bin/sh

set -xue

# Set other dates
YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
cdate="${PDY}${cyc}"

PTIME=$($NDATE -${DATE_CYCLE_FREQ_HR} $PDY$cyc)
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

cycle_freq_hr_half=$(( DATE_CYCLE_FREQ_HR / 2 ))
HPTIME=$($NDATE -${cycle_freq_hr_half} $PDY$cyc)
YYYHP=${HPTIME:0:4}
MHP=${HPTIME:4:2}
DHP=${HPTIME:6:2}
HHP=${HPTIME:8:2}

final_prints_frequency="PT${cycle_freq_hr_half}H"
snow_bkg_time_fv3="${YYYY}${MM}${DD}_${HH}0000"
snow_bkg_time_iso="${YYYY}-${MM}-${DD}T${HH}:00:00Z"
snow_fv3jedi_files_path="./Data/fv3files"
snow_window_begin="${YYYHP}-${MHP}-${DHP}T${HHP}:00:00Z"
snow_window_length="PT${DATE_CYCLE_FREQ_HR}H"

# update jcb-base yaml file
settings="\
  'FIXlandda': ${FIXlandda}
  'final_prints_frequency': ${final_prints_frequency}
  'PARMlandda': ${PARMlandda}
  'RES': ${RES}
  'snow_window_begin': !!str ${snow_window_begin}
  'snow_window_length': ${snow_window_length}
  'snow_fv3jedi_files_path': ${snow_fv3jedi_files_path}
  'snow_layout_x': 1
  'snow_layout_y': 1
  'snow_npx_anl': ${res_p1}
  'snow_npy_anl': ${res_p1}
  'snow_npz_anl': ${NPZ}
  'snow_npx_ges': ${res_p1}
  'snow_npy_ges': ${res_p1}
  'snow_npz_ges': ${NPZ}
  'snow_bkg_path': ./bkg
  'snow_bkg_time_fv3': !!str ${snow_bkg_time_fv3}
  'snow_bkg_time_iso': !!str ${snow_bkg_time_iso}
  'snow_bump_data_dir': ./berror
  'snow_obsdatain_path': ./obs
  'snow_obsdatain_prefix': "obs_${cycle}."
  'snow_obsdataout_path': ./diags
  'snow_obsdataout_prefix': "diag_"
  'snow_obsdataout_suffix': "_${cdate}.nc"
  'OBS_GHCN': ${OBS_GHCN}
  'OBS_IMS': ${OBS_IMS}
" # End of settings variable

template_fp="${PARMlandda}/jedi/jcb-base_snow.yaml.j2"
jcb_base_fn="jcb-base_snow.yaml"
jcb_base_fp="${DATA}/${jcb_base_fn}"
jcb_out_fn="jedi_jcb_snow_nml.yaml"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${template_fp}" -o "${jcb_base_fp}"

${USHlandda}/jcb_setup.py -i "${jcb_base_fn}" -o "${jcb_out_fn}" -g "${FRAC_GRID}"
if [ $? -ne 0 ]; then
  err_exit "Generation of JEDI YAML file by JCB failed !!!"
fi

cp -p ${jcb_out_fn} ${COMOUT}
