***shell脚本注释***
***busybox.sh***






#!/bin/sh
# Busybox smoke tests.

# shellcheck disable=SC1091
set -x																	#调试模式
cd ../../../../utils													#切换到utils目录
    . ./sys_info.sh
    . ./sh-test-lib
cd -																	#切换到脚本所在目录
#Test user id
if [ `whoami` != 'root' ]; then											#判断是不是root用户
    echo "You must be the superuser to run this script" >&2
    exit 1
fi

case $distro in
    "centos")
        #yum install gcc -y
        #yum install make -y
        #yum install bzip2 -y
        #yum install wget -y
        pkgs="gcc make bzip2 wget"										#设定统一变量
        install_deps "${pkgs}"											#安装gcc，make，bizp2，wget包
        wget https://busybox.net/downloads/busybox-1.27.2.tar.bz2		#通过wget工具下载busybox
        print_info $? download-busybox
        tar -jxf busybox-1.27.2.tar.bz2									#解压busybox包
        print_info $? tar-busybox

        cd busybox-1.27.2/												#切换到busybox-1.27.2目录
        make defconfig													#arch/arm/defconfig是一个缺省的配置文件，
																		#make defconfig时会根据这个文件生成当前的.config，注意是.config为隐藏文件
        make															#编译
        print_info $? make-busybox										#判断编译是否成功
        ;;
esac
case $distro in
    "centos")
     commond="./busybox"												#设定执行命令
     ;;
    "debian")
     commond="busybox"
     ;;
esac

$commond pwd															#busybox执行pwd命令
print_info $? busybox-pwd


$commond mkdir dir
print_info $? busybox-mkdir

$commond touch dir/file.txt
print_info $? busybox-touch

$commond ls dir/file.txt
print_info $? busybox-ls

$commond cp dir/file.txt dir/file.txt.bak
print_info $? busybox-cp

$commond rm dir/file.txt.bak
print_info $? busybox-rm

$commond echo 'busybox test' > dir/file.txt
print_info $? busybox-echo

$commond cat dir/file.txt
print_info $? busybox-cat

$commond grep 'busybox' dir/file.txt
print_info $? busybox-grep

# shellcheck disable=SC2016
$commond awk '{printf("%s: awk\n", $0)}' dir/file.txt
print_info $? busybox-awk

$commond free
print_info $? busybox-free

$commond df
print_info $? busybox-df

case $distro in
    "centos")
     #yum remove gcc -y
     #yum remove make -y
     #yum remove bzip2 -y
     remove_deps "${pkgs}"												#卸载已经安装的gcc ，make,bzip2
     print_info $? remove-package
     ;;
esac
