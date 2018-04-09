***shell脚本注释***
***network-basic.sh***

***基本网络指令执行的验证***




#!/bin/sh
#Author mahongxin <hongxin_228@163.com>
set -x																#调试脚本
. ../../../../utils/sys_info.sh
. ../../../../utils/sh-test-lib
cd -
# shellcheck disable=SC1091
#. ../../lib/sh-test-lib
#OUTPUT="$(pwd)/output"
#RESULT_FILE="${OUTPUT}/result.txt"
#export RESULT_FILE
INTERFACE="eth0"

#usage() {
#    echo "Usage: $0 [-s <true|false>] [-i <interface>]" 1>&2
#    exit 1
#}

#while getopts "s:i:" o; do
#  case "$o" in
 #   s) SKIP_INSTALL="${OPTARG}" ;;
 #   i) INTERFACE="${OPTARG}" ;;
  #  *) usage ;;
  #esac
#done

install() {
    pkgs="curl net-tools"
    install_deps "${pkgs}" "${SKIP_INSTALL}"
    print_info $? install-pkgs										#安装curl net-tools工具是否成功
}

run() {
    test_case="$1"
    test_case_id="$2"
    echo
    info_msg "Running ${test_case_id} test..."						#running print-network-statistics test
    info_msg "Running ${test_case} test..."							#running netstat -an test
    eval "${test_case}"
    check_return "${test_case_id}"
}

# Test run.
#create_out_dir "${OUTPUT}"

install

# Get default Route Gateway IP address of a given interface
GATEWAY=$(ip route list  | grep default | awk '{print $3}')			#找到网卡的ip

run "netstat -an" "print-network-statistics"
print_info $? netstat												#查看netstat是否成功运行
run "ip addr" "list-all-network-interfaces"
print_info $? ip-addr												#查看ip addr是否成功运行
run "route" "print-routing-tables"
print_info $? route													#查看route命令是否成功运行
run "ip link set lo up" "ip-link-loopback-up"						#ip link set 改变设备属性此处是更改网卡loopback口状态
print_info $? ip-link												#查看ip-link命令是否成功运行											
run "route" "route-dump-after-ip-link-loopback-up"
print_info $? route-dump											#查看在loopback打开后，route命令是否成功
run "ip link set ${INTERFACE} up" "ip-link-interface-up"
run "ip link set ${INTERFACE} down" "ip-link-interface-down"
print_info $? ip-link												#查看ip link set命令控制eth0设备的开关状态
run "dhclient -v ${INTERFACE}" "Dynamic-Host-Configuration-Protocol-Client-dhclient-v"
print_info $? dhclient												#获取eth0ip命令dhclient是否执行成功
run "route" "print-routing-tables-after-dhclient-request"
run "ping -c 5 ${GATEWAY}" "ping-gateway"
print_info $? ping-gateway											#查看ping命令能否执行成功
run "curl http://samplemedia.linaro.org/MPEG4/big_buck_bunny_720p_MPEG4_MP3_25fps_3300K.AVI -o curl_big_video.avi" "download-a-file"
print_info $? curl													#查看curl下载文件是否成功
#remove_deps "${pkgs}"
yum remove net-tools -y
print_info $? removse-pkgs											#卸载net-tools工具