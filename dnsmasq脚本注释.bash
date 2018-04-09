***shell脚本注释***
***dnsmasq.sh***
***DNSmasq是一个小巧且方便地用于配置DNS和DHCP的工具，***
***适用于小型网络，它提供了DNS功能和可选择的DHCP功能。***
***它服务那些只在本地适用的域名，这些域名是不会在全球的DNS服务器中出现的***





***学习未完全，待续，着重注意sed***




#!/bin/sh
# Author: mahongxin <hongxin_228@163.com>
set -x
cd ../../../../utils
. ./sys_info.sh
. ./sh-test-lib
cd -

#Test user id
if [ `whoami` != 'root' ]; then
    echo " You must be the superuser to run this script" >&2
    exit 1
fi
case $distro in
    "centos")
        #yum install dnsmasq -y
        #yum install bind-utils -y
        pkgs="dnsmasq bind-utils"
        install_deps "${pkgs}"
        print_info $? install-dnsmasq
        ;;
    "ubuntu")
        #apt-get install dnsmasq -y
        #apt-get install bind9 -y
        pkgs="dnsmasq bind9"
        install_deps "${pkgs}"
        print_info $? install-dnsmasq
        ;;
esac
DNSMASQ_CONF=/etc/dnsmasq.conf
cp /etc/dnsmasq.conf /etc/dnsmasq.conf_bak														#创建dnsmasq配置文件的备份文件
sed -i 's/#resolv-file=/resolv-file=\/etc\/resolv.dnsmasq.conf/g' $DNSMASQ_CONF
sed -i 's/#strict-order/strict-order/g' $DNSMASQ_CONF
sed -i 's/#addn-hosts=\/etc\/banner_add_hosts/addn-hosts=\/etc\/dnsmasq.hosts/g' $DNSMASQ_CONF
sed -i 's/#listen-address=/listen-address=127.0.0.1/g' $DNSMASQ_CONF
echo 'nameserver 127.0.0.1' > /etc/resolv.conf
touch /etc/resolv.dnsmasq.conf																	#创建resolv.dnsmasq.conf空文件
echo 'nameserver 119.29.29.29' > /etc/resolv.dnsmasq.conf										#覆盖内容到resolv.dnsmasq.conf文件
cp /etc/hosts /etc/dnsmasq.hosts																#复制hosts文件为dnsmasq.hosts
echo 'addn-hosts=/etc/dnsmasq.hosts' >> /etc/dnsmasq.conf										#追加内容到dnsmasq.conf
service dnsmasq start																			#启动dnsmasq服务
print_info $? start-dnsmasq																		#验证服务是否成功启动
dig www.freehao123.com																			#dig域名
print_info $? dig-wwwfree																		#验证是否dig解析成功

case $distro in
    "centos")
        #yum remove dnsmasq -y
        #yum remove bind-utils -y
        remove_deps "${pkgs}"
        print_info $? remove-pip
        ;;
    "ubuntu")
        #apt-get remove dnsmasq -y
        #apt-get remove bind9 -y
        remove_deps "${pkgs}"
        print_info $? remove-dnsmasq
        ;;
esac
sed -i 's/nameserver 127.0.0.1/nameserver 114.114.114.114/g' /etc/resolv.conf					#替换resolv.conf文件中的内容

