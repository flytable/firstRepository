***shell脚本注释***
***samba.sh***


***Samba，是在Unix上实现SMB(Server Message Block)的一个工具套件。而SMB通常是windows***
***用来实现共享的，包括文件和打印机等。而Unix上装上SMB，则使得Unix能够和windows连接在一起，***
***实现两者的资源互通。***


#! /bin/bash

set -x

cd ../../../../utils
    . ./sys_info.sh
cd -
#distro=`cat /etc/redhat-release | cut -b 1-6`
case $distro in
    "ubuntu")
          apt-get install samba -y						#安装samba包，并安装以下依赖包
          apt-get install smbclient -y
          apt-get install expect -y
          apt-get install selinux-utils -y
          print_info $? install-package
          ;;
    "centos")
          yum install samba -y
          yum install samba-client.aarch64 -y
          yum install expect -y
          print_info $? install-package
          ;;
     "opensuse")
          zypper install -y samba
          ;;
esac
case $distro in
    "ubuntu")										

         systemctl start samba							#测试能否启动、重启、停止samba服务
         print_info $? start_smb
         systemctl restart samba
         print_info $? restart_smb
         systemctl stop samba
         ;;
    "centos")
         systemctl restart nmb.service smb.service
         print_info $? restart_smb
         systemctl start nmb.service smb.service
         print_info $? start_smb
         systemctl stop nmb.service smb.service
         print_info $? stop_smb
         ;;
esac

SMB_CONF=/etc/samba/smb.conf
if [ ! -e ${SMB_CONF}.origin ];
then
    cp ${SMB_CONF}{,.origin}
else
    cp ${SMB_CONF}{.origin,}							#备份samba的配置文件
fi

cat << EOF >> /etc/samba/smb.conf
[share]
    comment = Anonymous share
    path = /home/share
    public = yes
    browsable =yes
    writable = yes
    guest ok = yes
    read only = no
EOF

setenforce 0									#setenforce是Linux的selinux防火墙配置命令 执行setenforce 0 （permissive）表示关闭selinux防火墙。
												#setenforce命令是单词set（设置）和enforce(执行)连写，另一个命令getenforce可查看selinux的状态。
SMB_ROOT=/home
mkdir -p $SMB_ROOT/share						#创建/share目录
cd $SMB_ROOT
chmod -R 0755 share/							#该用户对share有rwx权限，组用户有rx权限，其他用户有rx权限
#case $distro in
 #   "ubuntu" | "debian")
  #       chown -R nobody:nogroup share/
   #      ;;
    # * )
     #    chown -R nobody:nobody share/
      #   ;;
#esac

systemctl restart samba
systemctl restart nmb.service smb.service
groupadd smbgrp
useradd smb -G smbgrp							#添加smb用户到用户组smbgrp

EXPECT=$(which expect)
$EXPECT << EOF
set timeout 100
spawn smbpasswd -a smb
expect "New SMB password:"
send "smb\r"
expect "Retype new SMB password:"
send "smb\r"
expect eof
EOF
print_info $? smb_add_user						#测试用户添加是否成功

mkdir -p $SMB_ROOT/secured
cd $SMB_ROOT
chmod -R 0777 secured/
chown -R smb:smbgrp secured/

#cat << EOF >> /etc/samba/smb.conf
#[secured]
 #   comment = Secured share
  #  path = /srv/samba/secured
   # valid users = @smbgrp
    #guest ok = no
    #writable = yes
    #browsable = yes
#EOF
chmod 777 /home/share
systemctl restart samba
systemctl restart nmb.service smb.service
SMB_GET_LOG=smb_get_test.log
SMB_PUT_LOG=smb_put_test.log
chmod 777 $SMB_PUT_LOG
chmod 777 $SMB_GET_LOG
cd share
echo 'For samba get testing' > $SMB_GET_LOG
cd /root/test-definitions/auto-test/distributions/distribution/samba
echo 'For samba put testing' > $SMB_PUT_LOG

EXPECT=$(which expect)
$EXPECT << EOF
set timeout 10
spawn testparm
expect "Press enter to see"
send "\r"
expect eof
EOF
print_info $? test_parm

EXPECT=$(which expect)
$EXPECT << EOF
set timeout: 10
spawn smbclient //localhost/share
expect "password:"
send "smb\r"
expect "smb: \> "
send "get smb_get_test.log\r"
expect "getting"
send "put smb_put_test.log\r"
expect "putting"
send "exit\r"
expect eof
EOF
print_info $? anony_test_share


EXPECT=$(which expect)
$EXPECT << EOF
set timeout 10
spawn smbclient //localhost/secured -U user
expect "password:"
send "\r"
expect "tree connect failed"
EOF
print_info $? anony_test_secured

#EXPECT=$(which expect)
#$EXPECT << EOF
#set timeout 10

#spawn smbclient //localhost/secured -U smb
#expect "password:"
#send "smb\r"
#expect "smb: \> "
#send "ls\r"
#expect "available"
#send "quit\r"
#expect eof
#EOF
#print_info $? group_test_secured


if [ $(find . -maxdepth 1 -name "$SMB_GET_LOG")x != ""x ]; then
    lava-test-case samba-download --result pass
else
    lava-test-case samba-download --result fail
fi

cd $SMB_ROOT/share

if [ $(find . -maxdepth 1 -name "$SMB_PUT_LOG")x != ""x ]; then
    lava-test-case samba-upload --result pass
else
    lava-test-case samba-upload --result fail
fi

cd -

cd ..

rm -rf share
count = `ps -aux |grep samba |wc -l`
if [ $count -gt 0 ];then
    kill -9 $(pidof samba)
    print_info $? kill-samba
fi
case $distro in
    "centos")
     yum remove samba smbclient expect selinux-utils -y
     print_info $? remove-package
     ;;
 "ubuntu")
    apt-get remove samba samba-client.aarch64 expect -y
    print_info $? remove-package
    ;;
esac