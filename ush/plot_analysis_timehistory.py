#!/usr/bin/env python3

###################################################################### CHJ #####
## Name		: plot_analysis_timehistory.py
## Usage	: Plot timehistory of analysis output
## Input files  : analysis_YYYYMMDDHH.log
## NOAA/EPIC
## History ===============================
## V000: 2024/10/14: Chan-Hoo Jeon : Preliminary version
###################################################################### CHJ #####

import os, sys
import pathlib
import yaml
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import matplotlib.ticker
import matplotlib as mpl


# Main part (will be called at the end) ============================= CHJ =====
def main():
# =================================================================== CHJ =====

#    yaml_file="plot_restart.yaml"
#    with open(yaml_file, 'r') as f:
#        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
#    f.close()
#    print("YAML_DATA:",yaml_data)

#    path_data=yaml_data['path_data']
#    work_dir=yaml_data['work_dir']
#    fn_data_base=yaml_data['fn_data_base']
#    out_title_base=yaml_data['out_title_base']
#    out_fn_base=yaml_data['out_fn_base']

    path_data='/scratch2/NAGAPE/epic/Chan-hoo.Jeon/landda_benchmark/ptmp/test/com/output/logs'
    work_dir='/scratch2/NCEPDEV/fv3-cam/Chan-hoo.Jeon/landda_test/land-DA_workflow/ush'
    fn_data_anal_prefix='analysis_'
    fn_data_anal_suffix='.log'
    fn_data_fcst_prefix='forecast_'
    fn_data_fcst_suffix='.log'
    nprocs_anal="6"
    nprocs_fcst="26"
    out_title_anal_base='land-DA::Analysis::QC SnowDepthGHCN::'
    out_fn_anal_base='landda_timehistory_'
    out_title_time='land-DA::Wall-clock/Total-CPU time'
    out_fn_time='landda_wtime_'

    var_list=["totalSnowDepth"]
    nprocs_anal = int(nprocs_anal)
    nprocs_fcst = int(nprocs_fcst)

    # plot time-history
    for var_nm in var_list:
        var_dict_anal = get_data_analysis(path_data,fn_data_anal_prefix,fn_data_anal_suffix,nprocs_anal,var_nm)
        var_dict_fcst = get_data_forecast(path_data,fn_data_fcst_prefix,fn_data_fcst_suffix,nprocs_fcst)
        plot_data(var_dict_anal,var_dict_fcst,out_title_anal_base,out_fn_anal_base,out_title_time,out_fn_time,work_dir,var_nm)


# Get data from files =============================================== CHJ =====
def get_data_analysis(path_data,fn_data_anal_prefix,fn_data_anal_suffix,nprocs_anal,var_nm):
# =================================================================== CHJ =====

    print(' ===== var name: '+var_nm+' ========================')
    # Find files with the sampe prefix
    fp_data_anal_prefix = os.path.join(path_data,fn_data_anal_prefix)
    files = []
    for entry in os.scandir(path_data):
        if entry.is_file() and entry.name.startswith(fn_data_anal_prefix):
            files.append(entry.path)

    files.sort()
    #print("Files=",files)

    wtime_oops_prefix = "OOPS_STATS util::Timers::Total"

    file_date = []
    min_val_final = []
    max_val_final = []
    rms_val_final = []
    wtime_oops = []
    for file_fp in files:
        file_date_raw = file_fp.removeprefix(fp_data_anal_prefix)
        file_date_raw = file_date_raw.removesuffix(fn_data_anal_suffix)
        file_date_tmp = f"{file_date_raw[0:4]}-{file_date_raw[4:6]}-{file_date_raw[6:8]}-{file_date_raw[8:10]}"
        file_date.append(file_date_tmp)
        print("File date=",file_date_tmp)

        min_val_file = []
        max_val_file = []
        rms_val_file = []
        with open(file_fp, 'r') as file:
            for line in file:
                if line.startswith(var_nm):
                    line_data_raw = line
                    #print("Line data=",line_data_raw)
                    line_split = line.split('| ')[1].split(' ')
                    #print("Line split=",line_split)
                    min_var = line_split[0].split(':')[0]
                    min_val = line_split[0].split(':')[1]
                    min_val = float(min_val)
                    min_val_file.append(min_val)
                    #print(min_var,"=",min_val,type(min_val))
                    max_var = line_split[1].split(':')[0]
                    max_val = line_split[1].split(':')[1]
                    max_val = float(max_val)
                    max_val_file.append(max_val)
                    #print(max_var,"=",max_val,type(max_val))
                    rms_var = line_split[2].split(':')[0]
                    rms_val = line_split[2].split(':')[1]
                    rms_val = float(rms_val)
                    rms_val_file.append(rms_val)
                    #print(rms_var,"=",rms_val,type(rms_val))
                if line.startswith(wtime_oops_prefix):
                    line_wtime_raw = line
                    line_split = line.split(' : ')[1].split(' ')
                    line_split = list(filter(None, line_split))
                    if len(line_split) == 5:
                        wtime_oops_file = float(line_split[2])
                        #print("WTIME OOPS AVG=",wtime_oops_file)

        min_val_final.append(min_val_file[-1])
        max_val_final.append(max_val_file[-1])
        rms_val_final.append(rms_val_file[-1])
        wtime_oops.append(wtime_oops_file)
    # ms to sec 
    wtime_oops = [x * 0.001 for x in wtime_oops]
    tcpu_oops = [x * nprocs_anal for x in wtime_oops]

    # Create dictionary
    var_dict_anal = {
        "Date": file_date,
        "Min": min_val_final,
        "Max": max_val_final,
        "RMS": rms_val_final,
        "wtime_oops": wtime_oops,
        "tcpu_oops": tcpu_oops
    }
    print("DICT=",var_dict_anal)

    return var_dict_anal


