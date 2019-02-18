#!/bin/bash

# get template vars from specified file (%%%{VARNAME})
# and print to stdout

file=$1

cat "${file}" | grep "%%%{" | sed 's/.*%%%{//;s/}.*//' | sort | uniq
