***shell脚本注释***
***dhcp.sh***
***dhclient命令使用动态主机配置协议动态的配置网络接口的网络参数，DHCP是动态IP地址分配***




#!/bin/sh
#gtest is Google's Unit test tool
# Author: mahongxin <hongxin_228@163.com>
set -x																			#调试模式，输出打印每一条语句以及执行结果													
cd ../../../../utils
. ./sys_info.sh
. ./sh-test-lib																	#初始化测试工具
cd -

#Test user id
if [ `whoami` != 'root' ]; then													#判断是否为root用户
    echo " You must be the superuser to run this script" >&2
    exit 1
fi
#distro=`cat /etc/redhat-release | cut -b 1-6`
case $distro in
    "centos")
        #yum install dhclient.aarch64 -y
        pkgs="dhclient"
        install_deps "${pkgs}"
        print_info $? install-package											#安装dhcp客户端
        ;;
    "ubuntu")
        #apt-get install dhclient -y
        pkgs="dhclient"
        install_deps "${pkgs}"
        print_info $? install-package
        ;;

esac
ROUTE_ADDR=$(ip route list |grep default |awk '{print $3}' |head -1)			#设置变量route_addr，ip route list打印路由表
dhclient -v -r eth0
ping -c 5 ${ROUTE_ADDR}															#ping 5次route_addr这个地址
print_info $? delete-ip															#查看删除ip是否成功

dhclient -v eth0																#启动dhclient 并设置为-v模式，捕获eth0设备的ip
print_info $? acquiring-ip														#捕获ip是否成功
ping -c 5 ${ROUTE_ADDR} 2>&1 |tee dhcp.log										#ping ROUTE_ADDR地址，并只接受5次返回，并且将输出打印到dhcp.log

str=`grep -Po "64 bytes" dhcp.log`												#匹配dhcp.log中是否有 64 bytes
TCID="dhcp test"

if [ "$str" != "" ];then
    lava-test-case $TCID --result pass
else
    lava-test-case $TCID --result fail											#将测试结果写入CI
fi