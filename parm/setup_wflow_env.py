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
#        print(f''' Input YAML file:, {yaml_data} ''')
    except FileNotFoundError:
        print(f''' FATAL ERROR: Input YAML file {yaml_file} does not exist! ''')

    for key,value in yaml_data.items():
        if key in config_parm:
            config_parm[key] = value

    # Create an experimental case directory
    if config_parm.get("exp_case_name") is None:
        exp_case_name = f'''{config_parm.get("app")}_{config_parm.get("run")}'''
        config_parm.update({'exp_case_name': exp_case_name})
    else:
        exp_case_name = config_parm.get("exp_case_name")

    # Calculate date for the second cycle
    date_first_cycle = config_parm.get("date_first_cycle")
    date_cycle_freq_hr = config_parm.get("date_cycle_freq_hr")
    next_date = datetime.strptime(str(date_first_cycle), "%Y%m%d%H") + timedelta(hours=date_cycle_freq_hr)
    date_second_cycle = next_date.strftime("%Y%m%d%H")
    config_parm["date_second_cycle"] = date_second_cycle

    # Calculate HPC parameter values
    app = config_parm.get("app")
    atm_layout_x = config_parm.get("atm_layout_x")
    atm_layout_y = config_parm.get("atm_layout_y")
    atm_io_layout_x = config_parm.get("atm_io_layout_x")
    atm_io_layout_y = config_parm.get("atm_io_layout_y")    
    lnd_layout_x = config_parm.get("lnd_layout_x")
    lnd_layout_y = config_parm.get("lnd_layout_y")
    max_cores_per_node = config_parm.get("max_cores_per_node")

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
    net = config_parm.get("net")
    run = config_parm.get("run")
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



# Default values of configuration =================================== CHJ =====
def set_default_parm():
# =================================================================== CHJ =====

    default_config = {
        "account": "epic",
        "app": "LND",
        "atm_io_layout_x": 1,
        "atm_io_layout_y": 1,
        "atm_layout_x": 3,
        "atm_layout_y": 8,
        "COMINgdas": "",
        "ccpp_suite": "FV3_GFS_v17_p8",
        "coldstart": "NO",
        "coupler_calendar": 2,
        "date_cycle_freq_hr": 24,
        "date_first_cycle": 200001030000,
        "date_last_cycle": 200001040000,
        "dt_atmos": 900,
        "dt_runseq": 3600,
        "envir": "test",
        "exp_case_name": None,
        "fcsthr": 24,
        "fhrot": 0,
        "ic_data_model": "GFS",
        "imo": 384,
        "jedi_path": "/path/to/jedi/install/dir",
        "jedi_py_ver": "/python/version/used/for/jedi",
        "jmo": 190,
        "lnd_calc_snet": ".true.",
        "lnd_ic_type": "custom",
        "lnd_initial_albedo": 0.25,
        "lnd_layout_x": 1,
        "lnd_layout_y": 2,
        "lnd_output_freq_sec": 21600,
        "machine": "/machine/platform/name",
        "med_coupling_mode": "ufs.nfrac.aoflux",
        "model_ver": "v2.1.0",
        "net": "landda",
        "nprocs_analysis": 6,
        "nprocs_fcst_ic": 36,
        "obsdir": "",
        "obs_ghcn": "YES",
        "output_fh": "1 -1",
        "res": 96,
        "restart_interval": "12 -1",
        "run": "landda",
        "warmstart_dir": "/path/to/wart/start/dir",
        "we2e_test": "NO",
        "write_groups": 1,
        "write_tasks_per_group": 6,
    }

    return default_config



# Machine-specific values of configuration ========================== CHJ =====
def set_machine_parm(machine):
# =================================================================== CHJ =====

    lowercase_machine = machine.lower()
    match lowercase_machine:
        case "hera":
            jedi_path = "/scratch2/NAGAPE/epic/UFS_Land-DA_v2.1/jedi_v7_ic"
            jedi_py_ver = "python3.11"
            warmstart_dir = "/scratch2/NAGAPE/epic/UFS_Land-DA_v2.1/inputs/DATA_RESTART"
            max_cores_per_node = 40
        case "orion":
            jedi_path = "/work/noaa/epic/UFS_Land-DA_v2.1/jedi_v7_ic_orion"
            jedi_py_ver = "python3.10"
            warmstart_dir = "/work/noaa/epic/UFS_Land-DA_v2.1/inputs/DATA_RESTART"
            max_cores_per_node = 40
        case "hercules":
            jedi_path = "/work/noaa/epic/UFS_Land-DA_v2.1/jedi_v7_ic_hercules"
            jedi_py_ver = "python3.10"
            warmstart_dir = "/work/noaa/epic/UFS_Land-DA_v2.1/inputs/DATA_RESTART"
            max_cores_per_node = 80
        case "singularity":
            jedi_path = "SINGULARITY_WORKING_DIR"
            jedi_py_ver = "python3.11"
            warmstart_dir = "SINGULARITY_WORKING_DIR"
            max_cores_per_node = 40
        case _:
            sys.exit(f"FATAL ERROR: this machine/platform '{lowercase_machine}' is NOT supported yet !!!")

    machine_config = {
        "jedi_path": jedi_path,
        "jedi_py_ver": jedi_py_ver,
        "warmstart_dir": warmstart_dir,
        "max_cores_per_node": max_cores_per_node,
    }

    return machine_config



# Parse arguments =================================================== CHJ =====
def parse_args(argv):
# =================================================================== CHJ =====
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Generate case-specific workflow environment.")

    parser.add_argument(
        "-p", "--platform",
        dest="machine",
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
    elif os.path.isdir("/lfs/h2"):
        machine = "wcoss2"
    else:
        sys.exit(f"Machine (platform) is not detected. Please set it with -p argument")

    print(f" Machine (platform) detected: {machine}")

    return machine


# Main call ========================================================= CHJ =====
if __name__=='__main__':
    args = parse_args(sys.argv[1:])
    machine=args.machine
    if machine is None:
        machine = detect_platform()
   
    setup_wflow_env(machine)

