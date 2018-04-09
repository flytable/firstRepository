***shell脚本注释***
***gtest.sh***

***gtest是一个谷歌单元测试工具***

***


#!/bin/sh
#gtest is Google's Unit test tool
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
fi																			#判断是不是root用户
#distro=`cat /etc/redhat-release | cut -b 1-6`
case $distro in
    "centos")
        #yum install gcc -y
        #yum install gcc-c++ -y
        #yum install git -y
        #yum install make -y
        pkgs="gcc gcc-c++ git make"
        install_deps "${pkgs}"
        git clone https://github.com/google/googletest.git
        print_info $? install-gtest											#安装依赖包，并下载googletest仓库
        ;;
esac
cp Makefile googletest/googletest/samples									#
cd googletest/googletest/samples
make
./run_test
print_info $? compile-gtest													#运行测试，并查看编译结果，看是否能够正常编译gtest
touch sqrt.h																#创建库文件
chmod 777 sqrt.h															
touch sqrt.cpp																#创建源文件
chmod 777 sqrt.cpp
touch sqrt_unittest.cpp
chmod 777 sqrt_unittest.cpp
cat << EOF >> ./sqrt.h
#ifndef _SQRT_H_
#define _SQRT_H_
int sqrt(int x);
#endif //_SQRT_H_
EOF

cat << EOF >> ./sqrt.cpp
#include "sqrt.h"
int sqrt(int x) {
    if(x<=0) return 0;
    if(x==1) return 1;
    int small=0;
    int large=x;
    int temp=x/2;
    while(small<large){
        int a = x/temp;
        int b = x/(temp+1);
        if (a==temp) return a;
        if (b==temp+1) return b;
        if(temp<a && temp+1>b){
            return temp;
        }
        else if(temp<a && temp+1<b){
            small=temp+1;
            temp = (small+large)/2;
        }else {
            large = temp;
            temp = (small+large)/2;
        }
    }
    return -1;
}
EOF

cat <<EOF >> ./sqrt_unittest.cpp
#include "sqrt.h"
#include "gtest/gtest.h"
TEST(SQRTTest,Zero){
    EXPECT_EQ(0,sqrt(0));
}
TEST(SQRTTest,Positive){
    EXPECT_EQ(100,sqrt(10000));
    EXPECT_EQ(1000,sqrt(1000009));
    EXPECT_EQ(99,sqrt(9810));
}
TEST(SQRTTest,Negative){
    int i=-1;
    EXPECT_EQ(0,sqrt(i));
}
EOF
make clean													#清除上次的make命令所产生的object文件（后缀为“.o”的文件）及可执行文件。
make
print_info $? compile-cpp									#查看cpp文件编译结果,查看是否能够编译测试文件
./run_test
print_info $? run-cpp										#查看cpp运行结果，查看编译后的测试文件是否能够运行
file1="./sqrt.o"
file2="./sqrt_unittest.o"
TCID="gtest-testing"
if [ -f "$file1" ] && [ -f "$file2" ];then					#查看编译出来的文件是否为常规文件，查看是否正常结束了测试，依据此二进制文件是否正常生成
    lava-test-case $TCID --result pass
else
    lava-test-case $TCID --result fail
fi
case $distro in
    "centos")
        #yum remove gcc gcc-c++ git make  -y
        remove_deps "${pkgs}"
        print_info $? remove-pkgs
        ;;
esac