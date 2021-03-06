# asus-router-sh


ASUS 공유기에서 부팅시에 스크립트를 자동으로 실행하게 하는 방법이다. 
ASUS 정식 펌웨어에서도 잘 동작한다. 


아래는 내가 만들어서 사용하는 스크립트들이다.
이 스크립트들은 ASUS 정펌에서 잘 동작한다. 


필요 사항 : USB 메모리 필요.
            USB 메모리 포맷시에 NTFS 타입으로 하고, 반드시 "usb"란 이름으로 해야 한다.
            공유기 설정에서 ssh 기능 활성화 필요
            ssh 접속을 위한  putty나 테라텀 필요
            공유기 설정에서 ftp나  samba  기능 활성화 필요


기타 추가 기능
            jffs, opt를  USB메모리에 저장 하도록 한다. jffs 의 용량 제한 때문에 추가함.
            swap 을 1기가를 설정한다. RAM 용량 부족을 위해서 추가함.
            territory_code 가 중국(CN/01)인 경우 중국어를 선택해도 한국어로 되도록 추가함.



스크립트 파일 목록

    211_main.sh
        *.sh 가 종료되면 자동으로 실행 
        *.sh 의 내용이 변경되면 자동 재실행

    211_check.sh
        주기적으로 상태를 체크하여 필요시 실행
        공유기의 국가코드와 위치코드를 강제로 변경하고자 하는 경우 사용
        주기적으로 현재 상태를 체크하여 강제로 변경함
        openvpn 이 실행된 경우 내부망 접속을 위한 추가
        openvpn 설정에서 대역을 192.168.10.0 를 사용하도록 변경하였다.
            설정값에 따라 192.168.10.0 를 변경하여 사용해야 한다.
        중국 uuplugin 관련 process 를 사용하지 않도록 kill
        매일 0900 시에 공유기 상태를 텔레그램으로 전송한다.
        공유기 CPU 온도를 텔레그램으로 전송
        공유기 WIFI 모듈의 파워(dBm), 온도를 텔레그램으로 전송
        공유기 RAM, SWAP, 메모리 상태를 텔레그램으로 전송
        CPU 온도 변화가 _DIFF_TEMP 만큼 변한 경우 텔레그램으로 전송
        RAM FREE 변화가 _DIFF_RAM 만큼 변한 경우 텔레그램으로 전송
        WAN_IP 외부에서 공유기 접속을 위한 IP를 구해서 텔레그램으로 전송

    211_wifi_sts.sh
        가족 WIFI 연결 상태를 텔레그램으로 전송
        가족 스마트폰의 WIFI 접속여부를 확인하여 외출했는지 집에 도착했는지를 텔레그램으로 전송하는 스크립트

    211_zone_ip.sh
        국가별 IP 대역을 읽어와 iptables를 사용하여 차단하는 스크립트
        중국, 러시아 등을 차단하였다. 
        속도가 느려지므로 꼭 필요한 경우에만 사용한다.

    211_zone_ip.allow 는 허용하는 IP 리스트이다. 
        mihome 의 중국서버들을  *71, *72 스마트폰IP 에만 하용하게 설정되어 있다. 

    211_cur_sts.sh
        현재 상태를 조회하여 문자로 변경하는 스크립트로 다른 스크립트에 의해서 실행된다.

    211_config.sh
        공통으로 사용할 환경 설정 값
        사용자 수정 필요한 스크립트 


    211_tele_rcv.sh
        텔레그램으로부터 명령을 입력받아 실행하는 스크립트 
        예를 들어 텔레그램 Bot에 c 를 입력하여 전송하면 이 스크립트가 입력된 c(현재 상태를 터미널 화면에 출력하는 스크립트) 명령을 실행하여 현재 공유기의 상태를 텔레그램으로 전송한다.
        이 스크립트는 4초 간격으로 새로 입력된 명령이 있는지 확인한다. 따라서 명령 입력후 4초 정도 후에 실행되는 경우도 있다. 
        입력된 명령이 공유기에서 그대로 실행되므로 rm * 같은 모두 삭제하는 명령등 공유기에 위험한 명령은 사용하지 않거나 주의해서 사용해야 한다. 
        top 과 같이 계속 실행되어 유지되는 명령은 절대 사용하지 않아야 한다. 


    211_usb_use.sh
        USB 메모리와 211*.sh 사용시 최초 한번만 실행
        USB 메모리 mount시에 211*.sh를 실행하기 위한 설정

    c
        현재 상태를 터미널 화면에 출력

    usb_mount.sh
    usb_umount.sh
        USB 메모리 mount, unmount 시 실행할 스크립트

    zp
        211_zone_ip 기능을 중지한다

    zs
        zp에 의해서 중지된 211_zone_ip 기능을 재시작한다




