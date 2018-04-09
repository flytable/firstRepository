***shell脚本注释***
***prce.sh***

***PCRE(Perl Compatible Regular Expressions)是一个Perl库，包括 perl 兼容的正则表达式库。***
***这些在执行正规表达式模式匹配时用与Perl 5同样的语法和语义是很有用的。***
***Boost太庞大了，使用boost regex后，程序的编译速度明显变慢。测试了一下，同样一个程序，***
***使用boost::regex编译时需要3秒，而使用pcre不到1秒。因此改用pcre来解决C语言中使用正则表达式的问题***



#!/bin/bash
. ../../../../utils/sh-test-lib
. ../../../../utils/sys_info.sh
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
LOG_FILE="${OUTPUT}/log.txt"
SKIP_INSTALL="no"
VERSION="8.41"
SOURCE="Estuary"
! check_root && error_msg "This script must be run as root"										#检查是否为root用户
create_out_dir "${OUTPUT}"
install_pcre() {
    dist_name																					#执行当前系统版本判断方法
    # shellcheck disable=SC2154
    case "${dist}" in
      centos)
            install_deps "pcre gcc-c++" "${SKIP_INSTALL}"										#安装依赖库
            if test $? -eq 0;then
                echo "pcre install: [PASS]" | tee -a "${RESULT_FILE}"
            else
                echo "pcre install: [FAIL]" | tee -a "${RESULT_FILE}"
                exit 1
            fi
            print_info $? install-pcre															#判断是否安装成功
            version=$(yum info pcre | grep "^Version" | awk '{print $3}')						#截取镜像源pcre版本信息
            if [ ${version} = ${VERSION} ];then													#与已安装pcre比对版本
                echo "pcre version is ${version}: [PASS]" | tee -a "${RESULT_FILE}"
            else
                echo "pcre version is ${version}: [FAIL]" | tee -a "${RESULT_FILE}"

            fi
            print_info $? pcre-version															#测试pcre-version的版本
            sourc=$(yum info pcre | grep "^From repo" | awk '{print $4}')						#截取pcre的镜像源信息
            if [ ${sourc} = ${SOURCE} ];then													#比对pcre的镜像源信息
                echo "pcre source from ${version}: [PASS]" | tee -a "${RESULT_FILE}"
            else
                echo "pcre source from ${version}: [FAIL]" | tee -a "${RESULT_FILE}"

             fi
             print_info $? pcre-source															#比对pcre镜像源的结果
            ;;
      unknown) warn_msg "Unsupported distro: package install skipped" ;;
    esac
}
install_pcre																					#调用安装pcre的install方法
g++ -o pcre test_pcre.cpp -lpcre																#连接lpcre库编译test_pcre.cpp文件为pcre文件
if test $? -eq 0;then																			#判断是否编译成功
    echo "pcre build: [PASS]" | tee -a "${RESULT_FILE}"
    print_info $? compilation-cpp
else
    echo "pcre build: [FAIL]" | tee -a "${RESULT_FILE}"
fi
./pcre | tee -a "${LOG_FILE}"																	#执行pcre
print_info $? run-cpp																			#判断是否执行成功
 cat ${LOG_FILE} | grep "PCRE compilation pass"

 if [ $? -eq 0 ];then																			#regular-compilation正则表达编译是否成功
    echo "regular-compilation: [PASS]" | tee -a ${RESULT_FILE}
    print_info $? regular-comilation
else
    echo "regular-compilation: [FIAL]" | tee -a ${RESULT_FILE}
fi
#if [ cat ${LOG_FILE} | grep "OK, has matched" ];then
 cat ${LOG_FILE} | grep "OK, has matched"
 if [ $? -eq 0 ];then
    echo "regular-matches: [PASS]" | tee -a ${RESULT_FILE}
    print_info $? regular-matches																#判断正则表达的匹配功能
else
    echo "regular-matches: [FIAL]" | tee -a ${RESULT_FILE}
fi
 cat ${LOG_FILE} | grep "free ok"
 if [ $? -eq 0 ];then
    echo "regular-release: [PASS]" | tee -a ${RESULT_FILE}
    print_info $? regular-release
else
    echo "regular-release: [FIAL]" | tee -a ${RESULT_FILE}
fi
case $distro in
    "centos")
        yum remove  gcc-c++ -y
        print_info $? remove-pcre
        ;;
esac