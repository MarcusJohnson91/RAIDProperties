#!/usr/bin/env sh

# Author: Marcus Johnson
# Copyright: 2019+

#Usage: first login to the machine you want to get the details from, then run the script with sudo.

GetHardwareRAIDProperties() {
	Manufacturer=$1 # Argument #1
    	#Use LSPCI
	# 01:00.0 RAID bus controller: LSI Logic / Symbios Logic MegaRAID SAS-3 3008 [Fury] (rev 02)
	# HARDWARE RAID can have multiple "ports", an 8i raid card has 2 ports, with up to 4 drives for each port for a total of 8 drives attached to each raid card. 4i is the same but with 	1 port, 4 drives per port, 4 drives total.
	RAIDPath=$()
	RAIDManufacturer=$(lspci | grep -i 'raid' | awk '{print $5}')
	RAIDTyoe=$() # 0, 1, etc

	if [ $RAIDManufacturer -eq "LSI" ]
		#STORCLI
	elif [ $RAIDManufacturer -eq "Adaptec" ]
		# tw_cli
	fi

# LSI = storcli
# 3Ware = tw_cli
# Adaptec = smartctl
# Additional commands: lsblk, lspci

#itxtemp1 = SoftwareRAID
#itxtemp2 = SoftwareRAID
#itxtemp3 = HardwareRAID, LSI
#itxtemp4 = HardwareRAID, LSI

# run both lsblk and lspci, is lsblk comes back with a result from RAID, it's software RAID, if lspci comes back with a result for RAID, it's hardware RAID

}

GetSoftwareRAIDProperties() {
    #Use MDADM
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
LSBLKPath=$(which lsblk)
MDADMPath=$(which mdadm)

if [ $(tail -n 1 $LSPCIPath) -eq ")" ] # Need to install lspci
	DNFPath=$(which dnf)
	APTPath=$(which apt)
	YUMPath=$(which yum)
	if [ $(tail -n 1 $DNFPath) -ne ")" ] # DNF is available
		dnf install lspci
	elif [ $(tail -n 1 $DNFPath) -ne ")" ] # APT is available, use it if we need to
		apt update
		apt install lspci
	elif [ $(tail -n 1 $YUMPath) -ne ")" ] # Use YUM as a last resort
		yum install lspci
	fi
fi

if [ $(tail -n 1 $LSBLKPath) -eq ")" ] # Need to install LSBLKPath
	DNFPath=$(which dnf)
	APTPath=$(which apt)
	YUMPath=$(which yum)
	if [ $(tail -n 1 $DNFPath) -ne ")" ] # DNF is available
		dnf install lsblk
	elif [ $(tail -n 1 $DNFPath) -ne ")" ] # APT is available, use it if we need to
		apt update
		apt install lsblk
	elif [ $(tail -n 1 $YUMPath) -ne ")" ] # Use YUM as a last resort
		yum install lsblk
	fi
fi

if [ $(tail -n 1 $MDADMPath) -eq ")" ]
	DNFPath=$(which dnf)
	APTPath=$(which apt)
	YUMPath=$(which yum)
	if [ $(tail -n 1 $DNFPath) -ne ")" ] # DNF is available
		dnf install mdadm
	elif [ $(tail -n 1 $DNFPath) -ne ")" ] # APT is available, use it if we need to
		apt update
		apt install mdadm
	elif [ $(tail -n 1 $YUMPath) -ne ")" ] # Use YUM as a last resort
		yum install mdadm
	fi
fiping

# there may also be multiple RAID cards, we need to pul in all of that information.
# So, the heirarchy of information we need:
# 1: Number of RAID cards
# 2: Number of ports on each RAID card.
# 3: Number of drives attached to each RAID port
# 4: RAID card manufacturer, model, hardware revision, and firmware info (revision and firmwre just to be safe/future expansion)
# Partitioning info for all RAID arrays
 
NumberOfHardwareRAIDCards=$(lspci -vv | grep -i 'RAID bus controller' | wc -l)
if [ $NumberOfHardwareRAIDCards -ge 1 ]; then
	if [ $(lspci -knn | grep 'RAID bus controller' | awk '{print $8}') -eq "LSI" ]; then
		GetHardwareRAIDProperties LSI
	elif [ $(lspci -knn | grep 'RAID bus controller' | awk '{print $5}') -eq "Adaptec" ]; then
		GetHardwareRAIDProperties Adaptec
	else
		echo "Unknown RAID card manufacturer!"
		exit
	fi
else
	if [ $(mdadm --detail -scan | grep -i 'ARRAY' | wc -l) -ge 1 ]; then
		# Software RAID found
		GetSoftwareRAIDProperties
	fi
	
fi




NumberOfSoftwareRAIDArrays=$(mdadm --detail -scan | grep -i 'ARRAY' | wc -l)
NumberOfHardwareRAIDPorts=0
NumberOfHardwareRAIDArrays=$(lspci -vv | grep -i 'raid')
NumberOfRAIDArrays=$($NumberOfSoftwareRAIDArrays + $NumberOfHardwareRAIDArrays)
if [ "$NumberOfSoftwareRAIDArrays" -ge 1 ]; then
    GetSoftwareRAIDProperties
elif [ "$NumberOfHardwareRAIDArrays" -ge 1 ]; then
    # Do the RAID specific stuff here
    # Then call the BasicDriveProperties function
    GetBasicDriveProperties
    GetHardwareRAIDProperties
    
else
    echo "RAID: NOT PRESENT"
    # Call the BasicDriveProperties function
    GetBasicDriveProperties
fi
