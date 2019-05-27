#!/usr/bin/env bash
#
#
#  minerboot - A script to set up and run NVIDIA miner(s) on boot
#
#  Copyright (C) 2019 LeshaCat
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#


logit "Updating system, please wait..."
UPDATERES=$(apt update 2>&1)
REMOVERES=$(apt autoremove -y 2>&1)
UPGRADERES=$(apt upgrade -y 2>&1 ; apt full-upgrade -y 2>&1 ;)
REMOVERES="${REMOVERES} "$(apt autoremove -y 2>&1)

#   CHECK IF NVIDIA DRIVER WAS UPDATED AND REBOOT
logit "Checking NVIDIA updates..."
NUMNVIDIACHGS=$(echo ${UPGRADERES} | grep "nvidia" | wc -l)

if [ $NUMNVIDIACHGS -gt 0 ] ; then
    logit "Counted ${NUMNVIDIACHGS} changes to NVIDIA packages :("
    
    if [ "$FORCE_REBOOT_AFTER_NVIDIA_UPDATE" = true ] ; then
        logit "FORCING REBOOT IN 5 SECONDS!"
        sleep 5
        /sbin/reboot
    if
else
    logit "No changes to NVIDIA packages :)"
fi

logit "Counting GPU's..."
NUMGPUS=$(nvidia-smi -L | grep "UUID:" | wc -l)
logit "Counted ${NUMGPUS} GPU's"

for (( c=0; c<=($NUMGPUS-1); c++ ))
do
    
    logit "Resetting GPU #${c}"
    
    nvidia-smi -i ${c} -r #2>&1 >/dev/null
    nvidia-smi -i ${c} -rgc #2>&1 >/dev/null
    nvidia-smi -i ${c} -rac #2>&1 >/dev/null
    
    logit "Enabling NVIDIA Persistance Mode..."
    nvidia-smi -i ${c} -pm 1 #2>&1 >/dev/null
    
    logit "Enabling other options..."
    nvidia-smi -i ${c} -cc 1 #2>&1 >/dev/null
    nvidia-smi -i ${c} -acp 0 #2>&1 >/dev/null
    nvidia-smi -i ${c} --auto-boost-permission=0 #2>&1 >/dev/null
    nvidia-smi -i ${c} --auto-boost-default=1 #2>&1 >/dev/null

    
    logit "Getting info for GPU #${c}"  
    
    QRES=$(nvidia-smi -i ${c} -q)  
    CRES=$(echo "$QRES" | grep "Max Clocks" -A 4) 
    
    QRES=$(echo "$QRES" | grep "Max Power Limit") 
  
    # GET MAX POWER LEVEL  
  
    IFS=':' # space is set as delimiter
    read -ra ADDR <<< "$QRES"
    MAX_POWER=$(echo "${ADDR[1]}" | xargs)
    
    IFS='.' # space is set as delimiter
    read -ra ADDR <<< "$MAX_POWER"
    MAX_POWER=$(echo "${ADDR[0]}" | xargs)
    
    logit "GPU #${c} Setting Max Power: ${MAX_POWER}"   
    nvidia-smi -i ${c} -pl ${MAX_POWER} #2>&1 >/dev/null
    
    # GET CLOCK SPEEDS   
     
    MAX_MEMCLK=$(echo "$CRES" | grep "Memory")
    
    IFS=':' # space is set as delimiter
    read -ra ADDR <<< "$MAX_MEMCLK"
    MAX_MEMCLK=$(echo "${ADDR[1]}" | xargs)  
    
    IFS=' ' # space is set as delimiter
    read -ra ADDR <<< "$MAX_MEMCLK"
    MAX_MEMCLK=$(echo "${ADDR[0]}" | xargs)  
    
    logit "GPU #${c} Setting Max Memory Clock Speed: ${MAX_MEMCLK} Mhz"  
     
    MAX_GFXCLK=$(echo "$CRES" | grep "Graphics")
    
    IFS=':' # space is set as delimiter
    read -ra ADDR <<< "$MAX_GFXCLK"
    MAX_GFXCLK=$(echo "${ADDR[1]}" | xargs)  
    
    IFS=' ' # space is set as delimiter
    read -ra ADDR <<< "$MAX_GFXCLK"
    MAX_GFXCLK=$(echo "${ADDR[0]}" | xargs)  
    
    logit "GPU #${c} Setting Max Graphics Clock Speed: ${MAX_GFXCLK} Mhz"  
    
    nvidia-smi -i ${c} -ac ${MAX_MEMCLK},${MAX_GFXCLK} #2>&1 >/dev/null
  
done






