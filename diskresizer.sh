#!/bin/bash

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
for path_block in $(/usr/bin/find /sys/class/block -type l -name "[s|v]d[a-z]"); do
  device_name=$(basename "${path_block}")
  device_size="/tmp/${device_name}_size"
  device_path="/dev/${device_name}"
  touch "${device_size}"
  if [[ "$(cat "${device_size}")" -ne "$(echo 1 > "${path_block}/device/rescan" && cat "${path_block}/size")" ]]; then
    part_num=$(/usr/bin/find /sys/class/block -type l -wholename "${path_block}[0-9]" -printf "%d"|sort -n|head -n 1)
    if [ -n "${part_num}" ]; then
      growpart "${device_path}" "${part_num}"
      device_path+=${part_num}
    fi
    if test -f /sbin/pvs && pvs "${device_path}" > /dev/null 2>&1; then
      logicalvolume=$(pvs "${device_path}"|sed 1d|awk '{print $2}'|head -n 1|xargs -I {} lvs {}|sed 1d|head -n 1|awk '{print "/dev/"$2"/"$1}')
      /sbin/pvresize "${device_path}"
      /sbin/lvextend -l +99%FREE "${logicalvolume}"
      device_path="${logicalvolume}"
    fi
    /sbin/resize2fs "${device_path}"
    cat "${path_block}/size" > "${device_size}"
  fi
done
