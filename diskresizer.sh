#!/bin/bash

for path_block in $(/usr/bin/find /sys/class/block -type l -name "[s|v]d[a-z]"); do
  if [[ "$(cat "${path_block}/size")" -ne "$(echo 1 > "${path_block}/device/rescan" && cat "${path_block}/size")" ]]; then
    path_dev="/dev/$(basename "${path_block}")"
    part_num=$(/usr/bin/find /sys/class/block -type l -wholename "${path_block}[0-9]" -printf "%d"|sort -n|head -n 1)
    if [ -n "${part_num}" ]; then
      growpart "${path_dev}" "${part_num}"
      path_dev+=${part_num}
    fi
    if test -f /sbin/pvs && pvs "${path_dev}" > /dev/null 2>&1; then
      logicalvolume=$(pvs "${path_dev}"|sed 1d|awk '{print $2}'|head -n 1|xargs -I {} lvs {}|sed 1d|head -n 1|awk '{print "/dev/"$2"/"$1}')
      /sbin/pvresize "${path_dev}"
      /sbin/lvextend -l +99%FREE "${logicalvolume}"
      /sbin/resize2fs "${logicalvolume}"
    else
      /sbin/resize2fs "${path_dev}"
    fi
   fi
done
