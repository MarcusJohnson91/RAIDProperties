#!/usr/bin/env sh

#Usage: first login to the machine you want to get the details from, then run the script with sudo.

GetHardwareRAIDProperties() {
    #Use LSPCI
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
