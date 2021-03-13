#!/bin/bash

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
_TMP_DIR="$(dirname "$(readlink -f "$0")")/tmp_tele_rcv"
[ ! -d "$_TMP_DIR" ] && mkdir -p "$_TMP_DIR"

#========================================================
# 환경 설정
#========================================================
# 일부는 211_config.sh 로 옮겼음
_TELE_CHK_INTV=4


#######################################################################
# MAIN
# 주기적으로 연결상태를 체크하여 변경시 텔레그램으로 전송
#######################################################################

#----------------------------------------------------------------------
_cmd="curl -s https://api.telegram.org/bot${_TELE_TOKEN}/getMe"
#echo "${_cmd}"

_get_my_ret="$(${_cmd})"
#echo -e "\n${_get_my_ret}\n"


#----------------------------------------------------------------------
_my_ok=$(echo "$_get_my_ret" | sed -re 's/.*"(ok)":true,.*/\1/')

if [ "$_my_ok" = "ok" ] ; then
	_my_username=$(echo "$_get_my_ret" | sed -re 's/.*"username":"([^\"]+)".*/\1/')
    if [ ${#_get_my_ret} -eq ${#_my_username} ] ; then
		echo "MY username NONE"
		exit 1
	else
		echo "MY username [ ${_my_username} ]"
	fi

	_my_id=$(echo "$_get_my_ret" | sed -re 's/.*"id":([0-9\-]+),.*/\1/')
    if [ ${#_get_my_ret} -eq ${#_my_id} ] ; then
		echo "MY id NONE"
		exit 1
	else
		echo "MY id [ ${_my_id} ]"
	fi
else
	echo "_TELE_TOKEN ERROR : NOT OK -> exit"
	exit 1
fi

#----------------------------------------------------------------------
if [ -e "${_TMP_DIR}/${_my_id}.lastmsg" ] ; then
	_first_flag=0
else
	touch "${_TMP_DIR}/${_my_id}.lastmsg"
	_first_flag=1
fi

#----------------------------------------------------------------------
echo "Start Telegram Message Receive"

#----------------------------------------------------------------------
#----------------------------------------------------------------------
while true ; do

	#----------------------------------------------------------------------
	#Telegram Message
	_tele_msg_ret=$(curl -s "https://api.telegram.org/bot${_TELE_TOKEN}/getUpdates")
	#echo -e "\n${_tele_msg_ret}\n"

	#----------------------------------------------------------------------
	# Parsing Message
	echo "${_tele_msg_ret}" | while read -r _line ; do
		#----------------------------------------------------------------------
		#init value
		_tele_chat_id=0
		_tele_msg_id=0
		_tele_text=0
		_tele_err_flag=0

		#----------------------------------------------------------------------
		_tele_chat_id=$(echo "$_line" | sed -re 's/.*"chat":\{"id":([0-9]+),.*/\1/')
		if [ ${#_line} -eq ${#_tele_chat_id} ] ; then
			_tele_err_flag=1
		fi

		_tele_msg_id=$(echo "$_line" | sed -re 's/.*"message_id":([0-9]+),.*/\1/')
		if [ ${#_line} -eq ${#_tele_msg_id} ] ; then
			_tele_err_flag=1
		fi

		_tele_text=$(echo "$_line" | sed -re 's/.*"text":"(.+)"}}.*/\1/')
		if [ ${#_line} -eq ${#_tele_text} ] ; then
			_tele_err_flag=1
		fi

		#echo "_tele_chat_id  = [${_tele_chat_id}]"
		#echo "_tele_msg_id   = [${_tele_msg_id}]"
		#echo "_tele_text     = [${_tele_text}]"
		#echo "_tele_err_flag = [${_tele_err_flag}]"
		#echo ""

		#----------------------------------------------------------------------
		# 메시지 내용이 존재하면
		if [ $_tele_err_flag -ne 1 ] && [ $_tele_msg_id -ne 0 ] && [ $_tele_chat_id -ne 0 ] ; then

			#----------------------------------------------------------------------
			#CHAT_ID가 일치하면
			if [ "$_TELE_CHAT_ID" = "$_tele_chat_id" ] ; then


				#----------------------------------------------------------------------
				_tele_msg_id_last=$(cat "${_TMP_DIR}/${_my_id}.lastmsg")
				#echo "_tele_msg_id_last    = [${_tele_msg_id_last}]"
				if [ ${#_tele_msg_id_last} -eq 0 ] ; then
					_tele_msg_id_last=0
				fi

				#----------------------------------------------------------------------
				#추가된 메시지인지 확인
				if [ $_tele_msg_id -gt $_tele_msg_id_last ] ; then
					#----------------------------------------------------------------------
					# 최종 _tele_msg_id 저장
					echo $_tele_msg_id > "${_TMP_DIR}/${_my_id}.lastmsg"

					#----------------------------------------------------------------------
					# 처음이 아닌지 확인
					if [ $_first_flag -eq 1 ] ; then
						# 처음인 경우 모든 명령을 SKIP한다.
						echo "SKIP";
					else
						if [ "${#_tele_text}" -gt 0 ] ; then
							curl -s -d "text=COMMAND:[${_tele_text}]&chat_id=${_tele_chat_id}" "https://api.telegram.org/bot${_TELE_TOKEN}/sendMessage" > /dev/null
							nohup "$_tele_text" > "${_TMP_DIR}/${_my_id}.cmd"

							_ret_str=$(cat "${_TMP_DIR}/${_my_id}.cmd")

							#echo "$_ret_str";

							curl -s -d "text=RESULT:${_ret_str}&chat_id=${_tele_chat_id}" "https://api.telegram.org/bot${_TELE_TOKEN}/sendMessage" > /dev/null
						else
							echo "SKIP";
						fi
					fi
				fi
			fi
		fi
	done

	_first_flag=0;

	sleep "$_TELE_CHK_INTV"

done

exit 0
