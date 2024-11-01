#!/usr/bin/env python3

###################################################################### CHJ #####
#
# Setting up workflow environemnt
#
###################################################################### CHJ #####

import os
import sys
import yaml
import numpy as np

# Main part (will be called at the end) ============================= CHJ =====
def setup_wflow_env():
# =================================================================== CHJ =====

    # Set directory paths
    parm_dir = os.getcwd()
    print(f''' Current directory (PARMdir): {parm_dir} ''')
    home_dir = os.path.dirname(parm_dir)
    print(f''' Home directory (HOMEdir): {home_dir} ''')
    exp_basedir = os.path.dirname(home_dir)
    print(f''' Experimental base directory (EXP_BASEDIR): {exp_basedir} ''')

    # Set default values of input parameters
    config_parm = set_default_parm()

    # Set machine-specific parameters
    machine_config = set_machine_parm(machine)

    # Merge default and machine-specific parameters
    config_parm.update(machine_config)

    # Add extra parameters
    config_parm["exp_basedir"] = exp_basedir
    config_parm["machine"] = machine

    # Read input YAML file
    yaml_file = "config.yaml"
    try:
        with open(yaml_file, 'r') as f:
            yaml_data = yaml.safe_load(f)
        f.close()
        print(f''' Input YAML file:, {yaml_data} ''')
    except FileNotFoundError:
        print(f''' FATAL ERROR: Input YAML file {yaml_file} does not exist! ''')

    for key,value in yaml_data.items():
        if key in config_parm:
            config_parm[key] = vlue

    print(config_parm)

    # Create an experimental case directory
    exp_case_name = f"{config_parm[app]}_{config_parm[run]}" 
    exp_case_path = os.path.join(exp_basedir, "exp_case", exp_case_name) 
    if not os.path.exists(exp_case_path):
        os.makedirs(exp_case_path)

    # Create the YAML file for Rocoto XML from template


    # Call uwtools to create Rocoto XML file



# Default values of configuration =================================== CHJ =====
def set_default_parm():
# =================================================================== CHJ =====

    default_config = {
        "account": "epic",
        "allcomp_read_restart": false,
        "allcomp_start_type": "startup",
        "app": "LND",
        "atm_model": "datm",
        "ccpp_suite": "FV3_GFS_v17_p8",
        "coupler_calendar": "2",
        "date_cycle_freq_hr": "24",
        "date_first_cycle": "200001030000",
        "date_last_cycle": "200001040000",
        "dt_atmos": "900",
        "dt_runseq": "3600",
        "envir": "test",
        "exp_basedir": "/path/to/parent/dir/of/home",
        "fcsthr": "24",
        "jedi_install": "/path/to/jedi/install/dir",
        "lnd_calc_snet": true,
        "lnd_ic_type": "custom",
        "lnd_initial_albedo": "0.25",
        "lnd_layout_x": "1",
        "lnd_layout_y": "2",
        "lnd_output_freq_sec": "21600",
        "machine": "/machine/platform/name",
        "med_coupling_mode": "ufs.nfrac.aoflux",
        "model_ver": "v2.1.0",
        "net": "landda",
        "nprocs_analysis": "6",
        "nprocs_forecast": "26",
        "nprocs_forecast_atm": "12",
        "nprocs_forecast_lnd": "12",
        "nnodes_forecast": "1",
        "nprocs_per_node": "26",
        "res": "96",
        "restart_interval": "12 -1",
        "run": "landda",
        "warmstart_dir": "/path/to/wart/start/dir",
        "we2e_test": "NO",
        "write_groups": "1",
        "write_tasks_per_group": "6",
    }

    return default_config


# Machine-specific values of configuration ========================== CHJ =====
def set_machine_parm(machine):
# =================================================================== CHJ =====

    lowercase_machine = machine.lower()
    match lowercase_machine:
        case "hera":
            jedi_install = ""
        case "orion":
            jedi_install = ""
        case "hercules":
            jedi_install = ""
        case "singularity":
            jedi_install = ""

    machine_config = {
        "jedi_install": jedi_install,
    }

    return machine_config


# Main call ========================================================= CHJ =====
if __name__=='__main__':
    setup_wflow_env()

