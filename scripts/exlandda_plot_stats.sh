#!/bin/sh

set -xue

# Set other dates
NTIME=$($NDATE {DATE_CYCLE_FREQ_HR} $PDY$cyc)

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}

nYYYY=${NTIME:0:4}
nMM=${NTIME:4:2}
nDD=${NTIME:6:2}
nHH=${NTIME:8:2}

############################################################
# Stats Plot
############################################################

# Path to the directory containing the input file
INPUTFP="${DATA_HOFX}"
# Field variable
FIELDVAR="OMA"
# Field Range for scatter plot: [Low,High]
FRLOW=-300
FRHIGH=300
# Number of bins in histogram plot
NBINS=100
# Plot type (scatter/histogram/both)
PLOTTYPE="both"
# Figure title
FIGTITLE="GHCN Snow Depth (mm)::Obs-Ana::${PDY}"
# Prefix of output file name
PREOUTFN="hofx_oma_${PDY}"

cat > plot_hofx.yaml <<EOF
hofx_files: '${INPUTFP}'
field_var: '${FIELDVAR}'
field_range: [${FRLOW},${FRHIGH}]
nbins: ${NBINS}
plottype: '${PLOTTYPE}'
title_fig: '${FIGTITLE}'
output_prefix: '${PREOUTFN}'
machine: '${MACHINE}'
EOF

${USHlandda}/hofx_analysis_stats.py
if [ $? -ne 0 ]; then
  err_exit "Scatter/Histogram plots failed"
fi

# Copy result files to COMOUT
cp -p ${PREOUTFN}* ${COMOUTplot}


############################################################
# Time-history Plot
############################################################

FN_DATA_ANAL_PREFIX="analysis_"
FN_DATA_ANAL_SUFFIX=".log"
FN_DATA_FCST_PREFIX="forecast_"
FN_DATA_FCST_SUFFIX=".log"
OUT_TITLE_ANAL_BASE="Land-DA::Analysis::QC SnowDepthGHCN::"
OUT_FN_ANAL_BASE="landda_timehistory_"
OUT_TITLE_TIME="Land-DA::Wall-clock time"
OUT_FN_TIME="landda_timehistory_wtime"

cat > plot_timehistory.yaml <<EOF
path_data: '${LOGDIR}'
work_dir: '${DATA}'
fn_data_anal_prefix: '${FN_DATA_ANAL_PREFIX}'
fn_data_anal_suffix: '${FN_DATA_ANAL_SUFFIX}'
fn_data_fcst_prefix: '${FN_DATA_FCST_PREFIX}'
fn_data_fcst_suffix: '${FN_DATA_FCST_SUFFIX}'
nprocs_anal: '${NPROCS_ANALYSIS}'
nprocs_fcst: '${NPROCS_FORECAST}'
out_title_anal_base: '${OUT_TITLE_ANAL_BASE}'
out_fn_anal_base: '${OUT_FN_ANAL_BASE}'
out_title_time: '${OUT_TITLE_TIME}'
out_fn_time: '${OUT_FN_TIME}'
EOF

${USHlandda}/plot_analysis_timehistory.py
if [ $? -ne 0 ]; then
  err_exit "Time-history plots failed"
fi

# Copy result files to COMOUT
cp -p ${OUT_FN_ANAL_BASE}* ${COMOUTplot}
cp -p ${OUT_FN_TIME}* ${COMOUTplot}


############################################################
# Restart Plot
############################################################

FN_DATA_BASE="ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile"
FN_DATA_EXT=".nc"
SOIL_LEVEL_NUMBER="1"
OUT_TITLE_BASE="Land-DA::restart::${nYYYY}-${nMM}-${nDD}_${nHH}::"
OUT_FN_BASE="landda_out_restart_${nYYYY}-${nMM}-${nDD}_${nHH}_"

cat > plot_restart.yaml <<EOF
path_data: '${COMIN}/RESTART'
work_dir: '${DATA}'
fn_data_base: '${FN_DATA_BASE}'
fn_data_ext: '${FN_DATA_EXT}'
soil_lvl_number: '${SOIL_LEVEL_NUMBER}'
out_title_base: '${OUT_TITLE_BASE}'
out_fn_base: '${OUT_FN_BASE}'
machine: '${MACHINE}'
EOF

${USHlandda}/plot_forecast_restart.py
if [ $? -ne 0 ]; then
  err_exit "Forecast restart plots failed"
fi

# Copy result files to COMOUT
cp -p ${OUT_FN_BASE}* ${COMOUTplot}

