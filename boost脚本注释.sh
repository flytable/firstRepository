***shell脚本注释***
***boost.sh***



#!/bin/sh
#Boots is a standard library for c++,portable,and available source code			Boots是一个用于c++、可移植和可用源代码的标准库
#Author mahongxin <hongxin_228@163.com>
set -x																			#设置为调试模式，每次执行的语句都会显示出来，+号
cd ../../../../utils															#切换到utils目录
. ./sys_info.sh																	#执行当前目录下的sys_info.sh脚本
cd -

#Test user id
if [ `whoami` != 'root' ]; then
    echo "You must be the superuser to run this script" >$2						#将信息输出保存到第二个参数
    exit 1																		#退出，并输出程序运行出错代号
fi
#distro=`cat /etc/redhat-release | cut -b 1-6`
case $distro in
    "centos")
        yum install gcc -y
        yum install gcc-c++ -y
        yum install wget -y														#安装以上三个依赖包，注意不同发行版安装命令不同，apt-get
        print_info $? install-package											#测试上述三个依赖包是否安装成功并输出测试结果信息
        wget http://htsat.vicp.cc:804/boost_1_63_0.tar.gz						#下载源码包
        print_info $? get-boost													#判断是否下载成功
        tar -zxf boost_1_63_0.tar.gz											#解压源码包
        print_info $? tar-boost													#判断是否解压成功
        cd boost_1_63_0															#切换到刚刚解压出来的目录boost_1_63_0下														
        sudo ./bootstrap.sh														#sudo执行bootstrap.sh脚本
        ./b2 install															#执行b2安装
        print_info $? install-boost
        ;;
esac
touch test_boost.cpp
chmod 777 test_boost.cpp
cat <<EOF >> test_boost.cpp
#include <boost/version.hpp>
#include <boost/config.hpp>
#include <boost/lexical_cast.hpp>
#include <iostream>
using namespace std;
int main()
{
    using boost::lexical_cast;
    int a=lexical_cast<int>("123456");
    double b=lexical_cast<double>("123.456");
    std::cout << a << std::endl;
    std::cout << b << std::endl;
    return 0;
}
EOF
g++ -Wall -o test_boost test_boost.cpp											#使用g++编译器编译.cpp文件为test_boost，-o参数表示指定输出文件名，-wall表示所有警告
./test_boost >> boost.log														#执行可运行文件，并将执行过程追加到boost.log文件
str=`grep -Po "123456" boost.log`												#检查是否输出打印了字符串"123456"
TCID="boost1.63.0 -test"
if [ "$str" != "" ]; then
    lava-test-case $TCID --result pass
else
    lava-test-case $TCID --result fail
fi
yum remove gcc gcc-c++ -y
print_info $? remove-gcc