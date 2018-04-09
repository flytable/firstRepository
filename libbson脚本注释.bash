***shell脚本注释***
***libbson.sh***


***MongoDB内部用于数据消息序列化的而开发的子模块***
***未完全学习透彻，待续。。。***


#!/bin/bash
. ../../../../utils/sh-test-lib														#在当前进程加载sh-test-lib
. ../../../../utils/sys_info.sh														#在当前进程加载sys_info.sh
OUTPUT="$(pwd)/output"																#当前路径下output
RESULT_FILE="${OUTPUT}/libbson.txt"
LOGFILE="${OUTPUT}/compilation.txt"
export RESULT_FILE																	#将result_file加入当前环境变量
pkgcf="https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz"
install_pkg-config(){
    wget ${pkgcf}
    tar xzf pkg-config-0.29.2.tar.gz
    cd pkg-config-0.29.2
    ./configure --with-internal-glib
    cd ${OUTPUT} 																	#切换到目录
}
usage() {
    echo "Usage: $0  [-s true|false]" 1>&2
    exit 1
}

while getopts "s:h" o; do															#getopts表示后面的字串为参数，o为变量作为case选项
    case "$o" in
        s) SKIP_INSTALL="${OPTARG}" ;;
        h|*) usage ;;
    esac
done
! check_root && error_msg "You need to be root to install packages!"
create_out_dir "${OUTPUT}"															#创建目录
cd "${OUTPUT}"																		#切换到目录
dist_name																			#前面的. sh-test-lib将该方法加载到了当前进程，所以方法产生的变量存在于当前进程
case "${dist}" in
    centos) 
            version="1.6.2"
            SOURCE="Estuary"
            pkgs="libbson libbson-devel"
            install_deps "${pkgs}" "${SKIP_INSTALL}"
            print_info $? install-libbson-devel
            print_info $? install-libbson
            v=$(yum info libbson | grep "^Version" | awk '{print $3}')
            if [ $v = ${version} ];then
                echo "libbson version is $v: [PASS]" | tee -a "${RESULT_FILE}"
            else
                echo "libbson version is $v: [FAIL]" | tee -a "${RESULT_FILE}"
            fi
            print_info $? libbson-version											#libbson-version版本检查
            s=$(yum info libbson | grep "^From repo" | awk '{print $4}')
            if [ $s = ${SOURCE} ];then
                echo "libbson source is $s: [PASS]" | tee -a "${RESULT_FILE}"
            else
                echo "libbson source is $s: [FAIL]" | tee -a "${RESULT_FILE}"
            fi
            print_info $? libbson-source											#检查libbson安装源是否正确

            v=$(yum info libbson-devel | grep "^Version" | awk '{print $3}')
            if [ $v = ${version} ];then
                echo "libbson-devel version is $v: [PASS]" | tee -a "${RESULT_FILE}"
            else
                echo "libbson-devel version is $v: [FAIL]" | tee -a "${RESULT_FILE}"
            fi
            print_info $? libbson-dever-version										#检查libbson-devel版本是否正确
            s=$(yum info libbson-devel | grep "^From repo" | awk '{print $4}')
            if [ $s = ${SOURCE} ];then
                echo "libbson-devel source is $s: [PASS]" | tee -a "${RESULT_FILE}"
            else
                echo "libbson-devel source is $s: [FAIL]" | tee -a "${RESULT_FILE}"
            fi
            print_info $? libbson-devel-source										#检查libbson-devel安装源是否正确
            ;;
esac
install_pkg-config
print_info $? install-pkg-config													#检查安装pkg-config是否正确
cp ../hello_bson.c .																#拷贝上级目录的hello_bson.c到当前目录下
gcc -o hello_bson hello_bson.c $(pkg-config --cflags --libs libbson-1.0 ) | tee "${LOGFILE}"	#gcc编译该文件输出为hello_bson
print_info $? complie-cpp															#查看是否编译成功
command="./hello_bson | grep  'bson'"
skip_list="execute_binary"
run_test_case "${command}" "${skip_list}"
print_info $? run-bson																#检查bson是否正常运行
remove_pkg "${pkgs}"
print_info $? remove-bson															#卸载bson
rm -rf pkg-config-0.29.2
print_info $? remove-pkg															#卸载pkg