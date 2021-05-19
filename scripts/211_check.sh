#!/bin/bash

#==================================================================
# 주기적으로 상태를 체크하여 필요시 실행
#
# 매일 0900 시에 공유기 상태를 텔레그램으로 전송한다.
# CPU 온도를 텔레그램으로 전송
# WIFI 모듈의 파워(dBm), 온도를 텔레그램으로 전송
# RAM, SWAP, 메모리 상태를 텔레그램으로 전송
# CPU 온도 변화가 _DIFF_TEMP 만큼 변한 경우 텔레그램으로 전송
# RAM FREE 변화가 _DIFF_TRAM 만큼 변한 경우 텔레그램으로 전송
# WAN_IP 외부에서 접속을 위한 IP를 구해서 텔레그램으로 전송
#
# 공유기의 국가코드와 위치코드를 강제로 변경하고자 하는 경우 사용
# 주기적으로 현재 상태를 체크하여 강제로 변경함
#
# openvpn 이 실행된 경우 내부망 접속을 위한 추가
# openvpn 설정에서 대역을 192.168.10.0 를 사용하도록 변경하였다.
# 설정값에 따라 192.168.10.0 를 변경하여 사용해야 한다.
#
# 중국 uuplugin 관련 process 를 사용하지 않도록 kill
#
# 성능테스트를 위하여 /tmp/iperf 가 존재하면 iperf3 서버를 실행
#==================================================================

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
# 211_cur_sts.sh 파일 읽어오기 
_CUR_STS_FILE="$(dirname "$(readlink -f "$0")")/211_cur_sts.sh"


#==================================================================
# 환경 설정
# 211_config.sh  로 이동

#변경하고자 하는 국가코드와 위치코드 설정
#_TERRITORY_CODE="US/01"
#_TERRITORY_CODE="CN/01"
#_LOCATION_CODE="XX"

#_DIFF_TEMP=5        #CPU 온도차가 _DIFF_TEMP 만큼되면 전송
#_DIFF_RAM=20        #RAM FREE 차이가 _DIFF_RAM 만큼되면 전송
#_CHK_RAM_CNT_MAX=3  #RAM은 너무 가변적이라 차이가 _CHK_RAM_CNT_MAX 번 만큼 유지되어야 전송
#==================================================================

#==================================================================
# LOCAL 변수 설정
_my_sts_sent_flag=0
_chk_ram_cnt_cur=0
_wan_ip=""
_wan_ip_chk_flag=0
_cpu_temp="0"
#==================================================================



#######################################################################
# FUNCTION
# ROUTER CPU, WIFI출력, 메모리 상태를 텔레그램으로 전송한다.
# 인자 1 : 전송 원인
#######################################################################
FUNC_SEND_ROUTER_STS(){
    source "$_CUR_STS_FILE"

	if [ "${_TELEGRAM_USE_FLAG}" = "1" ] ; then
		FUNC_MAKE_CURRENT_STATE_STR "${1}"

		#----------------------------------
		FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "${_CURRENT_STATE_STR}"

		_chk_ram_cnt_cur=0
	fi
}
#######################################################################





#######################################################################
# main
#######################################################################

