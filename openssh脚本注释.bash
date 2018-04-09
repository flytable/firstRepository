***shell脚本注释***
***openssh.sh***



***OpenSSH 是 SSH （Secure SHell） 协议的免费开源实现。SSH协议族可以用来进行远程控制， 或在计算机之间传送文件。***
***OpenSSH是使用SSH透过计算机网络加密通讯的实现***




#! /bin/bash

set -x																	#调试模式

cd ../../../../utils
    . ./sys_info.sh
    . ./sh-test-lib
cd -
#distro=`cat /etc/redhat-release | cut -b 1-6`
case $distro in
    "ubuntu")
        #apt-get install openssh-server  -y
        #apt-get install expect -y
        pkgs="openssh-server expect"									#安装包
        install_deps "${pkgs}"
        print_info $? install-package
        ;;
    "centos")
        yum install openssh-server.aarch64 -y
        yum install expect -y
        print_info $? install-package
        ;;
    "opensuse")
        zypper install -y openssh
        zypper install -y expect
        print_info $? install-package
        ;;
esac

FTP_PUT_LOG=sftp_put_test.log
FTP_GET_LOG=sftp_get_test.log

# prepare for the put and get test and the ftp home is ~/
mkdir tmp && cd tmp
echo 'For ftp put testing' > $FTP_PUT_LOG
echo 'For ftp get testing' > ~/$FTP_GET_LOG
#测试ssh登录是否成功
EXPECT=$(which expect)
$EXPECT << EOF
set timeout 100
spawn ssh localhost														#建立ssh会话到localhost
#expect "Are you sure"
expect {
"*yes/no" { send "yes\r"; exp_continue }								
"*assword:" { send "root\r" }
}
#send "yes\n"
#expect "*assword:"
#send "root\n"
expect eof
EOF
print_info $? test-login												#测试登录结果
#for get and put test "EXPECT=$(which expect)
$EXPECT << EOF
set timeout 100
spawn sftp localhost
expect "(password|Password)"
send "root\r"
expect "sftp>"
send "get sftp_get_test.log\r"
expect "sftp>"
send "put sftp_put_test.log\r"
expect "sftp>"
send "quit\r"
expect eof
EOF
if [ $(find . -maxdepth 1 -name "$FTP_GET_LOG")x != ""x ]; then			#查看是否通过sftp下载到了文件
    lava-test-case sftp-download --result pass
else
    lava-test-case sftp-download --result fail
fi
cd -

cd ~

if [ $(find . -maxdepth 1 -name "sftp_put_test.log")x != ""x ]; then	#查看是否成功上传了文件
    lava-test-case sftp-upload --result pass
else
    lava-test-case sftp-upload --result fail
fi

rm -rf tmp																#删除tmp文件夹
case $distro in
    "ubuntu")
        apt-get remove expect openssh-server -y
        print_info $? remove-package
        ;;
    "centos")
        yum remove expect openssh-server -y
        print_info $? remove-package
        ;;
esac