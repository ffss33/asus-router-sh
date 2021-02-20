#!/bin/bash

#==================================================================
# 국가별 IP 대역을 읽어와 iptables를 사용하여 차단
#==================================================================
sleep 25


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

#==================================================================
# 임시 디렉토리 생성
#==================================================================
_PWD="$(dirname "$(readlink -f "$0")")"      
_TMP_DIR="$(dirname "$(readlink -f "$0")")/tmp_zone_ip"      
[ ! -d "$_TMP_DIR" ] && mkdir -p "$_TMP_DIR"


#==================================================================
# 환경 설정
#==================================================================
# 211_config.sh 로 옮김
#_ZONE_LIST="cn ru af au br pk sa sc tr tw ua vn jp"
#_ZONE_LIST="cn ru af jp"
#_ZONE_IP_STOP_FILE="/tmp/z"

_ACCEPT_CFG_FILE="${_PWD}/211_zone_ip.allow"

_ORG_FILE="${_TMP_DIR}/org"         #iptables-save 저장한 원본 파일
_NEW_FILE="${_TMP_DIR}/new"         #최종 iptables-restore 할 파일
_BKUP_FILE="${_TMP_DIR}/final"      #국가 차단 설정 후에 iptables-save 한 파일

_ZONE_ACCEPT_FILE="${_TMP_DIR}/accept"                 #iptables-save 형식으로 저장한 파일
_ZONE_ACCEPT_FILE_TMP="${_TMP_DIR}/accept.tmp"         #임시 파일
_ZONE_ACCEPT_LOG_FILE="${_TMP_DIR}/accept.log"         #iptables-save 형식으로 저장한 파일
_ZONE_ACCEPT_LOG_FILE_TMP="${_TMP_DIR}/accept.log.tmp" #임시 파일

_ZONE_DROP_FILE="${_TMP_DIR}/drop"                 #iptables-save 형식으로 저장한 파일
_ZONE_DROP_FILE_TMP="${_TMP_DIR}/drop.tmp"         #임시 파일
_ZONE_DROP_LOG_FILE="${_TMP_DIR}/drop.log"         #iptables-save 형식으로 저장한 파일
_ZONE_DROP_LOG_FILE_TMP="${_TMP_DIR}/drop.log.tmp" #임시 파일

_CHAIN_ACCEPT_LOG="ZONE_ACCEPT_LOG"          #iptables 에서 ACCEPT_LOG 할 chain 이름
_CHAIN_ACCEPT="ZONE_ACCEPT"                  #iptables 에서 ACCEPT 할 chain 이름
_CHAIN_DROP_LOG="ZONE_DROP_LOG"              #iptables 에서 DROP_LOG 할 chain 이름
_CHAIN_DROP="ZONE_DROP"                      #iptables 에서 DROP 할 chain 이름

_NEW_CHAIN_ACCEPT_LOG_RULE=":${_CHAIN_ACCEPT_LOG} - [0:0]"    #_ORG_FILE을 _NEW_FILE로 만들 때 사용
_NEW_CHAIN_ACCEPT_RULE=":${_CHAIN_ACCEPT} - [0:0]"            #_ORG_FILE을 _NEW_FILE로 만들 때 사용
_NEW_CHAIN_DROP_LOG_RULE=":${_CHAIN_DROP_LOG} - [0:0]"        #_ORG_FILE을 _NEW_FILE로 만들 때 사용
_NEW_CHAIN_DROP_RULE=":${_CHAIN_DROP} - [0:0]"                #_ORG_FILE을 _NEW_FILE로 만들 때 사용

#현재의 LOG 설정값
_CUR_ZONE_DROP_LOG_USE_FLAG="$_ZONE_DROP_LOG_USE_FLAG"
_CUR_ZONE_ACCEPT_LOG_USE_FLAG="$_ZONE_ACCEPT_LOG_USE_FLAG"

_ZONE_DROP_FILE_FAIL_FLAG=0
#==================================================================