#-----------------------------------------------------------
_cpu_temp=$(awk '{printf("%d\n", $1/1000 + 0.5)}' < /sys/class/thermal/thermal_zone0/temp)
_ram=$(free | grep Mem | awk '{printf("%d", $4/1000 + 0.5)}')
#시작시 WAN_IP를 구한다.
_wan_ip=$(wget -O - -q http://checkip.dynu.com | awk -F": " '{print $2}')

#-----------------------------------------------------------
#시작시 ROUTER 현재 상태를 텔레그램으로 전송
FUNC_SEND_ROUTER_STS "Start"
    
#-----------------------------------------------------------
while true
do
    #-----------------------------------------------------------
    source "$_CONFIG_FILE"

    #-----------------------------------------------------------
    # 공유기의 국가코드와 위치코드를 강제로 변경하고자 하는 경우 사용
    # 주기적으로 현재 상태를 체크하여 강제로 변경함
    #-----------------------------------------------------------
    # 국가코드를 변경
    #-----------------------------------------------------------
    if [ ${#_TERRITORY_CODE} -gt 0 ] ; then
        _tmp="$(nvram get territory_code)"
        if [ ${#_tmp} -gt 0 ] ; then
            if [ "${_tmp}" != "${_TERRITORY_CODE}" ] ; then
				if [ "${_TELEGRAM_USE_FLAG}" = "1" ] ; then
                	FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "territory_code 변경 ${_tmp} -> ${_TERRITORY_CODE}"
				fi
                nvram set territory_code="${_TERRITORY_CODE}"
                nvram commit
            fi
        fi
        sleep 1
    fi

    #-----------------------------------------------------------
    # 위치코드를 변경
    #-----------------------------------------------------------
    if [ ${#_LOCATION_CODE} -gt 0 ] ; then
        _tmp="$(nvram get location_code)"
        if [ ${#_tmp} -gt 0 ] ; then
            if [ "${_tmp}" != "${_LOCATION_CODE}" ] ; then
				if [ "${_TELEGRAM_USE_FLAG}" = "1" ] ; then
                	FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "location_code 변경 ${_tmp} -> ${_LOCATION_CODE}"
				fi
                nvram set location_code="${_LOCATION_CODE}"
                nvram commit
            fi
        fi
        sleep 1
    fi

    #-----------------------------------------------------------
    # 중국 uuplugin 관련 process 를 사용하지 않도록 kill
    #-----------------------------------------------------------
    if [ "${_KILL_UUPLUGIN}" = "1" ] ; then
		_tmp=$(pidof uuplugin_monitor.sh)
		if [ "${_tmp}" ] ; then
			kill -9 "${_tmp}"
		fi
		_tmp=$(pidof uuplugin)
		if [ "${_tmp}" ] ; then
			kill -9 "${_tmp}"
		fi
		sleep 1
	fi

    #-----------------------------------------------------------
    # openvpn 이 실행된 경우 내부망 접속을 위한 추가
    #-----------------------------------------------------------
    _tmp=$(pidof openvpn)
    if [ "${_tmp}" ] ; then
        _vpn_ip="$(nvram get vpn_server_sn)"
        #_vpn_ip="$(nvram get vpn_server1_sn)"
        if [ "${_vpn_ip}" ] ; then
            #_tmp=$(iptables -t nat -nL POSTROUTING | grep "192.168.10.0/24")
            _tmp=$(iptables -t nat -nL POSTROUTING | grep "${_vpn_ip}/24")
            if [ ! "${_tmp}" ] ; then
                #iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o br0 -j MASQUERADE
                iptables -t nat -A POSTROUTING -s "${_vpn_ip}"/24 -o br0 -j MASQUERADE
    			if [ "${_TELEGRAM_USE_FLAG}" = "1" ] ; then
                	FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "OPENVPN ${_vpn_ip} POSTROUTING ADDED"
				fi
            fi
        fi
    fi
    sleep 1

    #-----------------------------------------------------------
    # ssh 접속을 위한 dropbear 이 죽는 경우 재실행 하도록 함
    #-----------------------------------------------------------
    #if [ ! "$(pidof dropbear)" ] ; then
    #    _tmp="$(nvram get lan_ipaddr)"
    #    if [ "${_tmp}" ] ; then
    #        dropbear -p "${_tmp}":22 -a &
    #		if [ "${_TELEGRAM_USE_FLAG}" = "1" ] ; then
    #       		FUNC_SEND_TELEGRAM_BOT "${_TELE_TOKEN}" "${_TELE_CHAT_ID}" "dropbear ${_tmp} START"
	#		fi
    #    fi
    #fi
    #sleep 1



    #==============================================================================
    # 정각이 되거나 값이 변경되면 텔레그램으로 상태를 전송한다.
    #==============================================================================
    if [ "${_TELEGRAM_USE_FLAG}" = "1" ] ; then

		#------------------------------------------------------------------------------
		# 매일 0900 시에 공유기 상태를 텔레그램으로 전송한다.
		#------------------------------------------------------------------------------
		_tmp="$(date +%H%M)"
		if [ "$_tmp" = "0900" ] || [ "$_tmp" = "0901" ] ; then
			if [ $_my_sts_sent_flag -eq 0 ] ; then
				_my_sts_sent_flag=1
				FUNC_SEND_ROUTER_STS "오전 9시"
				continue
			fi
		else
			_my_sts_sent_flag=0
		fi
		sleep 1

		#------------------------------------------------------------------------------
		# CPU 온도 변화 체크 -> 공유기 상태를 텔레그램으로 전송한다.
		#------------------------------------------------------------------------------
		_tmp=$(awk '{printf("%d\n", $1/1000 + 0.5)}' < /sys/class/thermal/thermal_zone0/temp)
		if [ ${#_tmp} -gt 0 ] ; then
			_tmp_max=$((_cpu_temp + _DIFF_TEMP))
			_tmp_min=$((_cpu_temp - _DIFF_TEMP))
			if [ "${_tmp}" -ge "${_tmp_max}" ] || [ "${_tmp}" -le "${_tmp_min}" ] ; then
				FUNC_SEND_ROUTER_STS "Cpu Temp. ${_cpu_temp} -> ${_tmp}"
				_cpu_temp="${_tmp}"
				continue
			fi
		fi
		sleep 1

		#------------------------------------------------------------------------------
		# RAM FREE 용량 체크 -> 공유기 상태를 텔레그램으로 전송한다.
		#------------------------------------------------------------------------------
		_tmp=$(free | grep Mem | awk '{printf("%d", $4/1000 + 0.5)}')
		if [ ${#_tmp} -gt 0 ] ; then
			_tmp_max=$((_ram + _DIFF_RAM))
			_tmp_min=$((_ram - _DIFF_RAM))
			if [ "${_tmp}" -ge "${_tmp_max}" ] || [ "${_tmp}" -le "${_tmp_min}" ] ; then
				_chk_ram_cnt_cur=$((_chk_ram_cnt_cur + 1))
				if [ "${_chk_ram_cnt_cur}" -ge "${_CHK_RAM_CNT_MAX}" ] ; then
					FUNC_SEND_ROUTER_STS "Mem. Free ${_ram} -> ${_tmp}"
					_ram="${_tmp}"
					continue
				fi
			else
				_chk_ram_cnt_cur=0
			fi
		fi
		sleep 1

		#-----------------------------------------------------------
		# WAN_IP 외부에서 공유기 접속을 위한 IP를 구해서 텔레그램으로 전송
		#-----------------------------------------------------------
		#분을 10으로 나눈 값이 0이면...-> 10분단위로 체크하기 위함
		if [ "$(expr "$(date +%M)" % 10)" = "0" ] ; then
			if [ $_wan_ip_chk_flag -eq 0 ] ; then
				_tmp=$(wget -O - -q http://checkip.dynu.com | awk -F": " '{print $2}')
				if [ ${#_tmp} -gt 0 ] ; then
					if [ "${_tmp}" != "${_wan_ip}" ] ; then
						FUNC_SEND_ROUTER_STS "WAN IP"
						_wan_ip="${_tmp}"
						continue
					fi
					_wan_ip_chk_flag=1
				fi
			fi
		else
			_wan_ip_chk_flag=0
		fi
		sleep 1
    fi


    #-----------------------------------------------------------
    # 성능테스트를 위하여 /tmp/iperf 가 존재하면 iperf3 서버를 실행
    #-----------------------------------------------------------
    if [ -f "/tmp/iperf" ] ; then
        _tmp=$(pidof iperf3)
        if [ ${#_tmp} -lt 1 ] ; then
            iperf3 -s &
        fi
    else
        _tmp=$(pidof iperf3)
        if [ "${_tmp}" ] ; then
            kill -9 "${_tmp}"
        fi
    fi
    sleep 1



done
