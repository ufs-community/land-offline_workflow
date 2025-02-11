#!/bin/sh

set -xue

# Set other dates
NTIME=$($NDATE ${DATE_CYCLE_FREQ_HR} $PDY$cyc)

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}

nYYYY=${NTIME:0:4}
nMM=${NTIME:4:2}
nDD=${NTIME:6:2}
nHH=${NTIME:8:2}

DO_PLOT_STATS="YES"
DO_PLOT_TIME_HISTORY="YES"
DO_PLOT_RESTART="YES"

############################################################
# Stats Plot
############################################################
if [ "${DO_PLOT_STATS}" = "YES" ]; then
  # Field variable
  field_var="OMA"
  # Field Range for scatter plot: [Low,High]
  field_range_low=-300
  field_range_high=300
  # Number of bins in histogram plot
  nbins=100
  # Plot type (scatter/histogram/both)
  plottype="both"
  # Figure title
  title_fig="GHCN Snow Depth (mm)::Obs-Ana::${PDY}"
  # Prefix of output file name
  output_prefix="hofx_oma_${PDY}"
  
  cat > plot_hofx.yaml <<EOF
hofx_files: '${DATA_HOFX}'
field_var: '${field_var}'
field_range: [${field_range_low},${field_range_high}]
jedi_exe: '${JEDI_ALGORITHM}'
nbins: ${nbins}
plottype: '${plottype}'
title_fig: '${title_fig}'
output_prefix: '${output_prefix}'
cartopy_ne_path: '${FIXlandda}/NaturalEarth'
EOF
  
  ${USHlandda}/hofx_analysis_stats.py
  if [ $? -ne 0 ]; then
    err_exit "Scatter/Histogram plots failed"
  fi
  
  # Copy result files to COMOUT
  cp -p ${output_prefix}* ${COMOUTplot}
fi


############################################################
# Time-history Plot
############################################################
if [ "${DO_PLOT_TIME_HISTORY}" = "YES" ]; then
  fn_data_anal_prefix="analysis_"
  fn_data_anal_suffix=".log"
  fn_data_fcst_prefix="forecast_"
  fn_data_fcst_suffix=".log"
  out_title_anal_base="Land-DA::Analysis::QC SnowDepth::"
  out_fn_anal_base="landda_timehistory_"
  out_title_time="Land-DA::Wall-clock time"
  out_fn_time="landda_timehistory_wtime"

  cat > plot_timehistory.yaml <<EOF
path_data: '${LOGDIR}'
work_dir: '${DATA}'
fn_data_anal_prefix: '${fn_data_anal_prefix}'
fn_data_anal_suffix: '${fn_data_anal_suffix}'
fn_data_fcst_prefix: '${fn_data_fcst_prefix}'
fn_data_fcst_suffix: '${fn_data_fcst_suffix}'
jedi_exe: '${JEDI_ALGORITHM}'
nprocs_anal: '${NPROCS_ANALYSIS}'
nprocs_fcst: '${nprocs_forecast}'
obs_type: '${OBS_TYPE}'
out_title_anal_base: '${out_title_anal_base}'
out_fn_anal_base: '${out_fn_anal_base}'
out_title_time: '${out_title_time}'
out_fn_time: '${out_fn_time}'
EOF

  ${USHlandda}/plot_analysis_timehistory.py
  if [ $? -ne 0 ]; then
    err_exit "Time-history plots failed"
  fi

  # Copy result files to COMOUT
  cp -p ${out_fn_anal_base}* ${COMOUTplot}
  cp -p ${out_fn_time}* ${COMOUTplot}
fi


###########################################################
# Restart Plot
###########################################################
if [ "${DO_PLOT_RESTART}" = "YES" ]; then
  fn_data_base="ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile"
  fn_data_ext=".nc"
  soil_level_number="1"
  out_title_base="Land-DA::restart::${nYYYY}-${nMM}-${nDD}_${nHH}::"
  out_fn_base="landda_out_restart_${nYYYY}-${nMM}-${nDD}_${nHH}_"

  cat > plot_restart.yaml <<EOF
path_data: '${COMIN}/RESTART'
work_dir: '${DATA}'
fn_data_base: '${fn_data_base}'
fn_data_ext: '${fn_data_ext}'
soil_lvl_number: '${soil_level_number}'
out_title_base: '${out_title_base}'
out_fn_base: '${out_fn_base}'
cartopy_ne_path: '${FIXlandda}/NaturalEarth'
EOF

  ${USHlandda}/plot_forecast_restart.py
  if [ $? -ne 0 ]; then
    err_exit "Forecast restart plots failed"
  fi

  # Copy result files to COMOUT
  cp -p ${out_fn_base}* ${COMOUTplot}
fi

