#!/usr/bin/env python3

###################################################################### CHJ #####
#
# Setting up workflow environemnt
#
###################################################################### CHJ #####

import argparse
import os
import sys
import socket
import shutil
import yaml
import math
from datetime import datetime, timedelta

dirpath = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(dirpath, '../ush'))

from fill_jinja_template import fill_jinja_template
from uwtools.api.rocoto import realize


# Main part (will be called at the end) ============================= CHJ =====
def setup_wflow_env(machine):
# =================================================================== CHJ =====

    machine = machine.lower()
    print(f''' Machine (platform) name: {machine} ''')
    # Set directory paths
    parm_dir = os.getcwd()
    print(f''' Current directory (PARMdir): {parm_dir} ''')
    home_dir = os.path.dirname(parm_dir)
    print(f''' Home directory (HOMEdir): {home_dir} ''')
    exp_basedir = os.path.dirname(home_dir)
    print(f''' Experimental base directory (exp_basedir): {exp_basedir} ''')

    # Set default values of input parameters
    config_parm = set_default_parm()

    # Set machine-specific parameters
    machine_config = set_machine_parm(machine)

    # Merge default and machine-specific parameters
    config_parm.update(machine_config)

    # Add extra parameters
    config_parm["exp_basedir"] = exp_basedir
    config_parm["MACHINE"] = machine
    config_parm["res_p1"] = int(config_parm.get("RES")) + 1

    # Read input YAML file
    yaml_file = "config.yaml"
    try:
        with open(yaml_file, 'r') as f:
            yaml_data = yaml.safe_load(f)
        f.close()
#        print(f''' Input YAML file:, {yaml_data} ''')
    except FileNotFoundError:
        print(f''' FATAL ERROR: Input YAML file {yaml_file} does not exist! ''')

    for key,value in yaml_data.items():
        if key in config_parm:
            config_parm[key] = value

    # Create an experimental case directory
    if config_parm.get("EXP_CASE_NAME") is None:
        exp_case_name = f'''{config_parm.get("APP")}_{config_parm.get("RUN")}'''
        config_parm.update({'EXP_CASE_NAME': exp_case_name})
    else:
        exp_case_name = config_parm.get("EXP_CASE_NAME")

    # Calculate date for the second cycle
    date_first_cycle = config_parm.get("DATE_FIRST_CYCLE")
    date_cycle_freq_hr = config_parm.get("DATE_CYCLE_FREQ_HR")
    next_date = datetime.strptime(str(date_first_cycle), "%Y%m%d%H") + timedelta(hours=date_cycle_freq_hr)
    date_second_cycle = next_date.strftime("%Y%m%d%H")
    config_parm["date_second_cycle"] = date_second_cycle

    # Calculate HPC parameter values
    app = config_parm.get("APP")
    atm_layout_x = config_parm.get("ATM_LAYOUT_X")
    atm_layout_y = config_parm.get("ATM_LAYOUT_Y")
    atm_io_layout_x = config_parm.get("ATM_IO_LAYOUT_X")
    atm_io_layout_y = config_parm.get("ATM_IO_LAYOUT_Y")    
    lnd_layout_x = config_parm.get("LND_LAYOUT_X")
    lnd_layout_y = config_parm.get("LND_LAYOUT_Y")
    max_cores_per_node = config_parm.get("MAX_CORES_PER_NODE")

    nprocs_forecast_lnd = 6*lnd_layout_x*lnd_layout_y
    if app == "ATML":
        nprocs_forecast_atm = 6*(atm_layout_x*atm_layout_y+atm_io_layout_x*atm_io_layout_y)
    else:
        nprocs_forecast_atm = nprocs_forecast_lnd

    nprocs_forecast = nprocs_forecast_lnd + nprocs_forecast_atm + lnd_layout_x*lnd_layout_y
    if nprocs_forecast <= max_cores_per_node:
        nnodes_forecast = 1
        nprocs_per_node = nprocs_forecast
    else:
        nnodes_forecast = math.ceil(nprocs_forecast/max_cores_per_node)
        nprocs_per_node = math.ceil(nprocs_forecast/nnodes_forecast)

    config_parm.update({
        'nprocs_forecast_lnd': nprocs_forecast_lnd,
        'nprocs_forecast_atm': nprocs_forecast_atm,
        'nprocs_forecast': nprocs_forecast,
        'nnodes_forecast': nnodes_forecast,
        'nprocs_per_node': nprocs_per_node,
        })
   
    config_parm_str = yaml.dump(config_parm, sort_keys=True, default_flow_style=False)
