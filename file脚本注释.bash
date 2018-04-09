***shell脚本注释***
***file.sh***

***基本的文件创建，读写，移动，删除功能***


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
touch test.sh														#创建test文件
print_info $? create-file

chmod 777 test.sh													#给test文件授予777权限
print_info $? chmod-file

echo "hello my test file" > test.sh									#写入内容到test文件
print_info $? write-file

cat test.sh															#将test文件内容读取到屏幕
print_info $? cat-file

mv test.sh test1.sh													#给test文件重命名
print_info $? rename-file

rm test1.sh															#删除test文件
print_info $? rm-file