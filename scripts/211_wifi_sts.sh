#!/bin/bash





############################################################
# 가족 WIFI 연결 상태를 텔레그램으로 전송
############################################################
sleep 100


#==================================================================
# 211_config.sh 설정 파일 읽어오기
_CONFIG_FILE="$(dirname "$(readlink -f "$0")")/211_config.sh"
if [ -f "$_CONFIG_FILE" ] ; then
    source "$_CONFIG_FILE"
else
    echo "[$_CONFIG_FILE] FILE NOT EXIST"
    exit 1
fi
#==================================================================

#========================================================
# TMP 디렉토리 생성
[ ! -d "$_TMP_WIFI_STS_DIR" ] && mkdir -p "$_TMP_WIFI_STS_DIR"


#========================================================
# 환경 설정
#========================================================
# 일부는 211_config.sh 로 옮겼음

# 검색 파일
_SEARCH_FILE="/jffs/nmp_cl_json.js"
_CLIENT_FILE="/tmp/clientlist.json"



#######################################################################
# WIFI 연결상태 체크 후 상태가 변경된 경우 텔레그램으로 전송
# 인자                   1                   2           3                4
# FUNC_CHECK_WIFI_CONN "${_MAC_OR_DNAME1}" "${_NAME1}" "${_CONN_FILE1}" "${_WIFI_CONN_SEND1}"
#######################################################################
FUNC_CHECK_WIFI_CONN(){
    #---------------------------------------------------------------
    #1 연결상태 확인 후 텔레그램 전송
    #---------------------------------------------------------------
    _srch=$(echo "${_WIFI_SEARCH_LIST}" | sed "s/}/\\n/g" | grep "${1}")
    #echo "_srch = ${_srch}"

    _conn="0"

    for _line  in $_srch
    do
        #echo "_line = ${_line}"
        _mac=$(echo "${_line}" | sed "s/.*\"mac\":\"//g;s/\".*//g")
        #echo "_mac = ${_mac}"

        if [ "${#_mac}" -eq 17 ] ; then
            _sts=$(echo "${_WIFI_CLIENT_LIST}" | grep -c "${_mac}")
            if [ "${_sts}" != "0" ] ; then
                _conn="1"
                break
            fi
        fi
    done

    #echo "_conn = ${_conn}"

    if [ -f "${3}" ] ; then
        _conn_pre=$(cat "${3}")
    else
        _conn_pre="2"
    fi

    #-----------------------------
    if [ "${_conn_pre}" != "${_conn}" ] ; then
        echo "${_conn}" > "${3}"
        #-----------------------------
        if [ ${_conn} = 0 ] ; then
            _send_msg="${2}${_OUT_STR}"
        else
            _send_msg="${2}${_IN_STR}"
        fi

        _ndx=0
        _sends=$(echo $4 | tr "," "\n")
        for _snd_flag in $_sends
        do
            _ndx=$((_ndx + 1))
            #echo "$2, $4, _ndx = $_ndx, _snd_flag = $_snd_flag"
            if [ ${_snd_flag} = 1 ] ; then
               if [ ${_ndx} = 1 ] && [ "${_TOKEN1}" != "" ] ; then
                    FUNC_SEND_TELEGRAM_BOT "${_TOKEN1}" "${_CHATID1}" "${_send_msg}"
               elif [ ${_ndx} = 2 ] && [ "${_TOKEN2}" != "" ] ; then
                    FUNC_SEND_TELEGRAM_BOT "${_TOKEN2}" "${_CHATID2}" "${_send_msg}"
               elif [ ${_ndx} = 3 ] && [ "${_TOKEN3}" != "" ] ; then
                    FUNC_SEND_TELEGRAM_BOT "${_TOKEN3}" "${_CHATID3}" "${_send_msg}"
               elif [ ${_ndx} = 4 ] && [ "${_TOKEN4}" != "" ] ; then
                    FUNC_SEND_TELEGRAM_BOT "${_TOKEN4}" "${_CHATID4}" "${_send_msg}"
               elif [ ${_ndx} = 5 ] && [ "${_TOKEN5}" != "" ] ; then
                    FUNC_SEND_TELEGRAM_BOT "${_TOKEN5}" "${_CHATID5}" "${_send_msg}"
               elif [ ${_ndx} = 6 ] && [ "${_TOKEN6}" != "" ] ; then
                    FUNC_SEND_TELEGRAM_BOT "${_TOKEN6}" "${_CHATID6}" "${_send_msg}"
               elif [ ${_ndx} = 7 ] && [ "${_TOKEN7}" != "" ] ; then
                    FUNC_SEND_TELEGRAM_BOT "${_TOKEN7}" "${_CHATID7}" "${_send_msg}"
               elif [ ${_ndx} = 8 ] && [ "${_TOKEN8}" != "" ] ; then
                    FUNC_SEND_TELEGRAM_BOT "${_TOKEN8}" "${_CHATID8}" "${_send_msg}"
               elif [ ${_ndx} = 9 ] && [ "${_TOKEN9}" != "" ] ; then
                    FUNC_SEND_TELEGRAM_BOT "${_TOKEN9}" "${_CHATID9}" "${_send_msg}"
               fi
            fi
        done
    fi
}
#######################################################################


