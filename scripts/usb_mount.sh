#!/bin/bash

#==================================================================
# 211_config.sh 설정 파일 읽어오기 
_CONFIG_FILE="$(dirname "$(readlink -f "$0")")/211_config.sh"
if [ -f "$_CONFIG_FILE" ] ; then
    source "$_CONFIG_FILE"
else
    echo "[$_CONFIG_FILE] FILE NOT EXIST"
fi
#==================================================================



#-----------------------------------------------------------
# 국가코드를 변경
#-----------------------------------------------------------
if [ ${#_TERRITORY_CODE} -gt 0 ] ; then
    _tmp="$(nvram get territory_code)"
    if [ ${#_tmp} -gt 0 ] ; then
        if [ "${_tmp}" != "${_TERRITORY_CODE}" ] ; then
            nvram set territory_code="${_TERRITORY_CODE}"
            nvram commit
        fi
    fi
fi

#-----------------------------------------------------------
# 위치코드를 변경
#-----------------------------------------------------------
if [ ${#_LOCATION_CODE} -gt 0 ] ; then
    _tmp="$(nvram get location_code)"
    if [ ${#_tmp} -gt 0 ] ; then
        if [ "${_tmp}" != "${_LOCATION_CODE}" ] ; then
            nvram set location_code="${_LOCATION_CODE}"
            nvram commit
        fi
    fi
fi


#-------------------------------------------------------------
# 웹설정에서 중국어를 선택해도 한국어로 나오도혹 변경한다. CN -> KR
#-------------------------------------------------------------
if [ "${_TERRITORY_CODE}" = "CN/01" ] || [ "$(nvram get territory_code)" = "CN/01" ] ; then
    mount -o bind   /www/KR.dict /www/CN.dict
fi

#-------------------------------------------------------------
# USB 저장장치를 /jffs로 mount
# jffs bind
#-------------------------------------------------------------
if [ -d "/tmp/mnt/${_USB_STORAGE_LABEL}/jffs_old" ] ; then
    \cp -a /jffs/* "/tmp/mnt/${_USB_STORAGE_LABEL}/jffs_old/"
else
    mkdir -p "/tmp/mnt/${_USB_STORAGE_LABEL}/jffs_old"
    \cp -a /jffs/* "/tmp/mnt/${_USB_STORAGE_LABEL}/jffs_old/"
fi

if [ -d "/tmp/mnt/${_USB_STORAGE_LABEL}/jffs" ] ; then
    mount -o bind "/tmp/mnt/${_USB_STORAGE_LABEL}/jffs" /jffs
else
    mkdir -p "/tmp/mnt/${_USB_STORAGE_LABEL}/jffs"
    \cp -a /jffs/* "/tmp/mnt/${_USB_STORAGE_LABEL}/jffs/"
    mount -o bind "/tmp/mnt/${_USB_STORAGE_LABEL}/jffs" /jffs
fi

#-------------------------------------------------------------
# USB 저장장치를 /opt로 mount
# opt bind
#-------------------------------------------------------------
if [ -d "/tmp/mnt/${_USB_STORAGE_LABEL}/opt" ] ; then
    mount -o bind "/tmp/mnt/${_USB_STORAGE_LABEL}/opt" /opt
else
    mkdir -p "/tmp/mnt/${_USB_STORAGE_LABEL}/opt"
    cd "/tmp/mnt/${_USB_STORAGE_LABEL}/opt"
    mkdir bin doc etc include lib opt sbin share tmp usr scripts
    cd -
    \cp -a /opt/scripts/* "/tmp/mnt/${_USB_STORAGE_LABEL}/opt/scripts/"
    mount -o bind "/tmp/mnt/${_USB_STORAGE_LABEL}/opt" /opt
fi



#-------------------------------------------------------------
# SWAP 설정
#-------------------------------------------------------------
if [ "${_SWAP_USE_FLAG}" = "1" ] ; then
    if [ -f "/tmp/mnt/${_USB_STORAGE_LABEL}/swap" ] ; then
        swapon "/tmp/mnt/${_USB_STORAGE_LABEL}/swap"
    else
        dd if=/dev/zero of="/tmp/mnt/${_USB_STORAGE_LABEL}/swap" bs=1024 count=1024000
        mkswap "/tmp/mnt/${_USB_STORAGE_LABEL}/swap"
        swapon "/tmp/mnt/${_USB_STORAGE_LABEL}/swap"
    fi
fi

#-------------------------------------------------------------
# WEB 재기동
#-------------------------------------------------------------
service restart_httpd

#-------------------------------------------------------------
# profile
#-------------------------------------------------------------
if [ ! -f "/tmp/home/root/.profile" ] ; then
    if [ -f "/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/profile" ] ; then
        ln -s /tmp/mnt/${_USB_STORAGE_LABEL}/scripts/profile /tmp/home/root/.profile
    fi
fi


#-------------------------------------------------------------
# 211_main.sh 스크립트들을 실행
#-------------------------------------------------------------
_PWD="$(dirname "$(readlink -f "$0")")"
export PATH=${PATH}:${_PWD}

#-------------------------------------------------------------
chomd 755 "/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/*.sh /tmp/mnt/${_USB_STORAGE_LABEL}/scripts/c"
"/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/211_main.sh" &



