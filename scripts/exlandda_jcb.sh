#!/bin/sh

set -xue

# Set other dates
#PTIME=$($NDATE -${DATE_CYCLE_FREQ_HR} $PDY$cyc)
PTIME=$( date --utc --date "${PDY} ${cyc} UTC - ${DATE_CYCLE_FREQ_HR} hours" "+%Y%m%d%H" )

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}


snow_window_begin="${YYYP}-${MP}-${DP}T${HP}:00:00Z"
snow_window_lenth="PT${DATE_CYCLE_FREQ_HR}H"


# update jcb-base yaml file
settings="\
  'PARMlandda': ${PARMlandda}
  'snow_window_begin': ${snow_window_begin}
  'snow_window_length': ${snow_window_length}
  'snow_fv3jedi_files_path': ${DATA}/fv3jedi
  'snow_layout_x':
  'snow_layout_y':
  'snow_npx_anl':
  'snow_npy_anl':
  'snow_npz_anl':
  'snow_npx_ges':
  'snow_npy_ges':
  'snow_npz_ges':
  'FIXlandda': ${FIXlandda}
  'RES': ${RES}
  'snow_bkg_path':
  'snow_bkg_time_fv3':
  'snow_bkg_time_iso':
  'snow_bump_data_dir': ${DATA}/berror
  'snow_obsdatain_path':
  'snow_obsdatain_prefix':
  'snow_obsdataout_path':
  'snow_obsdataout_prefix':
  'snow_obsdataout_suffix':
  'obs_from_jcb':
" # End of settings variable

fp_template="${PARMlandda}/jedi/jcb-base_snow.yaml.j2"
fn_jcb_base="${DATA}/jcb-base_snow.yaml"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_jcb_base}"

${USHlandda}/jcb_setup.py

