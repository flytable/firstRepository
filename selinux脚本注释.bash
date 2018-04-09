***shell脚本注释***
***selinux.sh***


***SELinux 全称 Security Enhanced Linux (安全强化 Linux),是美国国家安全局2000年以 GNU GPL 发布，***
***是 MAC (Mandatory Access Control，强制访问控制系统)的一个实现,***
***目的在于明确的指明某个进程可以访问哪些资源(文件、网络端口等)***



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
getenforce
print_info $? selinux-state

setenforce 1
print_info $? off-seliunx

setenforce 0
print_info $? open-selinux