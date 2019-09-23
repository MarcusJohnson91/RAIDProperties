#!/usr/bin/env sh

# Author: Marcus Johnson
# Copyright: 2019+

#Usage: first login to the machine you want to get the details from, then run the script with sudo.

GetHardwareRAIDProperties() {
    #Use LSPCI
	# 01:00.0 RAID bus controller: LSI Logic / Symbios Logic MegaRAID SAS-3 3008 [Fury] (rev 02)
	#
	RAIDManufacturer=$(lspci | grep -i 'raid' | awk '{print $5}')
	RAIDTyoe=$() # 0, 1, etc

# LSI = storcli
# 3Ware = tw_cli
# Adaptec = smartctl
}

GetSoftwareRAIDProperties() {
    #Use DMADM
}

GetRAIDArrayProperties() {
    RAIDPath=$(mdadm --detail -scan | awk '{printf $2}') # Should always be /dev/md0, not sure what'll happen if there's ever more than 1 RAID array.
    NumRAIDDrives=$(mdadm --detail $"RAIDPath" | grep -i 'Raid Devices : ' | awk '{printf $2}')
    RAIDLevel=$(mdadm --detail $"RAIDPath" | grep -i 'Raid Level : ' | awk '{printf $4}') # 0, 1, 10, 4, 5, 6
    RAIDStatus=$(mdadm --detail $"RAIDPath" | grep -i 'State : ' | awk '{printf $2}')
    RAIDType=$() # Hardware vs Software
}

GetBasicDriveProperties() {
    NumberOfDrives=$(lsblk | grep -i disk | wc -l | awk '{print $1}')
    for Drive in $NumberOfDrives
    do
    DriveSerials[$Drive]=$(lshw -class disk | grep 'serial:' | awk '{printf $2}')
    done
}

# Check for LSPCI, DMADM, and if they're missing check for dnf and apt so we can auto-install

LSPCIPath=$(which lspci)
DMADMPath=$(which dmadm)

if [ $(tail -n 1 $LSPCIPath) -eq ")" ] # Need to install lspci
	DNFPath=$(which dnf)
	APTPath=$(which apt)
	if [ $(tail -n 1 $DNFPath) -ne ")" ] # DNF is available
		dnf install lspci
	elif [ $(tail -n 1 $DNFPath) -ne ")" ] # APT is available, use it if we need to
		apt update
		apt install lspci
	fi
fi

if [ $(tail -n 1 $DMADMPath) -eq ")" ]
	DNFPath=$(which dnf)
	APTPath=$(which apt)
	if [ $(tail -n 1 $DNFPath) -ne ")" ] # DNF is available
		dnf install dmadm
	elif [ $(tail -n 1 $DNFPath) -ne ")" ] # APT is available, use it if we need to
		apt update
		apt install dmadm
	fi
fi

NumberOfSoftwareRAIDArrays=$(mdadm --detail -scan | grep -i 'ARRAY' | wc -l)
NumberOfHardwareRAIDArrays=$(lspci -vv | grep -i 'raid' | wc -l)
NumberOfRAIDArrays=$($NumberOfSoftwareRAIDArrays + $NumberOfHardwareRAIDArrays)
if [ "$NumberOfSoftwareRAIDArrays" -ge 1 ]; then
    GetSoftwareRAIDProperties
elif [ "$NumberOfHardwareRAIDArrays" -ge 1 ]; then
    # Do the RAID specific stuff here
    # Then call the BasicDriveProperties function
    GetHardwareRAIDProperties
    GetBasicDriveProperties
else
    echo "RAID: NOT PRESENT"
    # Call the BasicDriveProperties function
    GetBasicDriveProperties
fi
