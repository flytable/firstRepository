***shell脚本注释***
***compilation.sh***d


*** ***


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
        yum install gcc -y
        print_info $? install-package
        ;;
esac
cat <<EOF >> ./main.c
#include <stdio.h>
int main()
{
    printf("hello world\n");
    return 0;
}
EOF
gcc main.c
print_info $? compilation-file

./a.out
print_info $? run-file
case $distro in
    "centos")
        yum remove gcc -y
        print_info $? remove-package
        ;;
esac