#!/bin/bash

#==================================================================
# *.sh 가 종료되면 자동으로 실행, *.sh 의 내용이 변경되면 자동 재실행
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


#-----------------------------------------------------------
#현재 실행중인 211_main.sh 파일의 정보를 읽어온다.
#-----------------------------------------------------------
_FILE_211_main="/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/211_main.sh"
_LSLC_211_main=$(ls -lc "${_FILE_211_main}")



#-------------------------------------------------------------
# 스크립트들을 실행
#-------------------------------------------------------------
while true
do
    #-----------------------------------------------------------
    source "$_CONFIG_FILE"

    #-------------------------------------------------------------
    #211_main.sh 파일은 변경시 새로 실행하고, exit한다.
    #-------------------------------------------------------------
    if [ -f "${_FILE_211_main}" ] ; then
        _lslc=$(ls -lc "${_FILE_211_main}")
        if [ "${_lslc}" != "${_LSLC_211_main}" ] ; then
            while true
            do
                _lslc=$(ls -lc "${_FILE_211_main}")
                if [ "${_lslc}" = "${_LSLC_211_main}" ] ; then
                    "${_FILE_211_main}" &
                    exit 0
                fi
                _LSLC_211_main="${_lslc}"
                sleep 5
            done
        fi
    fi
    sleep 1


    #-------------------------------------------------------------
    # 211_check.sh
    #-------------------------------------------------------------
    _file="/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/211_check.sh"
    _pidof=$(pidof 211_check.sh)
    if [ -f "${_file}" ] ; then
        _lslc=$(ls -lc "${_file}")
        if [ "${_pidof}" ] ; then
            if [ "${_lslc}" != "${_lslc_211_check}" ] ; then
                kill -9 "${_pidof}"
            fi
        else
            if [ "${_lslc}" = "${_lslc_211_check}" ] ; then
                "${_file}" &
            fi
            _lslc_211_check="${_lslc}"
        fi
    else
        if [ "${_pidof}" ] ; then
            kill -9 "${_pidof}"
        fi
    fi
    sleep 1


    #-------------------------------------------------------------
    # 211_wifi_sts.sh
    #-------------------------------------------------------------
    if [ "${_TELEGRAM_USE_FLAG}" = "1" ] ; then
        if [ "${_WIFI_STS_USE_FLAG}" = "1" ] ; then

            _file="/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/211_wifi_sts.sh"
            _pidof=$(pidof 211_wifi_sts.sh)
            if [ -f "${_file}" ] ; then
                _lslc=$(ls -lc "${_file}")
                if [ "${_pidof}" ] ; then
                    if [ "${_lslc}" != "${_lslc_211_wifi_sts}" ] ; then
                        kill -9 "${_pidof}"
                    fi
                else
                    if [ "${_lslc}" = "${_lslc_211_wifi_sts}" ] ; then
                        "${_file}" &
                    fi
                    _lslc_211_wifi_sts="${_lslc}"
                fi
            else
                if [ "${_pidof}" ] ; then
                    kill -9 "${_pidof}"
                fi
            fi
        else
            _pidof=$(pidof 211_wifi_sts.sh)
            if [ "${_pidof}" ] ; then
                kill -9 "${_pidof}"
            fi
        fi
    else
        _pidof=$(pidof 211_wifi_sts.sh)
        if [ "${_pidof}" ] ; then
            kill -9 "${_pidof}"
        fi
    fi
    sleep 1


    #-------------------------------------------------------------
    # 211_tele_rcv.sh
    #-------------------------------------------------------------
    if [ "${_TELEGRAM_USE_FLAG}" = "1" ] ; then

		_file="/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/211_tele_rcv.sh"
		_pidof=$(pidof 211_tele_rcv.sh)
		if [ -f "${_file}" ] ; then
			_lslc=$(ls -lc "${_file}")
			if [ "${_pidof}" ] ; then
				if [ "${_lslc}" != "${_lslc_211_tele_rcv}" ] ; then
					kill -9 "${_pidof}"
				fi
			else
				if [ "${_lslc}" = "${_lslc_211_tele_rcv}" ] ; then
					"${_file}" &
				fi
				_lslc_211_tele_rcv="${_lslc}"
			fi
		else
			if [ "${_pidof}" ] ; then
				kill -9 "${_pidof}"
			fi
		fi
    else
        _pidof=$(pidof 211_tele_rcv.sh)
        if [ "${_pidof}" ] ; then
            kill -9 "${_pidof}"
        fi
    fi
    sleep 1



    #-------------------------------------------------------------
    # 211_zone_ip.sh
    #-------------------------------------------------------------
    if [ "${_ZONE_USE_FLAG}" = "1" ] ; then

        _file="/tmp/mnt/${_USB_STORAGE_LABEL}/scripts/211_zone_ip.sh"
        _pidof=$(pidof 211_zone_ip.sh)
        if [ -f "${_file}" ] ; then
            _lslc=$(ls -lc "${_file}")
            if [ "${_pidof}" ] ; then
                if [ "${_lslc}" != "${_lslc_211_zone_ip}" ] ; then
                    kill -9 "${_pidof}"
                fi
            else
                if [ "${_lslc}" = "${_lslc_211_zone_ip}" ] ; then
                    "${_file}" &
                fi
                _lslc_211_zone_ip="${_lslc}"
            fi
        else
            if [ "${_pidof}" ] ; then
                kill -9 "${_pidof}"
            fi
        fi
    else
        _pidof=$(pidof 211_zone_ip.sh)
        if [ "${_pidof}" ] ; then
            kill -9 "${_pidof}"
        fi
    fi
    sleep 1


#-------------------------------------------------------------
done

