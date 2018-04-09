***shell脚本注释***
***unzip.sh***



***unzip为zip压缩文件的解压缩程序。***
***理解归档文件（archive file）和压缩文件（compressed file）间的区别对用户来说十分重要。***
***归档文件/打包是一个文件和目录的集合，而这个集合被贮存在一个文件中。***
***归档文件没有经过压缩 — 它所使用的磁盘空间是其中所有文件和目录的总和。***
***压缩文件也是一个文件和目录的集合，且这个集合也被贮存在一个文件中，***
***但是，它的贮存方式使其所占用的磁盘空间比其中所有文件和目录的总和要少,***
***当然看名也知道这是经过压缩的。如果你在计算机上的磁盘空间不足，***
***你可以压缩不常使用的、或不再使用但想保留的文件。你甚至可以创建归档文件，***
***然后再将其压缩来节省磁盘空间。***
***Linux下最常用的打包程序就是tar了，使用tar程序打出来的包或者说归档出来的，***
***我们常称为tar包，tar包文件的命令通常都是以.tar结尾的。生成tar包后，就可以用其它的程序来进行压缩了***



#!/bin/sh
# Author: mahongxin <hongxin_228@163.com>
set -x																			#调试模式
cd ../../../../utils
. ./sys_info.sh
. ./sh-test-lib
cd -

#Test user id
if [ `whoami` != 'root' ]; then													#判断是否为root用户
    echo " You must be the superuser to run this script" >&2
    exit 1
fi
case $distro in																	#安装依赖包
    "centos")
        yum install wget -y
        yum install unzip -y
        yum install zip -y
        ;;
esac
wget http://htsat.vicp.cc:804/netperf-2.7.0.tar.gz								#wget下载netperf-2.7.0.tar.gz归档压缩文件

tar -zxvf netperf-2.7.0.tar.gz													#解包归档压缩文件
print_info $? tar-compressedpackage

rm -f netperf-2.7.0.tar.gz														#删除下载包

tar -cvzf netperf-2.7.0.tar.gz netperf-2.7.0									#归档netperf-2.7.0文件为netperf-2.7.0.tar.gz包
print_info $? tar-packaging

wget http://htsat.vicp.cc:804/cryptopp-CRYPTOPP_5_6_5.zip						#wget下载zip压缩包
mv cryptopp-CRYPTOPP_5_6_5.zip cryp.zip											#重命名zip压缩包
unzip cryp.zip																	#解压压缩包
print_info $? unzip-compressedpackage

rm -f cryp.zip																	#删除压缩包
zip cryp.zip cryptopp-CRYPTOPP_5_6_5											#打包文件为cryp.zip压缩包
print_info $? zip-packaging

rm -rf netperf*
rm -rf cryp*
