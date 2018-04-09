***shell脚本注释***
***pip.sh***


***pip 是一个现代的，通用的 Python 包管理工具。提供了对 Python 包的查找、下载、安装、卸载的功能***




#!/bin/sh
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
fi
case $distro in
    "centos")
        yum install python2-pip.noarch -y
        print_info $? install-pip
        ;;
    "ubuntu")
        apt-get install python-pip -y
        print_info $? install-pip
        ;;
esac
pip install -U pip														#升级pip
print_info $? pip-update
pip install requests													#安装requests包
print_info $? pip-install-package
pip uninstall requests -y												#卸载requests包
print_info $? pip-remove-package
pip list																#列出已经安装的包
print_info $? pip-list
pip list --outdated														#查看待更新的包
print_info $? pip-list-outdate
pip install --upgrade anymarkup											#升级标记语言解析包
print_info $? pip-upgrade
pip show anymarkup														#查看包的信息
print_info $? pip-show
pip search "jquery"
print_info $? pip-search

case $distro in
    "centos")
        yum remove python2-pip -y
        print_info $? remove-pip
        ;;
    "ubuntu")
        apt-get remove python-pip -y
        print_info $? remove-pip
        ;;
esac