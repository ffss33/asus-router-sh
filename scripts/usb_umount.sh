#!/bin/bash

#-----------------------------------------------------------
# USB unmount 스크립트
#-----------------------------------------------------------


#==================================================================
# 211_config.sh 설정 파일 읽어오기
_CONFIG_FILE="$(dirname "$(readlink -f "$0")")/211_config.sh"
if [ -f "$_CONFIG_FILE" ] ; then
    source "$_CONFIG_FILE"
else
    echo "[$_CONFIG_FILE] FILE NOT EXIST"
fi
#==================================================================


#------------------------------------------------------
#swap off
#------------------------------------------------------
_swaptotal=$(free | grep Swap | awk '{printf("%d", $2)}')
if [ "${_swaptotal}" -gt 0 ] ; then
    swapoff "/tmp/mnt/${_USB_STORAGE_LABEL}/swap"
fi


#------------------------------------------------------
#umount bind
#------------------------------------------------------
_dev_sdx="$(mount | grep "/tmp/mnt/${_USB_STORAGE_LABEL}" | awk '{print $1}')"
_bind_list="$(mount | grep "${_dev_sdx}" | awk '{print $3}')"
if [ ${#_bind_list} -gt 2 ] ; then
    for _bind in $_bind_list
    do
        if [ "${_bind}" != "/tmp/mnt/${_USB_STORAGE_LABEL}" ] ; then
            #echo "$_bind"
            umount "${_bind}"
        fi
    done
fi
