#!/usr/bin/env sh

#Usage: first login to the machine you want to get the details from, then run the script with sudo.

GetBasicDriveProperties() {
    NumberOfDrives=$(lsblk | grep -i disk | wc -l | awk '{print $1}')
    IsRAID=$()
    if [ "$IsRAID" -gt 1 ]; then
        RAIDPath=$(sudo mdadm --detail -scan | awk '{printf $2}') # Should always be /dev/md0, not sure what'll happen if there's ever more than 1 RAID array.
        RAIDType=$() # Hardware vs Software
        RAIDLevel=$(sudo mdadm --detail $"RAIDPath" | grep -i 'Raid Level : ' | awk '{printf $4}' | tail -n 1) # 0, 1, 10, 4, 5, 6
    fi
}