#    print("FINAL configuration=",config_parm_str)

    exp_case_path = os.path.join(exp_basedir, "exp_case", exp_case_name) 
    if os.path.exists(exp_case_path) and os.path.isdir(exp_case_path):
        tmp_new_name = exp_case_path+"_old"
        if os.path.exists(tmp_new_name):
            shutil.rmtree(tmp_new_name)
        os.rename(exp_case_path, tmp_new_name)
        os.makedirs(exp_case_path)
    else:
        os.makedirs(exp_case_path)

    print(f''' Experimental case directory {exp_case_path} has been created. ''')

    # Create YAML file for Rocoto XML from template
    fn_yaml_rocoto_template = "template.land_analysis.yaml"
    fn_yaml_rocoto = "land_analysis.yaml"
    fp_yaml_rocoto_template = os.path.join(parm_dir, "templates", fn_yaml_rocoto_template)
    fp_yaml_rocoto = os.path.join(exp_case_path, fn_yaml_rocoto)
    print(f''' Rocoto YAML template: {fp_yaml_rocoto_template} ''')
    try:
        fill_jinja_template([
            "-u", config_parm_str,
            "-t", fp_yaml_rocoto_template,
            "-o", fp_yaml_rocoto ])
    except:
        print(f''' FATAL ERROR: Call to python script fill_jinja_template.py 
              to create a '{fp_yaml_rocoto}' file from a jinja2 template failed. ''')
        return False

    # Call uwtools to create Rocoto XML file
    fn_xml_rocoto = "land_analysis.xml"
    fp_xml_rocoto = os.path.join(exp_case_path, fn_xml_rocoto)
    realize(
        config = fp_yaml_rocoto,
        output_file = fp_xml_rocoto,
        )

    # Create rocoto launch file to exp_case directory
    fn_launch_template = "template.launch_rocoto_wflow.sh"
    fn_launch_script = "launch_rocoto_wflow.sh"
    fp_launch_template = os.path.join(parm_dir, "templates", fn_launch_template)
    fp_launch_script = os.path.join(exp_case_path, fn_launch_script)
    shutil.copyfile(fp_launch_template, fp_launch_script)
    with open(fp_launch_script, 'r') as file:
        fdata = file.read()
    fdata = fdata.replace('{{ parm_dir }}', parm_dir)
    fdata = fdata.replace('{{ fn_xml_rocoto }}', fn_xml_rocoto)
    fdata = fdata.replace('{{ exp_case_path }}', exp_case_path)
    with open(fp_launch_script, 'w') as file:
        file.write(fdata)
    os.chmod(fp_launch_script, 0o755)

    # Add links to log/tmp/com directories within exp_case directory
    envir = config_parm.get("envir")
    model_ver = config_parm.get("model_ver")    
    net = config_parm.get("NET")
    run = config_parm.get("RUN")
    ptmp = os.path.join(exp_basedir,"ptmp")
    log_dir_src = os.path.join(ptmp, envir, "com/output/logs")
    log_dir_dst = os.path.join(exp_case_path, "log_dir")
    tmp_dir_src = os.path.join(ptmp, envir, "tmp")
    tmp_dir_dst = os.path.join(exp_case_path, "tmp_dir")
    com_dir_src = os.path.join(ptmp, envir, "com", net, model_ver)
    com_dir_dst = os.path.join(exp_case_path, "com_dir")
    os.symlink(log_dir_src, log_dir_dst)
    os.symlink(tmp_dir_src, tmp_dir_dst)
    os.symlink(com_dir_src, com_dir_dst)

    # Create coldstart txt file for the first cycle when APP = LND
    coldstart = config_parm.get("COLDSTART")
    if app == "LND" and coldstart == "YES":
        fn_pass = f"task_skip_coldstart_{date_first_cycle}.txt"
        open(os.path.join(exp_case_path,fn_pass), 'a').close()