# Get data from files =============================================== CHJ =====
def get_data_forecast(path_data,fn_data_fcst_prefix,fn_data_fcst_suffix,nprocs_fcst):
# =================================================================== CHJ =====

    # Find files with the sampe prefix
    fp_data_fcst_prefix = os.path.join(path_data,fn_data_fcst_prefix)
    files = []
    for entry in os.scandir(path_data):
        if entry.is_file() and entry.name.startswith(fn_data_fcst_prefix):
            files.append(entry.path)

    files.sort()
    #print("Files=",files)

    wtime_uwm_prefix = "The total amount of wall time"

    file_date = []
    wtime_uwm = []
    for file_fp in files:
        file_date_raw = file_fp.removeprefix(fp_data_fcst_prefix)
        file_date_raw = file_date_raw.removesuffix(fn_data_fcst_suffix)
        file_date_tmp = f"{file_date_raw[0:4]}-{file_date_raw[4:6]}-{file_date_raw[6:8]}-{file_date_raw[8:10]}"
        file_date.append(file_date_tmp)
        print("File date=",file_date_tmp)

        with open(file_fp, 'r') as file:
            for line in file:
                if line.startswith(wtime_uwm_prefix):
                    line_wtime_raw = line
                    line_split = line.split(' = ')[1]
                    wtime_uwm_file = float(line_split)
                    #print("WTIME UFS Weather Model=",wtime_uwm_file)

        wtime_uwm.append(wtime_uwm_file)

    tcpu_uwm = [x * nprocs_fcst for x in wtime_uwm]

    # Create dictionary
    var_dict_fcst = {
        "Date": file_date,
        "wtime_uwm": wtime_uwm,
        "tcpu_uwm": tcpu_uwm
    }
    print("DICT=",var_dict_fcst)

    return var_dict_fcst


# Plot data ========================================================= CHJ =====
def plot_data(var_dict_anal,var_dict_fcst,out_title_anal_base,out_fn_anal_base,out_title_time,out_fn_time,work_dir,var_nm):
# =================================================================== CHJ =====

    out_title_anal = out_title_anal_base+var_nm
    out_fn_anal = out_fn_anal_base+var_nm

    df = pd.DataFrame(var_dict_anal)

    txt_fnt=7
    ln_wdth=0.75
    mk_sz=3
    
    # figsize=(width,height) in inches
    fig, axes = plt.subplots(nrows=2, ncols=1, sharex=True, figsize=(6,4))
    fig.suptitle(out_title_anal,fontsize=txt_fnt+1,y=0.95)

    axes[0].plot(df['Date'],df['Min'],'o-',color='blue',linewidth=ln_wdth,markersize=mk_sz,label='Min')
    axes[0].plot(df['Date'],df['Max'],'s-.',color='red',mfc='none',linewidth=ln_wdth,markersize=mk_sz,label='Max')
    axes[0].set_ylabel('Min / Max', fontsize=txt_fnt-1)
    axes[0].tick_params(axis="y",labelsize=txt_fnt-2)
    axes[0].legend(fontsize=txt_fnt-1)
    axes[0].grid(linewidth=0.2)

    axes[1].plot(df['Date'],df['RMS'],'o-',color='blue',linewidth=ln_wdth,markersize=mk_sz)
    axes[1].set_xlabel('Date', fontsize=txt_fnt-1)
    axes[1].set_ylabel('RMS', fontsize=txt_fnt-1)
    axes[1].tick_params(axis="x",labelsize=txt_fnt-2)
    axes[1].tick_params(axis="y",labelsize=txt_fnt-2)
    axes[1].grid(linewidth=0.2)

    plt.xticks(rotation=30, ha='right')
    plt.tight_layout()

    # Output figure
    ndpi = 300
    out_file(work_dir,out_fn_anal,ndpi)


# Output file ======================================================= CHJ =====
def out_file(work_dir,out_file,ndpi):
# =================================================================== CHJ =====
    # Output figure
    fp_out = os.path.join(work_dir,out_file)
    plt.savefig(fp_out+'.png',dpi=ndpi,bbox_inches='tight')
    plt.close('all')


# Main call ========================================================= CHJ =====
if __name__=='__main__':
    main()

