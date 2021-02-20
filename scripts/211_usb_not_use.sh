#!/bin/bash

#==================================================================
# USB 메모리 mount시에 211*.sh를 사용하지 않기 위해 실행
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

nvram set script_usbmount=""
nvram set script_usbumount=""

nvram commit