# Default values of configuration =================================== CHJ =====
def set_default_parm():
# =================================================================== CHJ =====

    default_config = {
        "ACCOUNT": "epic",
        "APP": "LND",
        "ATM_IO_LAYOUT_X": 1,
        "ATM_IO_LAYOUT_Y": 1,
        "ATM_LAYOUT_X": 3,
        "ATM_LAYOUT_Y": 8,
        "ATMOS_FORC": "gswp3",
        "COMINgdas": "",
        "CCPP_SUITE": "FV3_GFS_v17_p8",
        "COLDSTART": "NO",
        "COUPLER_CALENDAR": 2,
        "DATE_CYCLE_FREQ_HR": 24,
        "DATE_FIRST_CYCLE": 200001030000,
        "DATE_LAST_CYCLE": 200001040000,
        "DT_ATMOS": 900,
        "DT_RUNSEQ": 3600,
        "envir": "test",
        "EXP_CASE_NAME": None,
        "FCSTHR": 24,
        "FHROT": 0,
        "FRAC_GRID": "NO",
        "IC_DATA_MODEL": "GFS",
        "IMO": 384,
        "JEDI_ALGORITHM": "letkf",
        "JEDI_PATH": "/path/to/jedi/install/dir",
        "JEDI_PY_VER": "python3.10",
        "JMO": 190,
        "KEEPDATA": "YES",
        "LND_CALC_SNET": ".true.",
        "LND_IC_TYPE": "custom",
        "LND_INITIAL_ALBEDO": 0.25,
        "LND_LAYOUT_X": 1,
        "LND_LAYOUT_Y": 2,
        "LND_OUTPUT_FREQ_SEC": 21600,
        "MACHINE": "/machine/platform/name",
        "MED_COUPLING_MODE": "ufs.nfrac.aoflux",
        "model_ver": "v2.1.0",
        "NET": "landda",
        "NPROCS_ANALYSIS": 6,
        "NPROCS_FCST_IC": 36,
        "NPZ": 127,
        "OBSDIR": "",
        "OBS_TYPE": "GHCN",
        "OUTPUT_FH": "1 -1",
        "RES": 96,
        "RESTART_INTERVAL": "12 -1",
        "RUN": "landda",
        "WARMSTART_DIR": "/path/to/wart/start/dir",
        "WE2E_TEST": "NO",
        "WRITE_GROUPS": 1,
        "WRITE_TASKS_PER_GROUP": 6,
    }

    return default_config



# Machine-specific values of configuration ========================== CHJ =====
def set_machine_parm(machine):
# =================================================================== CHJ =====

    lowercase_machine = machine.lower()
    match lowercase_machine:
        case "hera":
            JEDI_PATH = "/scratch2/NAGAPE/epic/UFS_Land-DA_v2.1/jedi_v8_ic"
            MAX_CORES_PER_NODE = 40
            WARMSTART_DIR = "/scratch2/NAGAPE/epic/UFS_Land-DA_v2.1/inputs/DATA_RESTART"
        case "orion":
            JEDI_PATH = "/work/noaa/epic/UFS_Land-DA_v2.1/jedi_v8_ic_orion"
            MAX_CORES_PER_NODE = 40
            WARMSTART_DIR = "/work/noaa/epic/UFS_Land-DA_v2.1/inputs/DATA_RESTART"
        case "hercules":
            JEDI_PATH = "/work/noaa/epic/UFS_Land-DA_v2.1/jedi_v8_ic_hercules"
            MAX_CORES_PER_NODE = 80
            WARMSTART_DIR = "/work/noaa/epic/UFS_Land-DA_v2.1/inputs/DATA_RESTART"
        case "singularity":
            JEDI_PATH = "SINGULARITY_WORKING_DIR"
            MAX_CORES_PER_NODE = 40
            WARMSTART_DIR = "SINGULARITY_WORKING_DIR"
        case _:
            sys.exit(f"FATAL ERROR: this machine/platform '{lowercase_machine}' is NOT supported yet !!!")

    machine_config = {
        "JEDI_PATH": JEDI_PATH,
        "MAX_CORES_PER_NODE": MAX_CORES_PER_NODE,
        "WARMSTART_DIR": WARMSTART_DIR,
    }

    return machine_config



# Parse arguments =================================================== CHJ =====
def parse_args(argv):
# =================================================================== CHJ =====
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Generate case-specific workflow environment.")

    parser.add_argument(
        "-p", "--platform",
        dest="MACHINE",
#        required=True,
        help="Platform (machine) name.",
    )

    return parser.parse_args(argv)



# Detect platform (machine) ========================================= CHJ =====
def detect_platform():
# =================================================================== CHJ =====

    if os.path.isdir("/scratch2/NAGAPE"):
        machine = "hera"
    elif os.path.isdir("/work/noaa"):
        machine = socket.gethostname().split('-')[0]  # orion/hercules
    elif os.path.isdir("/ncrc"):
        machine = "gaea"
    elif os.path.isdir("/glade"):
        machine = "derecho"
    elif os.path.isdir("/lfs4/HFIP"):
        machine = "jet"
    else:
        sys.exit(f"Machine (platform) is not detected. Please set it with -p argument")

    print(f" Machine (platform) detected: {machine}")

    return machine


# Main call ========================================================= CHJ =====
if __name__=='__main__':
    args = parse_args(sys.argv[1:])
    MACHINE=args.MACHINE
    if MACHINE is None:
        MACHINE = detect_platform()
   
    setup_wflow_env(MACHINE)

