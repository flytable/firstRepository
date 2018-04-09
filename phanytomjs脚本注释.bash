***shell脚本注释***
***phanytomjs.sh***



***PhantomJS 是一个基于 WebKit 的服务器端 JavaScript API。***
***它全面支持web而不需浏览器支持，其快速，原生支持各种Web标准：***
***DOM 处理, CSS 选择器, JSON, Canvas, 和 SVG。 PhantomJS***
***可以用于 页面自动化 ， 网络监测 ， 网页截屏 ，以及 无界面测试 等***





# Copyright (C) 2017-11-08, Linaro Limited.
# Author: mahongxin <hongxin_228@163.com>
# Test user idcd -  bandwidth and latencyqperf is a tool for testing

#!/bin/sh
set -x																			#调试模式

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
     yum install phantomjs -y
     print_info $? install-phantomjs
     ;;
 "ubuntu")
     apt-get install phantomjs -y
     print_info $? install-phantomjs
     ;;
esac

#验证截图功能
phantomjs ./a.js																#phantomjs执行a.js文件
print_info $? phantomjs-screenshots

#验证hello world功能
phantomjs ./hello.js 2>&1 | tee phantomjs.log									#执行hello.js文件
print_info $? phantomjs-helloword												#验证是否执行成功

#验证传递参数功能
phantomjs ./arguments.js foo bar baz 2>&1 |tee -a  phantomjs.log
print_info $? phantomjs-parameters

#加载页面的时间
phantomjs ./loadspeed.js https://www.baidu.com 2>&1 | tee -a phantomjs.log
print_info $? phantomjs-loadingpage

#获取到百度的标题
phantomjs ./title.js 2>&1 | tee -a phantomjs.log
print_info $? phantomjs-title

case $distro in
    "centos")
        yum remove phantomjs -y
        print_info $? remove-phantomjs
        ;;
    "ubuntu")
        apt-get remove phantomjs -y
        print_info $? remove-phantomjs
        ;;
esac