#######################################################################
# MAIN
# 주기적으로 연결상태를 체크하여 변경시 텔레그램으로 전송
#######################################################################
while true
do
    source "$_CONFIG_FILE"

    # ASUS 공유기는 아래 파일에 연결상태를 주기적으로 저장하므로 이 파일을 사용하여 체크한다.
    _WIFI_SEARCH_LIST=$(cat "${_SEARCH_FILE}")
    _WIFI_CLIENT_LIST=$(cat "${_CLIENT_FILE}")

    #echo "_WIFI_SEARCH_LIST = ${_WIFI_SEARCH_LIST}"
    #echo "_WIFI_CLIENT_LIST = ${_WIFI_CLIENT_LIST}"

    #---------------------------------------------------------------
    #1 연결상태 확인 후 텔레그램 전송
    #---------------------------------------------------------------
    if [ "${_MAC_OR_DNAME1}" != "" ] ; then
        FUNC_CHECK_WIFI_CONN "${_MAC_OR_DNAME1}"  "${_NAME1}" "${_CONN_FILE1}" "${_WIFI_CONN_SEND1}" 
        sleep 1
    fi

    if [ "${_MAC_OR_DNAME2}" != "" ] ; then
        FUNC_CHECK_WIFI_CONN "${_MAC_OR_DNAME2}"  "${_NAME2}" "${_CONN_FILE2}" "${_WIFI_CONN_SEND2}" 
        sleep 1
    fi

    if [ "${_MAC_OR_DNAME3}" != "" ] ; then
        FUNC_CHECK_WIFI_CONN "${_MAC_OR_DNAME3}"  "${_NAME3}" "${_CONN_FILE3}" "${_WIFI_CONN_SEND3}" 
        sleep 1
    fi

    if [ "${_MAC_OR_DNAME4}" != "" ] ; then
        FUNC_CHECK_WIFI_CONN "${_MAC_OR_DNAME4}"  "${_NAME4}" "${_CONN_FILE4}" "${_WIFI_CONN_SEND4}" 
        sleep 1
    fi

    if [ "${_MAC_OR_DNAME5}" != "" ] ; then
        FUNC_CHECK_WIFI_CONN "${_MAC_OR_DNAME5}"  "${_NAME5}" "${_CONN_FILE5}" "${_WIFI_CONN_SEND5}" 
        sleep 1
    fi

    if [ "${_MAC_OR_DNAME6}" != "" ] ; then
        FUNC_CHECK_WIFI_CONN "${_MAC_OR_DNAME6}"  "${_NAME6}" "${_CONN_FILE6}" "${_WIFI_CONN_SEND6}" 
        sleep 1
    fi

    if [ "${_MAC_OR_DNAME7}" != "" ] ; then
        FUNC_CHECK_WIFI_CONN "${_MAC_OR_DNAME7}"  "${_NAME7}" "${_CONN_FILE7}" "${_WIFI_CONN_SEND7}" 
        sleep 1
    fi

    if [ "${_MAC_OR_DNAME8}" != "" ] ; then
        FUNC_CHECK_WIFI_CONN "${_MAC_OR_DNAME8}"  "${_NAME8}" "${_CONN_FILE8}" "${_WIFI_CONN_SEND8}" 
        sleep 1
    fi

    if [ "${_MAC_OR_DNAME9}" != "" ] ; then
        FUNC_CHECK_WIFI_CONN "${_MAC_OR_DNAME9}"  "${_NAME9}" "${_CONN_FILE9}" "${_WIFI_CONN_SEND9}" 
        sleep 1
    fi

done
