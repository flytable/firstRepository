***shell脚本注释***
***snappy.sh***



***Snappy 是一个 C++ 的用来压缩和解压缩的开发包。***
***其目标不是最大限度压缩或者兼容其他压缩格式，而是旨在提供高速压缩速度和合理的压缩率。***




#!/bin/sh
# Copyright (C) 2017-8-29, Linaro Limited.
#qperf is a tool for testing bandwidth and latency
# Author: mahongxin <hongxin_228@163.com>

set -x

cd ../../../../utils
    . ./sys_info.sh
    . ./sh-test-lib
cd -

# Test user id
if [ `whoami` != 'root' ] ; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi
case $distro in
    "centos")
        yum install snappy.aarch64 -y
        yum install gcc-c++ -y
        yum install libtool -y
        print_info $? install-snappy
         ;;
esac
cat <<EOF >>./a.cpp
#include "snappy.h"
#include <string>
#include <iostream>
int main(){
        std::string s = "ddslkfslkdf;lfksjdlf;sdlkfjlsd;sdflkjl";
        std::string d;
        snappy::Compress(s.data(),s.size(),&d);
        std::cout<<d<<std::endl;
        std::cout<<s.size()<<""<<d.size()<<std::endl;
        return 0;
}
EOF
libtool --mode=compile g++ -c a.cpp
libtool --mode=link g++ -o test a.lo /usr/lib64/libsnappy.so.1
print_info $? compile-gcc
./test >> snappy.log
print_info $? run-cpp
TCID="snappy-test"
str=`grep -Po "error" snappy.log`
if [ "$str" != "" ] ; then
    lava-test-case $TCID --result fail
else
    lava-test-case $TCID --result pass
fi
rm snappy.log
print_info $? end-test
case $distro in
    "centos")
        yum remove snappy.aarhc64 -y
        yum remove gcc-c++ libtool -y
        print_info $? remove-pkg
        ;;
esac
