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
parser.add_option("-o", "--order_file", dest="order_file",
                  help="Optional file name of the top ordered fields", metavar="FILE")

parser.add_option("-f", "--options", dest="in_file", default='input.json',
                  help="Optional input file name")
parser.add_option("--s", "--skip", action="store_true", dest="skip", default=False,
                  help="Skip all fields except for those in the order file")

(options, args) = parser.parse_args()

# Validate and open files
order = []
if options.order_file:
    if not os.path.isfile(options.order_file) :
        print("Error: order file does not exist" + options.order_file)
        sys.exit()
    with open(options.order_file) as f:
        order_in = f.readlines()
        order = [x.strip() for x in order_in]
        print("Using field order if field exists - " + str(order))

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