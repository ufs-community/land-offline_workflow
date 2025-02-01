#!/bin/sh

set -xue

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}



# update jcb-base yaml file
settings="\
  'PARMlandda': ${PARMlandda}
  'snow_winddow_begin': 
  'snow_window_length':
  'snow_fv3jedi_files_path':
  'snow_layout_x':
  'snow_layout_y':
  'snow_npx_anl':
  'snow_npy_anl':
  'snow_npz_anl':
  'snow_npx_ges':
  'snow_npy_ges':
  'snow_npz_ges':
  'FIXlandda': ${FIXlandda}
  'res': ${RES}
  'snow_bkg_path':
  'snow_bkg_time_fv3':
  'snow_bkg_time_iso':
  'DATA': ${DATA}
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

