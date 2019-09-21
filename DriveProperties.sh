#!/usr/bin/env sh

#Usage: first login to the machine you want to get the details from, then run the script with sudo.

GetBasicDriveProperties() {
    NumberOfDrives=$(lsblk | grep -i disk | wc -l | awk '{print $1}')

    IsRAID=$()
    if [ "$IsRAID" -gt 1 ]; then
        RAIDPath=$(mdadm --detail -scan | awk '{printf $2}') # Should always be /dev/md0, not sure what'll happen if there's ever more than 1 RAID array.
        NumRAIDDrives=$(mdadm --detail $"RAIDPath" | grep -i 'Raid Devices : ' | awk '{printf $2}')
        RAIDLevel=$(mdadm --detail $"RAIDPath" | grep -i 'Raid Level : ' | awk '{printf $4}') # 0, 1, 10, 4, 5, 6
        RAIDStatus=$(mdadm --detail $"RAIDPath" | grep -i 'State : ' | awk '{printf $2}')
        RAIDType=$() # Hardware vs Software
    fi
}

NumberOfSoftwareRAIDArrays=$(mdadm --detail -scan | grep -i 'ARRAY' | wc -l)
NumberOfHardwareRAIDArrays=$(lspci -vv | grep -i 'raid' | wc -l)
if [ "$NumberOfSoftwareRAIDArrays" -ge 1 ] || [ "$NumberOfHardwareRAIDArrays" -ge 1 ]; then
    # Do the RAID specific stuff here
else
    echo "RAID: NOT PRESENT"
fi
