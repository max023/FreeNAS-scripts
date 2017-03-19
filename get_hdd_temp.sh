#!/usr/bin/env bash

# Display current temperature of all SMART-enabled drives

# We need a list of the SMART-enabled drives on the system. Choose one of these
# three methods to provide the list. Comment out the two unused sections of code.

# 1. A string constant; just key in the devices you want to report on here:
#drives="da1 da2 da3 da4 da5 da6 da7 da8 ada0"

# 2. A systcl-based technique suggested on the FreeNAS forum:
#drives=$(for drive in $(sysctl -n kern.disks); do \
#if [ "$(/usr/local/sbin/smartctl -i /dev/${drive} | grep "SMART support is: Enabled" | awk '{print $3}')" ]
#then printf ${drive}" "; fi done | awk '{for (i=NF; i!=0 ; i--) print $i }')

# 3. A smartctl-based function:
get_smart_drives()
{
  local gs_smartdrives
  local gs_drives
  local gs_drive
  local gs_smart_flag

  gs_drives=$(/usr/local/sbin/smartctl --scan | grep "dev" | awk '{print $1}' | sed -e 's/\/dev\///')

  gs_smartdrives=""

  for gs_drive in $gs_drives; do
    gs_smart_flag=$(/usr/local/sbin/smartctl -i /dev/"$gs_drive" | grep "SMART support is: Enabled" | awk '{print $4}')
    if [ "$gs_smart_flag" == "Enabled" ]; then
      gs_smartdrives=$gs_smartdrives" "${gs_drive}
    fi
  done

  eval "$1=\$gs_smartdrives"
}

declare drives
get_smart_drives drives

# end of method 3.

for drive in $drives; do
  serial=$(/usr/local/sbin/smartctl -i /dev/${drive} | grep "Serial Number" | awk '{print $3}')
  temp=$(/usr/local/sbin/smartctl -A /dev/${drive} | grep "Temperature_Celsius" | awk '{print $10}')
  brand=$(/usr/local/sbin/smartctl -i /dev/${drive} | grep "Model Family" | awk '{print $3, $4, $5}')
  if [ -z "$brand" ]; then
    brand=$(/usr/local/sbin/smartctl -i /dev/${drive} | grep "Device Model" | awk '{print $3, $4, $5}')
  fi
  printf "%5.5s: %3.3sC %s %s\n" "$drive" "$temp" "$brand" "$serial" 
done