#######################################################################
# FUNCTION
# 국가별 IP대역을 다운로드한 후에 iptables-save 형식으로 저장한 
# _ZONE_DROP_FILE, _ZONE_DROP_LOG_FILE 파일이 생성됨
#######################################################################
FUNC_MAKE_ZONE_DROP_FILE()
{
    FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "ZONE Drop File Make Start"

    #-------------------------------------------------------------
    #이전 _ZONE_DROP_FILE_TMP 을 지운다.
    \rm -f "${_ZONE_DROP_FILE_TMP}"
    \rm -f "${_ZONE_DROP_LOG_FILE_TMP}"

    #-------------------------------------------------------------
    #_ZONE_LIST 에 대해서 작업한다.
    for _zone  in $_ZONE_LIST
    do
        # iptables log 에 추가할 단어
        _log_msg="${_zone}_ZONE_DROP "   #(ex) "cn_ZONE_DROP"

        # 이전 성공 zone 파일 이름
        _zone_file="$_TMP_DIR/${_zone}.zone"
        # wget으로 받을 zone 파일 이름
        _zone_file_tmp="$_TMP_DIR/${_zone}.zone.tmp"

        # wget으로 다운로드
        _wget_fail_flag=0
        wget -O "$_zone_file_tmp" "http://www.ipdeny.com/ipblocks/data/countries/${_zone}.zone" || _wget_fail_flag=1

        #-------------------------------------------------------------
        # wget 성공시 zone.tmp 파일 이름을 성공 zone 파일 이름으로 mv
        if [ "$_wget_fail_flag" = "0" ] ; then
            if [ -f "$_zone_file_tmp" ] ; then
                _tmp_line_cnt=$(wc -l "${_zone_file_tmp}" | awk '{print $1}')
                if [ "$_tmp_line_cnt" -gt 3 ] ; then
                    \mv -f "$_zone_file_tmp" "$_zone_file"
                    #성공시 
                    echo "[${_zone}] ZONE [${_tmp_line_cnt}] DOWNLOAD SUCCESS"
                else
                    #실패시
                    echo "[${_zone}] ZONE FILE_ERROR FAIL"
                    FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "[${_zone}] ZONE File_Error Fail"
                fi
            else
                #실패시
                echo "[${_zone}] ZONE FILE_NONE FAIL"
                FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "[${_zone}] ZONE File_None Fail"
            fi
        else
            #실패시
            echo "[${_zone}] ZONE DOWNLOAD FAIL"
            FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "[${_zone}] ZONE Download Fail"
        fi

        #-------------------------------------------------------------
        # (wget 성공 || 실패시 이전 성공 파일) -> 파일을 읽어서 _zone_ip_list 에 저장
        if [ -f "$_zone_file" ] ; then
            _zone_ip_list=$(egrep -v "^#|^$" "$_zone_file")
        else
            _zone_ip_list=""
            echo "[${_zone}] ZONE FAIL"
            FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "[${_zone}] ZONE Fail"
            _ZONE_DROP_FILE_FAIL_FLAG=1
            return 
        fi

        #-------------------------------------------------------------
        # _zone_ip_list 가 존재하는 경우 
        # _ZONE_DROP_FILE_TMP, _ZONE_DROP_LOG_FILE_TMP 파일에 ip를 iptables-save 형태로 저장
        if [ ${#_zone_ip_list} -gt 20 ] ; then
            for _ip in $_zone_ip_list
            do
                #echo "$_ip"

                #_ZONE_DROP_LOG_FILE_TMP 파일에 저장
                echo -e "-A ${_CHAIN_DROP_LOG} -s ${_ip} -j LOG --log-prefix \"${_log_msg}\"" >> "${_ZONE_DROP_LOG_FILE_TMP}"

                #_ZONE_DROP_FILE_TMP 파일에 저장
                echo -e "-A ${_CHAIN_DROP} -s ${_ip} -j DROP" >> "${_ZONE_DROP_FILE_TMP}"
            done

        else
            #실패시 해당 zone에 대해서 FAIL을  텔레그램으로 전송
            echo "[${_zone}] ZONE ADD FAIL"
            FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "[${_zone}] ZONE Add Fail"
            _ZONE_DROP_FILE_FAIL_FLAG=1
            return 
        fi
    done

    #-------------------------------------------------------------
    #위에서 저장한 임시 FILE_TMP를 FILE로 mv
    if [ -f "$_ZONE_DROP_FILE_TMP" ] ; then
        \mv -f "${_ZONE_DROP_FILE_TMP}" "${_ZONE_DROP_FILE}"
        \mv -f "${_ZONE_DROP_LOG_FILE_TMP}" "${_ZONE_DROP_LOG_FILE}"
        #-------------------------------------------------------------
        echo "ALL ZONE DROP ADD SUCCESS"
        _tmp_line_cnt="$(wc -l "${_ZONE_DROP_FILE}" | awk '{print $1}')"
        FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "[ ${_ZONE_LIST} ]\nZONE DROP File [${_tmp_line_cnt}] Make End"
        _ZONE_DROP_FILE_FAIL_FLAG=0
    else
        #-------------------------------------------------------------
        echo "ALL ZONE DROP NONE"
        FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "[ ${_ZONE_LIST} ]\nZONE DROP File [0] Make End"
        _ZONE_DROP_FILE_FAIL_FLAG=0
    fi

    return 
}






#######################################################################
# FUNCTION
# MAKE ACCEPT
# from
# -s 120.92.119.0/24 -d 192.168.0.72/32 -p tcp -m tcp --sport 443
# -s 120.92.119.0/24 -d 192.168.0.71/32 -p tcp -m tcp --sport 80
# to
# -A ZONE_ACCEPT -s 110.43.52.0/24 -d 192.168.0.72/32 -p udp -m udp --sport 32100 -j LOG --log-prefix "ZONE_ACCEPT "
# -A ZONE_ACCEPT -s 110.43.52.0/24 -d 192.168.0.71/32 -p udp -m udp --sport 32100 -j ACCEPT
#######################################################################
FUNC_MAKE_ZONE_ACCEPT_FILE()
{
    FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "ZONE ACCEPT File Make Start"

    #-------------------------------------------------------------
    \rm -f "${_ZONE_ACCEPT_FILE_TMP}"
    \rm -f "${_ZONE_ACCEPT_LOG_FILE_TMP}"

    #-------------------------------------------------------------
    # iptables log 에 추가할 단어
    _log_msg="ZONE_ACCEPT "

    #-------------------------------------------------------------
    # _ACCEPT_CFG_FILE 파일을 읽어서 
    # _ZONE_ACCEPT_FILE_TMP, _ZONE_ACCEPT_LOG_FILE_TMP 파일에 iptables-save 형태로 저장
    if [ -f "$_ACCEPT_CFG_FILE" ] ; then
        cat "$_ACCEPT_CFG_FILE" | while read line
        do
            if [ ${#line} -gt 20 ] ; then
                #echo "$line"
                echo -e "-A ${_CHAIN_ACCEPT_LOG} ${line} -j LOG --log-prefix \"${_log_msg}\"" >> "${_ZONE_ACCEPT_LOG_FILE_TMP}"
                echo -e "-A ${_CHAIN_ACCEPT} ${line} -j ACCEPT" >> "${_ZONE_ACCEPT_FILE_TMP}"
            fi
        done

    else
        echo "ZONE ACCEPT CFG FILE[${_ACCEPT_CFG_FILE}] NOT EXIST"
        FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "[${_ACCEPT_CFG_FILE}] Not Exist"
        return 
    fi

    #-------------------------------------------------------------
    if [ -f "$_ZONE_ACCEPT_FILE_TMP" ] ; then
        \mv -f "${_ZONE_ACCEPT_FILE_TMP}" "${_ZONE_ACCEPT_FILE}"
        \mv -f "${_ZONE_ACCEPT_LOG_FILE_TMP}" "${_ZONE_ACCEPT_LOG_FILE}"
        #-------------------------------------------------------------
        echo "ALL ZONE ACCEPT ADD SUCCESS"
        _tmp_line_cnt="$(wc -l "${_ZONE_ACCEPT_FILE}" | awk '{print $1}')"
        FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "ZONE ACCEPT File [${_tmp_line_cnt}] Make End"
    else
        echo "ZONE ACCEPT NONE"
        FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "ZONE ACCEPT File [0] Make End"
    fi

    return 
}


#######################################################################
# FUNCTION
# iptables 에서 chain을 삭제한다.
# 인자1 : 0이면 모두 삭제, 1이면 chain rule은 유지하고 INPUT,FORWARD,OUTPUT 만 삭제
#######################################################################
FUNC_DELETE_ZONE_IN_IPTABLES()
{
    #-------------------------------------------------------------
    #iptables -D INPUT -j ZONE_DROP
    #iptables -D OUTPUT -j ZONE_DROP
    #iptables -D FORWARD -j ZONE_DROP
    #iptables -F ZONE_DROP
    #iptables -X ZONE_DROP

    #iptables -D INPUT -j ZONE_DROP_LOG
    #iptables -D OUTPUT -j ZONE_DROP_LOG
    #iptables -D FORWARD -j ZONE_DROP_LOG
    #iptables -F ZONE_DROP_LOG
    #iptables -X ZONE_DROP_LOG

    #iptables -D INPUT -j ZONE_ACCEPT
    #iptables -D OUTPUT -j ZONE_ACCEPT
    #iptables -D FORWARD -j ZONE_ACCEPT
    #iptables -F ZONE_ACCEPT
    #iptables -X ZONE_ACCEPT

    #iptables -D INPUT -j ZONE_ACCEPT_LOG
    #iptables -D OUTPUT -j ZONE_ACCEPT_LOG
    #iptables -D FORWARD -j ZONE_ACCEPT_LOG
    #iptables -F ZONE_ACCEPT_LOG
    #iptables -X ZONE_ACCEPT_LOG

    #-------------------------------------------------------------
    iptables -D INPUT -j ${_CHAIN_DROP}
    iptables -D OUTPUT -j ${_CHAIN_DROP}
    iptables -D FORWARD -j ${_CHAIN_DROP}

    iptables -D INPUT -j ${_CHAIN_DROP_LOG}
    iptables -D OUTPUT -j ${_CHAIN_DROP_LOG}
    iptables -D FORWARD -j ${_CHAIN_DROP_LOG}

    iptables -D INPUT -j ${_CHAIN_ACCEPT}
    iptables -D OUTPUT -j ${_CHAIN_ACCEPT}
    iptables -D FORWARD -j ${_CHAIN_ACCEPT}

    iptables -D INPUT -j ${_CHAIN_ACCEPT_LOG}
    iptables -D OUTPUT -j ${_CHAIN_ACCEPT_LOG}
    iptables -D FORWARD -j ${_CHAIN_ACCEPT_LOG}


    if [ "${1}" = "0" ] ; then
        iptables -F ${_CHAIN_DROP}
        iptables -X ${_CHAIN_DROP}

        iptables -F ${_CHAIN_DROP_LOG}
        iptables -X ${_CHAIN_DROP_LOG}

        iptables -F ${_CHAIN_ACCEPT}
        iptables -X ${_CHAIN_ACCEPT}

        iptables -F ${_CHAIN_ACCEPT_LOG}
        iptables -X ${_CHAIN_ACCEPT_LOG}

        FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "iptables All ZONE Deleted"
    else
        FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "iptables ZONE IOF Only Deleted"
    fi
}


#######################################################################
# FUNCTION
# iptables 에 chain 에 대해서 INPUT,FORWARD,OUTPUT 을 적용한다.
#######################################################################
FUNC_SET_ZONE_IOF_IN_IPTABLES()
{
    #-------------------------------------------------------------
    # 순서 주의
    #iptables -I INPUT -j ZONE_DROP
    #iptables -I OUTPUT -j ZONE_DROP
    #iptables -I FORWARD -j ZONE_DROP

    #iptables -I INPUT -j ZONE_DROP_LOG
    #iptables -I OUTPUT -j ZONE_DROP_LOG
    #iptables -I FORWARD -j ZONE_DROP_LOG

    #iptables -I INPUT -j ZONE_ACCEPT
    #iptables -I OUTPUT -j ZONE_ACCEPT
    #iptables -I FORWARD -j ZONE_ACCEPT

    #iptables -I INPUT -j ZONE_ACCEPT_LOG
    #iptables -I OUTPUT -j ZONE_ACCEPT_LOG
    #iptables -I FORWARD -j ZONE_ACCEPT_LOG

    #-------------------------------------------------------------
    _tmp="$(iptables -C INPUT -j ${_CHAIN_DROP})"
    if [ $? != 0 ] || [ "$_tmp" ] ; then
        iptables -I INPUT -j ${_CHAIN_DROP}
    fi
    _tmp="$(iptables -C OUTPUT -j ${_CHAIN_DROP})"
    if [ $? != 0 ] || [ "$_tmp" ] ; then
        iptables -I OUTPUT -j ${_CHAIN_DROP}
    fi
    _tmp="$(iptables -C FORWARD -j ${_CHAIN_DROP})"
    if [ $? != 0 ] || [ "$_tmp" ] ; then
        iptables -I FORWARD -j ${_CHAIN_DROP}
    fi

    if [ "$_ZONE_DROP_LOG_USE_FLAG" = "1" ] ; then
        _tmp="$(iptables -C INPUT -j ${_CHAIN_DROP_LOG})"
        if [ $? != 0 ] || [ "$_tmp" ] ; then
            iptables -I INPUT -j ${_CHAIN_DROP_LOG}
        fi
        _tmp="$(iptables -C OUTPUT -j ${_CHAIN_DROP_LOG})"
        if [ $? != 0 ] || [ "$_tmp" ] ; then
            iptables -I OUTPUT -j ${_CHAIN_DROP_LOG}
        fi
        _tmp="$(iptables -C FORWARD -j ${_CHAIN_DROP_LOG})"
        if [ $? != 0 ] || [ "$_tmp" ] ; then
            iptables -I FORWARD -j ${_CHAIN_DROP_LOG}
        fi
    fi

    #-------------------------------------------------------------
    _tmp="$(iptables -C INPUT -j ${_CHAIN_ACCEPT})"
    if [ $? != 0 ] || [ "$_tmp" ] ; then
        iptables -I INPUT -j ${_CHAIN_ACCEPT}
    fi
    _tmp="$(iptables -C OUTPUT -j ${_CHAIN_ACCEPT})"
    if [ $? != 0 ] || [ "$_tmp" ] ; then
        iptables -I OUTPUT -j ${_CHAIN_ACCEPT}
    fi
    _tmp="$(iptables -C FORWARD -j ${_CHAIN_ACCEPT})"
    if [ $? != 0 ] || [ "$_tmp" ] ; then
        iptables -I FORWARD -j ${_CHAIN_ACCEPT}
    fi

    if [ "$_ZONE_ACCEPT_LOG_USE_FLAG" = "1" ] ; then
        _tmp="$(iptables -C INPUT -j ${_CHAIN_ACCEPT_LOG})"
        if [ $? != 0 ] || [ "$_tmp" ] ; then
            iptables -I INPUT -j ${_CHAIN_ACCEPT_LOG}
        fi
        _tmp="$(iptables -C OUTPUT -j ${_CHAIN_ACCEPT_LOG})"
        if [ $? != 0 ] || [ "$_tmp" ] ; then
            iptables -I OUTPUT -j ${_CHAIN_ACCEPT_LOG}
        fi
        _tmp="$(iptables -C FORWARD -j ${_CHAIN_ACCEPT_LOG})"
        if [ $? != 0 ] || [ "$_tmp" ] ; then
            iptables -I FORWARD -j ${_CHAIN_ACCEPT_LOG}
        fi
    fi


    _CUR_ZONE_DROP_LOG_USE_FLAG="$_ZONE_DROP_LOG_USE_FLAG"
    _CUR_ZONE_ACCEPT_LOG_USE_FLAG="$_ZONE_ACCEPT_LOG_USE_FLAG"

    FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "iptables ZONE IOF Applyed\nACCEPT_LOG Use[${_ZONE_ACCEPT_LOG_USE_FLAG}]\nDROP_LOG Use[${_ZONE_DROP_LOG_USE_FLAG}]"
}




#######################################################################
# FUNCTION
# iptables-restore를 위한 _NEW_FILE 파일 생성한다.
# _NEW_FILE 파일을 iptables-restore 한다.
# iptables 에 chain 에 대해서 INPUT,FORWARD,OUTPUT 을 적용한다.
#######################################################################
FUNC_MAKE_NEW_FILE_AND_RESTORE()
{
    #-----------------------------------------------
    # _ZONE_DROP_FILE, _ZONE_ACCEPT_FILE 이 존재하지 않는 경우 생성
    if [ ! -f "$_ZONE_DROP_FILE" ] ; then
        FUNC_MAKE_ZONE_ACCEPT_FILE
        FUNC_MAKE_ZONE_DROP_FILE
    fi

    #-----------------------------------------------
    if [ ! -f "$_ZONE_DROP_FILE" ] ; then
        return 1
    fi

    #-----------------------------------------------
    # original iptables를 저장한다. 저장전에 ZONE을 모두 삭제한다.
    FUNC_DELETE_ZONE_IN_IPTABLES 0
    \rm -f "${_ORG_FILE}"
    iptables-save > "${_ORG_FILE}"

    #-----------------------------------------------
    # original iptables를 저장 확인
    if [ -f "$_ORG_FILE" ] ; then
        _org_file_line_cnt="$(wc -l "${_ORG_FILE}" | awk '{print $1}')"
        _ORG_RULES="$(cat "${_ORG_FILE}")"
        if [ ${#_ORG_RULES} -lt 200 ] ; then
            FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "Orignal iptables Save Fail"
            return 1
        fi
    else
        FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "Original iptables Save Fail"
        return 1
    fi

    #-----------------------------------------------
    # iptables-restore를 위한 _NEW_FILE 파일 생성한다.
    # _ORG_FILE과 _ZONE_DROP_FILE, _ZONE_ACCEPT_FILE 파일을 조합하여 _NEW_FILE 생성
    #-----------------------------------------------
    _RUL1=$(echo "${_ORG_RULES}" | sed -e '1h;2,$H;$!d;g' -re 's/(^.* - \[0:0\])\n.*/\1/')

    if [ ${#_ORG_RULES} -eq ${#_RUL1} ] || [ ${#_RUL1} -eq 0 ] ; then
        FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "iptables sed Fail"
        return 1
    fi
    _RUL2=$(echo "${_ORG_RULES}" | sed -e '1h;2,$H;$!d;g' -re 's/^.* - \[0:0\]\n//')
    _RUL2=$(echo "${_RUL2}" | sed -e '1h;2,$H;$!d;g' -re 's/(^.*\n)COMMIT\n.*/\1/')
    _RUL3=$(echo "${_ORG_RULES}" | sed -e '1h;2,$H;$!d;g' -re 's/^.*\n(COMMIT\n.*)/\1/')

    #-----------------------------------------------
    \rm -f "${_NEW_FILE}"

    #-----------------------------------------------
    echo "${_RUL1}" > "${_NEW_FILE}"

    #ADD ----------  순서주의
    echo "${_NEW_CHAIN_ACCEPT_LOG_RULE}" >> "${_NEW_FILE}"
    echo "${_NEW_CHAIN_ACCEPT_RULE}" >> "${_NEW_FILE}"
    echo "${_NEW_CHAIN_DROP_LOG_RULE}" >> "${_NEW_FILE}"
    echo "${_NEW_CHAIN_DROP_RULE}" >> "${_NEW_FILE}"

    #-----------------------------------------------
    echo "${_RUL2}" >> "${_NEW_FILE}"

    #ADD ---------- 순서주의
    if [ -f "$_ZONE_ACCEPT_LOG_FILE" ] ; then
        cat "${_ZONE_ACCEPT_LOG_FILE}" >> "${_NEW_FILE}"
    fi
    if [ -f "$_ZONE_ACCEPT_FILE" ] ; then
        cat "${_ZONE_ACCEPT_FILE}" >> "${_NEW_FILE}"
    fi
    cat "${_ZONE_DROP_LOG_FILE}" >> "${_NEW_FILE}"
    cat "${_ZONE_DROP_FILE}" >> "${_NEW_FILE}"

    #-----------------------------------------------
    echo "${_RUL3}" >> "${_NEW_FILE}"

    #-----------------------------------------------
    # _NEW_FILE 파일을 iptables-restore 한다.
    #-----------------------------------------------
    iptables-restore < "${_NEW_FILE}"

    #-----------------------------------------------
    # iptables 에 chain 에 대해서 INPUT,FORWARD,OUTPUT 을 적용한다.
    #-----------------------------------------------
    if [ ! -f "${_ZONE_IP_STOP_FILE}" ] ; then
        FUNC_SET_ZONE_IOF_IN_IPTABLES
    fi

    #-----------------------------------------------
    # 최종 iptables를 iptables-save 로 _BKUP_FILE 저장한다.
    #-----------------------------------------------
    \rm -f "${_BKUP_FILE}"
    iptables-save > "${_BKUP_FILE}"

    #-----------------------------------------------
    # 최종 결과를 텔레그램으로 전송한다.
    #-----------------------------------------------
    _tmp2="$(wc -l "${_ZONE_DROP_FILE}" | awk '{print $1}')"
    if [ -f "${_ZONE_ACCEPT_FILE}" ] ; then
        _tmp5="$(wc -l "${_ZONE_ACCEPT_FILE}" | awk '{print $1}')"
    else
        _tmp5="0"
    fi
    _tmp3="$(wc -l "${_NEW_FILE}" | awk '{print $1}')"

    if [ -f "$_BKUP_FILE" ] ; then
        _tmp4="$(wc -l "${_BKUP_FILE}" | awk '{print $1}')"
    else
        _tmp4=0
    fi

    FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "[[ IPTABLES ]]\nORG [ ${_org_file_line_cnt} ]\nZONE_IP [ ${_tmp2} ]\nACCEPT_IP [ ${_tmp5} ]\nNEW [ ${_tmp3} ]\nBACKUP [ ${_tmp4} ]\nAll ZONE OK"
}


#===================================================================================
# main MAIN
#===================================================================================
_zone_ipt_file_update_flag=0

while true
do
    #-------------------------------------------------------------------
    source "$_CONFIG_FILE"

    #-------------------------------------------------------------------
    #일시적으로 iptables에서 ZONE 기능을 사용하지 않기 위해서 추가한 기능, zp(purge), zs(start)
    #-------------------------------------------------------------------
    # iptables -nL ZONE_DROP 1
    # iptables -C INPUT -j ZONE_DROP
    if [ -f "${_ZONE_IP_STOP_FILE}" ] ; then
        #XXXX _ZONE_IP_STOP_FILE 파일이 존재하면 iptables에서 ZONE IOF 만 삭제한다.
        _tmp="$(iptables -C INPUT -j ${_CHAIN_DROP})"
        if [ $? = 0 ] && [ ! "$_tmp" ] ; then #IOF존재함
            FUNC_DELETE_ZONE_IN_IPTABLES 1
        else
            echo "ZONE PURGED"
        fi
    else

        #-------------------------------------------------------------------
        # DROP 파일이 존재하지 않으면 다시 생성한다.
        if [ ! -f "$_ZONE_DROP_FILE" ] ; then
            FUNC_MAKE_NEW_FILE_AND_RESTORE
        fi

        #-------------------------------------------------------------------
        # _ZONE_IP_STOP_FILE 파일이 존재하지 않으면 국가 차단 기능을 iptables에 추가한다.
        _tmp="$(iptables -nL ${_CHAIN_DROP} 1)"
        if [ $? = 0 ] && [ "$_tmp" ] ; then #ZONE chain IP 존재함
            _tmp="$(iptables -C INPUT -j ${_CHAIN_DROP})"
            if [ $? = 0 ] && [ ! "$_tmp" ] ; then #IOF존재함
                echo "ZONE RUNNING"

                #-------------------------------------------------------------------
                # 로그 설정값이 변경된 경우 삭제 후 다시 등록
                #-------------------------------------------------------------------
                if [ "$_CUR_ZONE_ACCEPT_LOG_USE_FLAG" != "$_ZONE_ACCEPT_LOG_USE_FLAG" ] || [ "$_CUR_ZONE_DROP_LOG_USE_FLAG" != "$_ZONE_DROP_LOG_USE_FLAG" ] ; then
                    FUNC_DELETE_ZONE_IN_IPTABLES 1
                    FUNC_SET_ZONE_IOF_IN_IPTABLES
                fi

            else
                #IOF 없음 -> 
                FUNC_SET_ZONE_IOF_IN_IPTABLES
            fi
        else
            #ZONE chain IP 없음 ->
            sleep 10
            FUNC_MAKE_NEW_FILE_AND_RESTORE
        fi

    fi



    #-------------------------------------------------------------------
    # 사용하지 않음이면 모두 삭제 후 종료 
    if [ "${_ZONE_USE_FLAG}" != "1" ] ; then
        FUNC_DELETE_ZONE_IN_IPTABLES 0
        exit 0
    fi


    sleep 5

    #-------------------------------------------------------------------
    # sunday 0700시에  ZONE파일을 다시 생성한다.
    #-------------------------------------------------------------------
    _week="$(date +%u%H%M)"
    if [ "$_week" = "70700" ] ; then
        if [ "$_zone_ipt_file_update_flag" = "0" ] ; then
            _ZONE_DROP_FILE_FAIL_FLAG=0
            FUNC_MAKE_ZONE_ACCEPT_FILE
            FUNC_MAKE_ZONE_DROP_FILE
            if [ "$_ZONE_DROP_FILE_FAIL_FLAG" = "0" ] ; then
                # ZONE 파일 생성에 성공한 경우 ->
                FUNC_MAKE_NEW_FILE_AND_RESTORE
                _zone_ipt_file_update_flag=1
            fi
        fi
    else
        _zone_ipt_file_update_flag=0
    fi



done