스크립트의 사용환경을 설정해야 한다.

    "텔레그램 봇 chat id token" 만들기로 네이버에서 검색하여 텔레그램 봇을 만든 후에 
    CHAT ID와 TOKEN 값을 구하여 스크립트의 CHAT ID와 TOKEN 값을 변경해야 한다. 
    다른 설정 값들도 적절히 수정한다.

    211_config.sh
        환경 설정 스크립트이다.
        텔레그램의 CHAT ID와 TOKEN값을 구해서 입력해야 한다.
        구하는 방법은 네이버 검색 (텔레그램 봇 chat id token)
        공유기의 상태를 전송받을 봇과 WIFI상태를 전송받을 봇을 별도로 만드는 것이 좋다.


        (오스트레일리아는 위치코드는 AU와 XX가 존재한다. XX로 설정하면 무선 강도가 가장 강하다.)
        한국은 23dBm 을 초과하면 불법으로 벌금을 선물받을 수 있으니 주의해야 한다.

        가족 각각의 스마트폰에서 텔레그램 봇을 만들고 CHAT ID와 TOKEN값을 구해서 입력해야 한다.
        공유기에서 조회된 이름이나 MAC을 입력 한다.

    211_zone_ip.allow
        211_zone_ip.sh 에서 사용되는 허용하는 IP 리스트이다. 
        mihome 의 중국서버들을  *71, *72 스마트폰IP 에만 허용하게 설정되어 있다.  

        공유기의 DHCP 서버 설정에서 mihome을 사용할 폰을 고정 IP(71, 72) 로 설정하였다.
        ZONE DROP 로그를 활성화한 후에 mihome앱으로 접속을 시도하고 공유기의 /jffs/syslog 를 
            확인하여 차된된 mihome ip, port 들을 구하였다.



설치 방법

    1. 공유기에 USB메모리를 장착한 후 공유기의 USB메뉴에서 메모리를 포맷한다.
       공유기의 USB메뉴에서 메모리를 포맷 할 때 Label 이름을  "usb" 로 한다. 

    2. USB 메모리는 /tmp/mnt/usb 으로 mount 된다.

    3. 공유기의 ssh 기능을 활성화 한다. 
       Administration -> System -> Service -> Enable SSH -> LAN only
       putty나 teraterm을 다운로드 받아 설치한 후에 공유기의 ip와 port(22)를 입력하여 접속한다.

    4. ssh 접속
       id와 password는 WEB설정 접속할 때와 동일하다.
       usb메모리 디렉토리로 이동한다.
       cd /tmp/mnt/usb
       
       최초인 경우 스크립트 디렉토리 생성
       mkdir scripts
       
       이전 파일이 존재하는 경우 삭제
       rm main.zip
       rm -rf asus-router-sh-main

       스크립트 압축 파일 다운로드 
       wget https://github.com/ffss33/asus-router-sh/archive/main.zip
       
    5. 파일의 압축을 푼다. 
       unzip main.zip
       
    6. 업그레이드 설치인 경우 이전 설정 파일을 백업
       cp /tmp/mnt/usb/scripts/211_config.sh /tmp/mnt/usb/211_config.sh 

    7. 스크립트들을 복사한다. 
       cp -af asus-router-sh-main/scripts/* /tmp/mnt/usb/scripts/

    8. 211_config.sh 를 수정한다. 

       최초 설치인 경우 211_config.sh 를 수정한다. 

       211_config.sh 파일이 업그레이드된 경우 백업한 파일을 참고하여 수정한다. 

       211_config.sh 파일이 업그레이드되지 않은 경우 백업한 파일을 복사한다. 
          cp /tmp/mnt/usb/211_config.sh /tmp/mnt/usb/scripts/211_config.sh 


    9. 스크립트에 실행 권한 추가
       chmod -R 755 /tmp/mnt/usb/scripts/*


    10. 최초 설치인 경우 USB메모리가 mount되면 자동으로 usb_mount.sh 스크립트를 실행하도록 설정하게 하는 스크립트를 실행한다. 
        bash /tmp/mnt/usb/scripts/211_usb_use.sh
    
    11. 공유기를 리부팅 한다.  
        reboot

    12. 이제 부팅시 USB메모리가 mount 된 후에 자동으로
       /tmp/mnt/usb/scripts/usb_mount.sh  스크립트가 실행된다.

    13. ssh 로 접속하여 ps명령으로 usb_mount.sh 에 설정한 동작이 잘 실행되어 있는지 확인한다. 



    원복 : 원복방법, 스크립트를 사용하지 않게 하기
        cd /tmp/mnt/usb/scripts
        bash 211_usb_not_use.sh

        WIFI 지역을 수정한 경우 WEB 설정화면에서 원하는 지역을 선택한다.
        공유기 설정에서 공유기를 재부팅한다.




무선 신호 강도 확인 방법

wl -i $(nvram get wl0_ifname) txpwr_target_max

wl -i $(nvram get wl1_ifname) txpwr_target_max


