***shell脚本注释***
***dns.sh***
***DNS是域名解析，有正向解析和逆向解析。。。正向解析：通过域名查找ip；逆向解析：通过ip查找域名***

***未完全学透，待续。。。。为学透部分为：sed以及正向解析和逆向解析***




#!/bin/sh
#DNS is the server responsibel for domain name resolution
#Author:mahongxin <hongxin_228@163.com>
set -x																										
cd ../../../../utils
. ./sys_info.sh
. ./sh-test-lib
cd -
#Test user id
if [ `whoami` != 'root' ]; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi

case $distro in
    "centos")
        #yum install bind -y
        #yum install bind-utils -y
        pkgs="bind bind-utils"
        install_deps "${pkgs}"
        print_info $? install-package
        ;;
esac
chmod 777 /etc/named.conf																#设置named.conf最高权限
sed -i 's/127.0.0.1/any/g' /etc/named.conf											#更改named.conf文件中，所有127.0.0.1为any
sed -i 's/localhost/any/g' /etc/named.conf												#将named.conf文件中，所有localhost替换为any
sed -i '42a zone "example.com" IN\{ \ntype master; \nfile "example.com.zone";\n\};\		
zone "realhostip.com" IN \{ \ntype master; \nfile "named.realhostip.com";\n\};' /etc/named.rfc1912.zones  #在42行后插入
cp -p /var/named/named.localhost /var/named/example.com.zone							#将named.localhost复制为named目录下example.com.zone,-p参数表示保留源文件属性

cat << EOF > /var/named/example.com.zone												#给example.com.zone文件覆盖内容
\$TTL  1D
@       IN    SOA    server1.example.com. root.invalid. (
                        20160614      ; serial
                        1D           ; refresh
                        1H           ; retry
                        1W           ; expire
                        3H )         ; minimum
          NS    server1.example.com.
server1   A     127.0.0.1
www       AAAA  ::1
bbs       CNAME news.example.com.
news      A     192.168.1.70
example.com.    MX 1       192.168.1.70.
EOF
chmod 777 /var/named/example.com.zone												#给example.com.zone文件授予777权限

cat << EOF >> /var/named/named.realhostip.com										#给named.realhostip.com文件追加内容
\$TTL 1D
@       IN    SOA    realhostip.com. rname.invalid. (
                        0               ;  serial
                        1D              ;  refresh
                        1H              ;  retry
                        1W              ;  expire
                        3H )            ;  minimum
       NS     @
       A      127.0.0.1
       AAAA   ::1
192-168-1-70  IN A       192.168.1.70
192-168-1-80  IN A       192.168.1.80
EOF
chmod 777 /var/named/named.realhostip.com											#给named.realhostip.com文件授予777权限
board_ip=`ip addr |grep "inet 192"|cut -c10-22|head -1`								#截取到板子的ip地址、比如：192.168.1.233/24
sed -i "2i\\nameserver ${board_ip}" /etc/resolv.conf								#在第二行之前，插入nameserver board_ip
systemctl restart named.service														#重启named.service服务，systemctl系统服务管理命令
print_info $? restart-dns															#判断是否执行成功
dig 192-168-1-70.realhostip.com 2>&1 | tee dig.log									#正向解析：
print_info $? forward-test
dig -t mx example.com 2>&1 |tee dig1.log											#反向解析；
print_info $? reverse-test
throu1=`grep -Po "192.168.1.70" dig.log`											#设置判断条件变量
throu2=`grep -Po "server1.example.com." dig1.log`									#设置判断条件变量
TCID1="DNS forward direction "
TCID2="DNS reverse "
if [ "$throu1" != "" ]; then
    lava-test-case $TCID --result pass
else
    lava-test-case $TCID --result fail
fi
if [ "$throu2" != "" ]; then
    lava-test-case $TCID2 --result pass
else
    lava-test-case $TCID2 --result fail
fi
case $distro in
    "centos")
        #yum remove bind bind-utils -y
        remove_deps "${pkgs}"
        print_info $? remove-package
        ;;
esac



#	'42a zone "example.com" IN\{ \ntype master; \nfile "example.com.zone";\n\};\
#	zone "realhostip.com" IN \{ \ntype master; \nfile "named.realhostip.com";\n\};'


#	42a
#	zone "example.com" IN{ 
#	type master; 
#	file "example.com.zone";
#	};zone "realhostip.com" IN { 
#	type master; 
#	file "named.realhostip.com";
#	};'