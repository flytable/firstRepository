***shell脚本注释***
***odp.sh***


***odp概念未学透，待续。。。***




# Copyright (C) 2017-11-08, Linaro Limited.
# Author: mahongxin <hongxin_228@163.com>
# Test user idcd -  bandwidth and latencyqperf is a tool for testing

#!/bin/sh
set -x

cd ../../../../utils

 . ./sys_info.sh
. ./sh-test-lib
cd -

if [ `whoami` != 'root' ] ; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi
case $distro in
"centos")
     yum install wget -y
     yum install CUnit-devel.aarch64 -y
     yum install libatomic.aarch64 -y
     print_info $? install-pkgs											#安装依赖工具包
     wget http://htsat.vicp.cc:804/centos_odp.tar.gz					#下载odp压缩包
     tar xf centos_odp.tar.gz											#解压压缩包
     ./centos_redhat_fedora/run-test.sh > odp.log						#执行压缩文件中的runtest脚本并输出执行过程到odp.log

     ;;
 "ubuntu")
     apt-get install libcunit1-dev -y
     print_info $? install-pkgs
     wget http://htsat.vicp.cc:804/debian_odp.tar.gz
     tar xf debian_odp.tar.gz
     ./debian_odp/run-test.sh > odp.log									#执行测试脚本，并输出到odp.log文件中
     ;;
esac

grep "_test" odp.log > 1.log											#从odp.log中匹配出_test的行覆盖到1.log
grep "test_in_ip" odp.log >> 1.log										#从odp.log中匹配出test_in_ip的行追加到1.log
awk '{print $2,$3}' 1.log > 2.log										#从1.log中截取第2和第3列覆盖到2.log
sed 's/\...//g' 2.log > 3.log											#使用sed工具去除掉2.log中的...

while read line															#从3.log中循环取出内容赋给变量并作判断
do
    str1=`echo $line |awk -F ' ' '{print $1}'`
    str2=`echo $line |awk -F ' ' '{print $2}'`
    if [ "$str2" == "passed" ];then
        str2=pass
    lava-test-case $str1 --result $str2
    else
        str2=fail
   fi
#lava-test-case $str1 --result $str2
done < 3.log