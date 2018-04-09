***shell脚本注释***
***ftp.sh***



***FTP 是File Transfer Protocol（文件传输协议）的英文简称，***
***而中文简称为“文传协议”。用于Internet上的控制文件的双向传输***

***未学透，备份文件***

#! /bin/bash

vsftpd_op()
{
    local cmd=""												#申明局部变量
    local operation=$1											#operation变量为操作类型，例如：查看状态，启动，停止
    local log_file="vsftpd.log"

    #case distro in 
    #add $ liucaili 20170505
    case $distro in
        "ubuntu" | "debian" )
            cmd="service vsftpd $operation"
            echo "$cmd" | tee ${log_file}
            $cmd | tee ${log_file}
            ;;
        * )
            #cmd="${operation}_service vsftpd"
            cmd="systemctl ${operation} vsftpd.service"			#设置cmd 为vsftpd系统服务控制命令，操作
            echo "$cmd" | tee ${log_file}						#运行系统服务并将运行消息输入到日志文件和输出到屏幕
           #eval \$$cmd | tee ${log_file}
            ;;
    esac
}

vsftpd_execute()
{
    local operation=$1											#定义第一个参数为操作动作
    vsftpd_op $operation										#调用vsftpd_op方法操作vsftpd，

    if [ 0 -ne $? ]; then										#判断执行状态
        echo "vsftpd $operation failed"
        lava-test-case vsftpd-$operation --result fail
    else
        echo "vsftpd $operation pass"
        lava-test-case vsftpd-$operation --result pass
    fi
}

set -x															#设定为调试模式

cd ../../../../utils
    . ./sys_info.sh
    . ./sh-test-lib
cd -
#distro=`cat /etc/redhat-release | cut -b 1-6`
case $distro in
    "ubuntu")
        #apt-get install vsftpd -y
        #apt-get install expect -y
        pkgs="vsftpd expect"									#设定要安装的包
        install_deps "${pkgs}"									#安装包
        print_info $? install-package							#验证是否安装成功
        ;;
    "centos")
        #yum install vsftpd -y
        #yum install vsftpd.aarch64 -y
        #yum install expect -y
        #yum install ftp -y
        pkgs="vsftpd expect ftp vsftpd.aarch64"
        install_deps "${pkgs}"
        print_info $? install-package
        ;;
esac

# test case -- start, stop, restart
vsftpd_execute start											#调用vsftpd_execute方法启动vsftpd并查看启动是否成功
vsftpd_execute restart											#调用vsftpd_execute方法重启vsftpd并查看重启是否成功
vsftpd_execute stop												#调用vsftpd_execute方法停止vsftpd并查看停止是否成功
#process=$(vsftpd_op status | grep "running")
#if [ "$process"x != ""x  ]; then
 #   vsftpd_op stop
#fi

FTP_PUT_LOG=ftp_put_test.log
FTP_GET_LOG=ftp_get_test.log
if [ "$distro"x = "centos"x ] ;
then
	FTP_USERS=/etc/vsftpd/ftpusers								#根据发行版型号，指定ftp用户目录以及ftp服务的配置文件目录
	VSFTPD_CONF=/etc/vsftpd/vsftpd.conf
else
	FTP_USERS=/etc/ftpusers
	VSFTPD_CONF=/etc/vsftpd.conf
fi

if [ ! -e ${FTP_USERS}.origin ];
then
    cp ${FTP_USERS}{,.origin}									#如果.origin文件不存在，则从源目录复制并创造一个源文件的副本.origin
else
    cp ${FTP_USERS}{.origin,}									#如果.origin文件存在，将.origin文件复制到ftp_users目录
fi

if [ ! -e ${VSFTPD_CONF}.origin ];
then
    cp ${VSFTPD_CONF}{,.origin}									#
else
    cp ${VSFTPD_CONF}{.origin,}
fi																#备份配置文件，

# prepare for the put and get test and the ftp home is ~/
mkdir tmp && cd tmp
echo 'For ftp put testing' > $FTP_PUT_LOG
echo 'For ftp get testing' > ~/$FTP_GET_LOG

sed -i 's/root/#root/g' $FTP_USERS
sed -i 's/listen=NO/listen=YES/g' $VSFTPD_CONF
sed -i 's/listen_ipv6=YES/#listen_ipv6=YES/g' $VSFTPD_CONF
sed -i 's/#write_enable=YES/write_enable=YES/g' $VSFTPD_CONF
sed -i 's/write_enable=NO/write_enable=YES/g' $VSFTPD_CONF
sed -i 's/userlist_enable=YES/userlist_enable=NO/g' $VSFTPD_CONF
if [ "$distro" == "ubuntu" ] ; then
    sed -i 's/pam_service_name=vsftpd/pam_service_name=ftp/g' $VSFTPD_CONF
fi

vsftpd_op restart
#add liucaili 20170516
sleep 5
vsftpd_op status
systemctl restart vsftpd.service
service restart vsftpd.service
# for get and put test
cd /root
#SELinux安全访问策略限制会导致550 Failed to open file的错误所以这里打开
setsebool -P allow_ftpd_full_access 1
cd -
EXPECT=$(which expect)
$EXPECT << EOF
set timeout 100
spawn ftp localhost
expect "Name"
send "\r"
expect "Password"																#注意如果登录失败，将影响后面的上传下载
send "root\r"
expect "ftp>"
#passive表示被动，ftp的工作模式有主动和被动解决"227 Entering Passive MOde"
send "passive\r"
expect "ftp>"
send "get ftp_get_test.log\r"
expect {
   "Transfer complete"
   {
       send "put ftp_put_test.log\r"
       expect "Transfer complete"
   }
   "Failed to open file"
   {
       send "put ftp_put_test.log\r"
       expect "Transfer complete"
   }
   "Connection refused"
   {
       send "put ftp_put_test.log\r"
       expect "Transfer complete"
   }
}
send "quit\r"
expect eof
EOF

if [ $(find . -maxdepth 1 -name "$FTP_GET_LOG")x != ""x ]; then
    lava-test-case vsftpd-download --result pass
else
    lava-test-case vsftpd-download --result fail
fi

cd -

cd ~

if [ $(find . -maxdepth 1 -name "ftp_put_test.log")x != ""x ]; then
    lava-test-case vsftpd-upload --result pass
else
    lava-test-case vsftpd-upload --result fail
fi

rm -rf tmp
case $distro in
    "ubuntu")
        #apt-get remove vsftpd expect -y
        remove_deps "${pkgs}"
        print_info $? remove-package
        ;;
    "centos")
        #yum remove vsftpd expect -y
        remove_deps "${pkgs}"
        print_info $? remove-package
        ;;
esac