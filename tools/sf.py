## =COPYRIGHT=======================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 20, 2018 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================

# Example input command - ibmcloud schematics output --id eu-de.workspace.vpc-vcf-with-architecture-options.c5276a56 --json

import sys
import json
import os
import yaml
import configparser
from optparse import OptionParser

def format_dict(in_dict, key):
    out_dict = dict(in_dict)
    if "type" in out_dict.keys():
        del out_dict["type"]
    if "value" in out_dict.keys():
        out_dict[key] = out_dict["value"]
        del out_dict["value"]
    return out_dict

# Process command line parameters

parser = OptionParser()
parser.add_option("-c", "--config_file", dest="config_file",
                  help="Optional file name of the top ordered fields", metavar="FILE")
parser.add_option("-i", "--in_file", dest="in_file", default='input.json',
                  help="Optional input file name")
parser.add_option("--s", "--skip", action="store_true", dest="skip", default=False,
                  help="Skip all fields except for those in the order file")

(options, args) = parser.parse_args()

# Validate and open files
order = []
out_keys = []
config = configparser.ConfigParser()
if options.config_file:
    if not os.path.isfile(options.config_file) :
        print("Error: config file does not exist" + options.config_file)
        sys.exit()
    config.read(options.config_file)
    order = str.split(config['KEYS_PRINT']['keys'], '\n')
    out_keys = str.split(config['KEYS_OUT']['keys'], '\n')

if not os.path.isfile(options.in_file):
    print("Error: input file does not exist - " + options.in_file)
    sys.exit()
with open(options.in_file) as f:
  input_json = json.load(f)

# Process input json

if isinstance(input_json, list):
    if "output_values" in input_json[0].keys():
        input_json = input_json[0]["output_values"][0]
    else:
        print("Error: Invalid file format")
        sys.exit(1)
else:
    if "output_values" in input_json.keys():
      input_json = input_json["output_values"][0]
    else:
        print("Error: Invalid file format")
        sys.exit(1)

# Print json in yaml format (horriby inefficient)

for ordered_field in order:
    if ordered_field in input_json.keys():
        print_dict = format_dict(input_json[ordered_field], ordered_field)
        print(yaml.dump(print_dict))


if not options.skip:
    for unordered_field in input_json.keys():
        if unordered_field not in order:
            print_dict = format_dict(input_json[unordered_field], unordered_field)
            print(yaml.dump(print_dict))

for out_key in out_keys:
    if out_key in input_json.keys():
        f = open(out_key, 'w+')
        f.write(input_json[out_key]["value"])
        f.close()
        print("Writing key file - " + out_key)