#!/bin/bash

#==================================================================
# 현재 상태를 조회

#==================================================================
# 211_config.sh 설정 파일 읽어오기
_CONFIG_FILE="$(dirname "$(readlink -f "$0")")/211_config.sh"
if [ -f "$_CONFIG_FILE" ] ; then
    source "$_CONFIG_FILE"
fi



FUNC_MAKE_CURRENT_STATE_STR()
{
    _CURRENT_STATE_STR="\n"
    _CURRENT_STATE_STR="${_CURRENT_STATE_STR}===========================\n"

    if [ "${1}" != "" ] ; then
    #if [ "$*" != "" ] ; then
        _CURRENT_STATE_STR="${_CURRENT_STATE_STR} [[ ${1} ]]\n"
        #_CURRENT_STATE_STR="${_CURRENT_STATE_STR} [[ $* ]]\n"
    else
        _CURRENT_STATE_STR="${_CURRENT_STATE_STR} [[ Status ]]\n"
    fi
    _CURRENT_STATE_STR="${_CURRENT_STATE_STR}===========================\n"

    #---------------------------
    _stmp=$(uptime)
    if [ ${#_stmp} -gt 0 ] ; then
        _stmp=$(echo "$_stmp" | sed "s/,/\\n/")
        _stmp=$(echo "$_stmp" | sed "s/users,/users\\n/")
        _CURRENT_STATE_STR="${_CURRENT_STATE_STR} uptime [${_stmp} ]\n"
    fi

    #---------------------------
    _stmp=$(wget -O - -q http://checkip.dynu.com | awk -F": " '{print $2}')
    if [ ${#_stmp} -gt 0 ] ; then
        #_CURRENT_STATE_STR="${_CURRENT_STATE_STR}---------------------------\n"
        _CURRENT_STATE_STR="${_CURRENT_STATE_STR} WAN IP [ ${_stmp} ]\n"
    fi

    #---------------------------
    if [ -f "/bin/nvram" ] ; then
        _stmp=$(wl -i "$(nvram get wl0_ifname)" phy_tempsense | awk '{printf("%d\n", ($1/2+20) + 0.5)}')
        if [ ${#_stmp} -gt 0 ] ; then
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} 2.4G Temp. [ ${_stmp}C ]\n"
        fi

        _stmp=$(wl -i "$(nvram get wl1_ifname)" phy_tempsense | awk '{printf("%d\n", ($1/2+20) + 0.5)}')
        if [ ${#_stmp} -gt 0 ] ; then
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} 5G   Temp. [ ${_stmp}C ]\n"
        fi
    fi


    #---------------------------
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ] ; then
        _stmp=$(awk '{printf("%d\n", $1/1000 + 0.5)}' < /sys/class/thermal/thermal_zone0/temp)
        if [ ${#_stmp} -gt 0 ] ; then
            #_CURRENT_STATE_STR="${_CURRENT_STATE_STR}---------------------------\n"
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} Cpu0 Temp. [ ${_stmp}C ]\n"

            if [ -f "/sys/class/thermal/thermal_zone1/temp" ] ; then
                _stmp=$(awk '{printf("%d\n", $1/1000 + 0.5)}' < /sys/class/thermal/thermal_zone1/temp)
                if [ ${#_stmp} -gt 0 ] ; then
                    _CURRENT_STATE_STR="${_CURRENT_STATE_STR} Cpu1 Temp. [ ${_stmp}C ]\n"
                fi
            fi
        fi
    fi



    #---------------------------
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ] ; then
        _stmp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
        if [ ${#_stmp} -gt 0 ] ; then
            #_CURRENT_STATE_STR="${_CURRENT_STATE_STR}---------------------------\n"
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} Governor [ ${_stmp} ]\n"
        fi
    fi


    #---------------------------
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq" ] ; then
        _stmp=$(awk '{printf("%d\n", $1/1000 + 0.5)}' < /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq)
        if [ ${#_stmp} -gt 0 ] ; then
            #_CURRENT_STATE_STR="${_CURRENT_STATE_STR}---------------------------\n"
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} Cpu0 Freq. [ ${_stmp} ]\n"

            if [ -f "/sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_cur_freq" ] ; then
                _stmp=$(awk '{printf("%d\n", $1/1000 + 0.5)}' < /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_cur_freq)
                if [ ${#_stmp} -gt 0 ] ; then
                    _CURRENT_STATE_STR="${_CURRENT_STATE_STR} Cpu1 Freq. [ ${_stmp} ]\n"
                fi
            fi

            if [ -f "/sys/devices/system/cpu/cpu2/cpufreq/cpuinfo_cur_freq" ] ; then
                _stmp=$(awk '{printf("%d\n", $1/1000 + 0.5)}' < /sys/devices/system/cpu/cpu2/cpufreq/cpuinfo_cur_freq)
                if [ ${#_stmp} -gt 0 ] ; then
                    _CURRENT_STATE_STR="${_CURRENT_STATE_STR} Cpu2 Freq. [ ${_stmp} ]\n"

                    if [ -f "/sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_cur_freq" ] ; then
                        _stmp=$(awk '{printf("%d\n", $1/1000 + 0.5)}' < /sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_cur_freq)
                        if [ ${#_stmp} -gt 0 ] ; then
                            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} Cpu3 Freq. [ ${_stmp} ]\n"
                        fi
                    fi

                fi
            fi

        fi

    else
        _stmp=$(grep -i Mhz < /proc/cpuinfo)
        if [ ${#_stmp} -gt 0 ] ; then
            #_stmp=$(echo "$_stmp" | sed "s/cpu MHz\t/Cpu Freq. MHz /g")
            _stmp=$(echo "$_stmp" | sed "s/cpu MHz\t\t/ Cpu Freq. /g;s/$/ MHz /g")
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR}${_stmp}\n"
        fi
    fi


    #---------------------------
    if [ -f "/bin/nvram" ] ; then
        _stmp="$(nvram get territory_code)"
        if [ ${#_stmp} -gt 0 ] ; then
            #_CURRENT_STATE_STR="${_CURRENT_STATE_STR}---------------------------\n"
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} territory_code [ ${_stmp} ]\n"
        fi

        _stmp="$(nvram get location_code)"
        if [ ${#_stmp} -gt 0 ] ; then
            #_CURRENT_STATE_STR="${_CURRENT_STATE_STR}---------------------------\n"
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} location_code [ ${_stmp} ]\n"
        fi

        _stmp=$(wl -i "$(nvram get wl0_ifname)" txpwr_target_max | awk '{printf("%s\n", $6)}')
        if [ ${#_stmp} -gt 0 ] ; then
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} 2.4G TX Power [ ${_stmp}dBm ]\n"
        fi

        _stmp=$(wl -i "$(nvram get wl1_ifname)" txpwr_target_max | awk '{printf("%s\n", $6)}')
        if [ ${#_stmp} -gt 0 ] ; then
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} 5G   TX Power [ ${_stmp}dBm ]\n"
        fi
    fi



    #-----------------------------
    _free=$(free)

    #_CURRENT_STATE_STR="${_CURRENT_STATE_STR}---------------------------\n"

    _target="Mem"
    _stmp=$(echo "${_free}" | grep "${_target}" | awk '{printf("%dM/%dM\n", $4/1000 + 0.5, $2/1000 + 0.5)}')
    if [ ${#_stmp} -gt 0 ] ; then
        _stmp=$(echo "$_stmp" | sed "s/\// \/ /")
        _CURRENT_STATE_STR="${_CURRENT_STATE_STR} ${_target}. Free [ ${_stmp} ]\n"
    fi

    _target="Swap"
    _stmp=$(echo "${_free}" | grep "${_target}" | awk '{printf("%dM/%dM\n", $4/1000 + 0.5, $2/1000 + 0.5)}')
    if [ ${#_stmp} -gt 0 ] ; then
        _stmp=$(echo "$_stmp" | sed "s/\// \/ /")
        _CURRENT_STATE_STR="${_CURRENT_STATE_STR} ${_target} Free [ ${_stmp} ]\n"
    fi


    #-----------------------------
    _df_h=$(df -h)

    #_CURRENT_STATE_STR="${_CURRENT_STATE_STR}---------------------------\n"

    _stmp=$(echo "${_df_h}" | grep "^.*\/$" | awk '{printf("%s/%s\n", $4, $2)}')
    if [ ${#_stmp} -gt 0 ] ; then
        _stmp=$(echo "$_stmp" | sed "s/\// \/ /")
        _CURRENT_STATE_STR="${_CURRENT_STATE_STR} /       Free [ ${_stmp} ]\n"
    fi


    #----------------------------------
    if [ -f "/bin/nvram" ] ; then

        _target="/jffs"
        _stmp=$(echo "${_df_h}" | grep "${_target}" | awk 'NR==1{printf("%s/%s\n", $4, $2)}')
        if [ ${#_stmp} -gt 0 ] ; then
            _stmp=$(echo "$_stmp" | sed "s/\// \/ /")
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} ${_target}   Free [ ${_stmp} ]\n"
        fi


        _target="/opt"
        _stmp=$(echo "${_df_h}" | grep "${_target}" | awk '{printf("%s/%s\n", $4, $2)}')
        if [ ${#_stmp} -gt 0 ] ; then
            _stmp=$(echo "$_stmp" | sed "s/\// \/ /")
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} ${_target}    Free [ ${_stmp} ]\n"
        fi

    fi


    #----------------------------------
    if [ "${_ZONE_USE_FLAG}" = "1" ] ; then
        #----------------------------------
        #_CURRENT_STATE_STR="${_CURRENT_STATE_STR}---------------------------\n"
        _CHAIN_DROP="ZONE_DROP"                      #iptables 에서 DROP 할 chain 이름
        _zone_ip_sts="Not Use"
        _stmp="$(iptables -nL ${_CHAIN_DROP} 1)"
        if [ $? = 0 ] && [ "$_stmp" ] ; then #ZONE chain IP 존재함
            _stmp="$(iptables -C INPUT -j ${_CHAIN_DROP})"
            if [ $? = 0 ] && [ ! "$_stmp" ] ; then #IOF존재함
                _zone_ip_sts="Running"
            else
                _zone_ip_sts="Purged"
            fi
        else
            _zone_ip_sts="Not Use"
        fi

        if [ ${#_ZONE_LIST} -gt 0 ] ; then
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} ZONE IP [ ${_ZONE_LIST} ${_zone_ip_sts} ]\n"
        else
            _CURRENT_STATE_STR="${_CURRENT_STATE_STR} ZONE IP [ ${_zone_ip_sts} ]\n"
        fi

    fi






    #----------------------------------
    _CURRENT_STATE_STR="${_CURRENT_STATE_STR}===========================\n"

}




