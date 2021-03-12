#!/bin/bash

#######################################################################
# 공통으로 사용할 환경 설정 값
#######################################################################
_PWD="$(dirname "$(readlink -f "$0")")"

#======================================================================
#USB 메모리 관련 설정
#usb_mount.sh
#======================================================================
#USB 저장장치의 LABEL : 필수
_USB_STORAGE_LABEL="usb"  #변경시 리부팅 필요
#SWAP 파일 사용 여부(RAM이 부족한 경우 재부팅되는 현상 방지)
_SWAP_USE_FLAG=1          #변경시 리부팅 필요


#======================================================================
#국가별 IP를 차단하는 기능. 해당 국가로부터 유입되는 해킹 차단
#211_zone_ip.sh
#======================================================================
#211_zone_ip.sh 실행 여부
_ZONE_USE_FLAG=1          #변경시 리부팅 필요

#/jffs/syslog.log 파일에 로그를 남길 것인지 여부
_ZONE_DROP_LOG_USE_FLAG=1      #실시간 적용
_ZONE_ACCEPT_LOG_USE_FLAG=0    #실시간 적용

# IP 차단할 국가. 많아질수록 공유기 느려진다.
# 변경시 rm -f ./tmp_zone_ip/*  실행 필요 
#_ZONE_LIST="cn ru af au br pk sa sc tr tw ua vn jp"
_ZONE_LIST="cn ru af"

#_ZONE_IP 기능을 일시적으로 중지/재시작 할 때 사용할 파일. 존재하면 중지(PURGE)(zp). 삭제하면 재시작(zs)
_ZONE_IP_STOP_FILE="/tmp/z"    #실시간 적용


#======================================================================
#공유기 상태, 설정 관리
#211_check.sh
#======================================================================
#강제로 변경하고자 하는 국가코드
#리부팅하거나 웹설정에서 설정을 변경하면 nvram 에서 기본값으로 원복된다. 원복되는 경우 자동으로 변경하도록 하기 위해 사용
#현재 설정값 확인 : nvram get territory_code
_TERRITORY_CODE=""               #이 기능을 사용하지 않을 경우 설정
#_TERRITORY_CODE="CN/01"          #실시간 적용
#_TERRITORY_CODE="US/01"          #실시간 적용
#_TERRITORY_CODE="KR/01"          #실시간 적용
#_TERRITORY_CODE="GD/01"          #실시간 적용, 건담모드

#변경하고자 하는 위치코드 설정
#웹설정에서 강제로 변경하더라도 자동으로 변경하기 위해 사용
#출력(dBm) 값은 리부팅해야 적용된다.
#현재 설정값 확인 : nvram get location_code
# wl -i $(nvram get wl0_ifname) txpwr_target_max
# wl -i $(nvram get wl1_ifname) txpwr_target_max
#오스트레일리아(호주)는 AU와 XX가 존재한다. XX로 설정하면 무선 강도가 가장 강하다.
#한국에서는 200mw을 초과하면 불법이다. 벌금을 선물받을 수 있으니 주의해야 한다.
#location_code=XX #2.4G : 27.00dBm / 501.19mw #5G : 26.00dBm / 398.11mw
#location_code=AU #2.4G : 23.50dBm / 223.87mw #5G : 20.50dBm / 112.20mw
#location_code=KR #2.4G : 23.50dBm / 223.87mw #5G : 20.50dBm / 112.20mw
_LOCATION_CODE=""      #이 기능을 사용하지 않을 경우 설정
#_LOCATION_CODE="XX"   #실시간 적용. 리부팅 필요
#_LOCATION_CODE="US"   #실시간 적용. 리부팅 필요
#_LOCATION_CODE="KR"   #실시간 적용. 리부팅 필요
#_LOCATION_CODE="GD"   #실시간 적용. 리부팅 필요, 건담모드


#CPU 온도, RAM FREE 용량 변경시 텔레그램 전송을 위한 차이값 설정
#CPU 온도차가 _DIFF_TEMP 만큼되면 전송
_DIFF_TEMP=5                      #실시간 적용
#RAM FREE 차이가 _DIFF_RAM 만큼되면 전송
_DIFF_RAM=30                      #실시간 적용
#RAM은 너무 가변적이라 차이가 _CHK_RAM_CNT_MAX 번 만큼 유지되어야 전송
_CHK_RAM_CNT_MAX=3                #실시간 적용



#======================================================================
# 공유기의 상태를 텔레그램 봇으로 전송. 
# 공유기 상태를 수신할 봇과 WIFI상태를 수신할 봇을 따로 만드는 것이 좋다.
# 텔레그램 CHAT ID, TOKEN 설정
#======================================================================
#공유기 상태 텔레그램 전송 기능 사용 여부
_TELEGRAM_USE_FLAG=0  #변경시 리부팅 필요

