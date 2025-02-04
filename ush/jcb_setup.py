#!/usr/bin/env python3

import argparse
import sys
import yaml
from jcb import render

# =================================================================== CHJ =====
def jedi_config_yaml(input_yaml_fn, output_yaml_fn, frac_grid):

    try:
        with open(input_yaml_fn, 'r') as f:
            input_yaml_dict = yaml.safe_load(f)
        f.close()
        print(f''' Input YAML file:, {input_yaml_dict} ''')
    except FileNotFoundError:
        print(f''' FATAL ERROR: Input YAML file {input_yaml_file} does not exist! ''')

    jedi_config_dict = render(input_yaml_dict)
    #print(jedi_config_dict)

    if frac_grid.upper() == "NO":
        jedi_config_dict["cost function"]["background"]["state variables"][0] = 'snwdph'
        jedi_config_dict["final"]["increment"]["output"]["state component"]["state variables"][0] = 'snwdph'

    with open(output_yaml_fn, 'w') as f:
        yaml.dump(jedi_config_dict, f, default_flow_style=False, sort_keys=False)
    f.close()


# =================================================================== CHJ =====
def parse_args(argv):
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Create JEDI configuration YAML file.")
    parser.add_argument(
        "-i",
        "--input_yaml_fn",
        dest="input_yaml_fn",
        required=True,
        help="Input YAML file name.",
    )
    parser.add_argument(
        "-o",
        "--output_yaml_fn",
        dest="output_yaml_fn",
        required=True,
        help="Output YAML file name.",
    )
    parser.add_argument(
        "-g",
        "--frac_grid",
        dest="frac_grid",
        required=True,
        help="Flag for fractional grid.",
    )
    return parser.parse_args(argv)


# =================================================================== CHJ =====
if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    jedi_config_yaml(
        input_yaml_fn=args.input_yaml_fn,
        output_yaml_fn=args.output_yaml_fn,
        frac_grid=args.frac_grid,
    )

