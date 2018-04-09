***shell脚本注释***
***sys_info.sh***

#!/bin/bash																		

USERNAME="testing"
PASSWD="open1234asd"

distro=""
#sys_info=$(uname -a)
sys_info=$(cat /etc/os-release | grep PRETTY_NAME)											#设定sys_info变量，并查找到当前系统的全称

if [ "$(echo $sys_info |grep -E 'UBUNTU|Ubuntu|ubuntu')"x != ""x ]; then					#grep -E 将接受的参数作为扩展正则表达式，统一规范distro名称
    distro="ubuntu"
elif [ "$(echo $sys_info |grep -E 'cent|CentOS|centos')"x != ""x ]; then
    distro="centos"
elif [ "$(echo $sys_info |grep -E 'fed|Fedora|fedora')"x != ""x ]; then
    distro="fedora"
elif [ "$(echo $sys_info |grep -E 'DEB|Deb|deb')"x != ""x ]; then
    dsstro="debian"
elif [ "$(echo $sys_info |grep -E 'OPENSUSE|OpenSuse|opensuse')"x != ""x ]; then
    distro="opensuse"
else
    distro="ubuntu"
fi

#local_ip=$(ip addr show `ip route | grep "default" | awk '{print $NF}'`| grep -o "inet [0-9\.]*" | cut -d" " -f 2)
#modify by liucaili 20171028
#local_ip=$(ip addr show `ip route | grep "default" | awk '{print $5}'`| grep -o "inet [0-9\.]*" | cut -d" " -f 2)

#tanliqing modify 
local_ip=`ip addr | grep -A2 "state UP" | tail -1 | awk {'print $2'} | cut -d / -f 1`		#首先输出ip信息，然后截取出本机正在通信的网络ip
if [ ${local_ip}x = ""x ]; then
    #local_ip=$(ifconfig `route -n | grep "^0"|awk '{print $NF}'`|grep -o "addr inet:[0-9\.]*"|cut -d':' -f 2)
    local_ip=$(ifconfig `route -n | grep "^0"|awk '{print $5}'`|grep -o "addr inet:[0-9\.]*"|cut -d':' -f 2)		#如果ip addr命令无效，那么从路由信息表中截取出ip，grep -o 表示仅打印出匹配行的匹配内容
fi

start_service='systemctl start'
stop_service='systemctl stop'
reload_service='systemctl reload'
restart_service='systemctl restart'
enable_service='systemctl enable'
disable_service='systemctl disable'
status_service='systemctl status'															#设定启动，停止，重载，重启，启用，不启用，状态，服务

case $distro in
    "ubuntu" | "debian" )																	#如果发行版distro变量是ubuntu或者debian,那么设定升级变量为apt-get update -y参数表示安装过程全部选择确认
        update_commands='apt-get update -y'
        install_commands='apt-get install -y'												#如果发行版distro变量是ubuntu或者debian,那么设定安装变量为apt-get install
        start_service=""
        reload_service=""
        restart_service=""
        status_service=""
        ;;
    "opensuse" )
        update_commands='zypper -n update'
        install_commands='zypper -n install'
        ;;
    "centos" )
        update_commands='yum update -y'
        install_commands='yum install -y'
        ;;
    "fedora" )
        update_commands='dnf update -y'
        install_commands='dnf install -y'													#注意不同发行版，升级和安装命令互不相同
        ;;
esac

# 临时执行
case $distro in 
    "centos")
        sed -i "s/5.1/5.0/g"  /etc/yum.repos.d/estuary.repo 								#sed工具 -i表示插入，s表示替换5.1为5.0，g表示全面替换 后面是操作对象文件
        yum clean all 																		#清除YUM缓存
yum 会把下载的软件包和header存储在cache中，而不会自动删除
        ;;
    "ubuntu" | "debian" )
        sed -i "s/5.1/5.0/g" /etc/apt/sources.list.d/estuary.list 
        apt-get update 
        ;;
    *)
        ;;
esac



red='\e[0;41m' # 红色  
RED='\e[1;31m'
green='\e[0;32m' # 绿色  
GREEN='\e[1;32m'
yellow='\e[5;43m' # 黄色  
YELLOW='\e[1;33m'
blue='\e[0;34m' # 蓝色  
BLUE='\e[1;34m'
purple='\e[0;35m' # 紫色  
PURPLE='\e[1;35m'
cyan='\e[4;36m' # 蓝绿色  
CYAN='\e[1;36m'
WHITE='\e[1;37m' # 白色
 
NC='\e[0m' # 没有颜色
	
print_info()													#设定print_info函数
{

    if [ $1 -ne 0 ]; then										#如果第一个参数不为零，则
        result='fail'
        cor=$red 
    else
        result='pass'
        cor=$GREEN
    fi

    test_name=$2												#将第二个参数的值传给test_name

    

    echo -e "${cor}the result of $test_name is $result${NC}"	#echo -e表示反斜杠转义
    lava-test-case "$test_name" --result $result				#lava-test-case是CI上已经封装好的一个函数，用来保存用例的执行情况信息
}

download_file()
{
    url_address=$1
    let i=0
    while (( $i < 5 )); do										#循环执行wget 5次，当wget 完成时，终止循环
        wget $url_address
        if [ $? -eq 0 ]; then
            break;
        fi
        let "i++"
    done
}

Check_Version()
{
	deps_name=$1
	version=$2
	ver_info=$(yum info $deps_name | grep Version | awk '{print $3}')			#yum info 表示从网络上查找包的信息，。这行是为了找出版本信息
	if [ $version == $ver_info ];then											#网络上查找的包版本号与输入的版本号对比，看是不是一致，一直则返回0
		return 0																#这个函数可用来检查包是不是最新
	else
		return 1
	fi
}


Check_Repo()
{
	deps_name=$1
	repo=$2
	repo_info=$(yum info $deps_name | grep Repo | awk '{print $3}')
	if [ $repo == $repo_info ];then
		return 0
	else
		return 1
	fi
}