# 텔레그램 가입자 CHAT ID
_TELE_CHAT_ID="111111111"    #변경시 리부팅 필요

#텔레그램 토큰. 공유기 상태 수신 봇
_TELE_TOKEN="9999999999:CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"    #변경시 리부팅 필요



#======================================================================
#공유기의 WIFI에 접속하는 휴대폰의 상태를 텔레그램으로 전송
#자녀가 방과 후 집에 잘 도착했는지 확인하기 위해서 사용
#211_wifi_sts.sh
#======================================================================
_WIFI_STS_USE_FLAG=0  #변경시 리부팅 필요
#설정해야 하는 값들이 많아서 211_wifi_sts.sh 에 설정해야 한다.

# 현재 상태를 저장할 디렉토리
_TMP_WIFI_STS_DIR="${_PWD}/tmp_wifi_sts"

# 연결/끊김 단어 설정
_IN_STR=" <- 연결" 
_OUT_STR=" -> 끊김"

_ROUTER="[ 공유기 ]" 

#--------------------------------------
# 검색할 WIFI 사용자 이름과 휴대폰 설정
#--------------------------------------
# 이름 설정 -> 10명이상인 경우 211_wifi_sts.sh, 211_cur_sts.sh 수정 필요
_NAME1="${_ROUTER} [홍길동폰]"
_NAME2="${_ROUTER} [마눌님폰]"
_NAME3="${_ROUTER} [이쁜딸폰]"
_NAME4="${_ROUTER} [이쁜딸탭]"

# 휴대폰 MAC이나 공유기에 표시되는 이름 설정
# 최신 폰은 보안을 위해서 WIFI MAC이 랜덤으로 변경되므로 공유기에서 조회되는 폰 이름으로 등록하도록 한다.
_MAC_OR_DNAME1="00:00:00:00:00:00"
_MAC_OR_DNAME2="Galaxy-A90"
_MAC_OR_DNAME3="Galaxy-A7"
_MAC_OR_DNAME4="11:11:11:11:11:11"

# 현재 WIFI 상태를 저장할 파일
_CONN_FILE1="${_TMP_WIFI_STS_DIR}/1"
_CONN_FILE2="${_TMP_WIFI_STS_DIR}/2"
_CONN_FILE3="${_TMP_WIFI_STS_DIR}/3"
_CONN_FILE4="${_TMP_WIFI_STS_DIR}/4"

#--------------------------------------
# WIFI 상태를 전송할 텔레그램 설정
# 공유기 상태를 수신할 봇과 구분하기 위하여 WIFI상태를 수신할 봇을 따로 만드는 것이 좋다.
#--------------------------------------
# 텔레그램 가입자 CHAT ID
_CHATID1="111111111"  #홍길동
_CHATID2="444444444"  #마눌님
_CHATID3="555555555"  #이쁜딸
# 텔레그램 토큰. WIFI 상태 수신 봇
_TOKEN1="000000000:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
_TOKEN2="111111111:BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
_TOKEN3="222222222:CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"

#--------------------------------------
# WIFI 상태를 어느 텔레그램 전송 할 것인지 설정
# 행:WIFI상태, 열:텔레그램
#(ex) _WIFI_CONN_SEND1="1,0,1" -> _MAC_OR_DNAME1의 연결상태를 _CHATID1, _CHATID3에 전송, _CHATID2에는 전송안함
#--------------------------------------
_WIFI_CONN_SEND1="1,1,1" 
_WIFI_CONN_SEND2="1,1,1"
_WIFI_CONN_SEND3="1,1,1"
_WIFI_CONN_SEND4="1,1,1"













#######################################################################
# 아래는 수정하면 안된다.
# 텔레그램으로 전송
# 인자  1:TELE_TOKEN   2:TELE_CHAT_ID   3:보낼 내용
# 보낼 내용이 일반문자임 -> curl로 url문자로 변환하여 처리한다.
#######################################################################
FUNC_SEND_TELEGRAM_BOT(){
    if [ "${_TELEGRAM_USE_FLAG}" = "1" ] ; then
        _msg=$(echo -e "${3}" | curl -Gso /dev/null -w %{url_effective} --data-urlencode @- "" | sed -E 's/..(.*).../\1/')
        #echo "MESSAGE = [${_msg}]"

        curl -s -d "text=${_msg}" "https://api.telegram.org/bot${1}/sendmessage?chat_id=${2}&" > /dev/null
    fi
}
#######################################################################

