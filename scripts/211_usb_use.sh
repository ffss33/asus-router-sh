#!/bin/bash

#==================================================================
# USB 메모리와 211*.sh 사용시 최초 한번만 실행.
# USB 메모리 mount시에 211*.sh를 실행하기 위한 설정
#==================================================================

#==================================================================
# 211_config.sh 설정 파일 읽어오기
_CONFIG_FILE="$(dirname "$(readlink -f "$0")")/211_config.sh"
if [ -f "$_CONFIG_FILE" ] ; then
    source "$_CONFIG_FILE"
else
    echo "[$_CONFIG_FILE] FILE NOT EXIST"
fi
#==================================================================

echo "nvram set script_usbmount=/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/usb_mount.sh"
echo "nvram set script_usbumount=/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/usb_umount.sh"
nvram set script_usbmount="/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/usb_mount.sh"
nvram set script_usbumount="/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/usb_umount.sh"

nvram set dns_probe_content="127.0.0.1"
nvram set dns_probe_host=""
nvram set ping_target="www.google.com"

nvram set http_autologout=10

nvram commit

service restart_httpd
