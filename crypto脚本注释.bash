***shell脚本注释***
***crypto.sh***
***crypto模块的目的是为了提供通用的加密和哈希算法，用于加解密的工具***




#!/bin/sh																		#Crypto++是个免费的C++加解密类库
#gtest is Google's Unit test tool											#gtest是谷歌的单元测试工具
# Author: mahongxin <hongxin_228@163.com>
set -x																		#调试模式
cd ../../../../utils														#切换到utils目录
. ./sys_info.sh																#
. ./sh-test-lib																#
cd -

#Test user id
if [ `whoami` != 'root' ]; then
    echo " You must be the superuser to run this script" >&2
    exit 1
fi
#distro=`cat /etc/redhat-release | cut -b 1-6`
case $distro in
    "centos")
        #yum install gcc -y
        #yum install gcc-c++ -y
        #yum install make -y
        #yum install unzip -y
        pkgs="gcc gcc-c++ make unzip"										#make 是一个命令工具，它解释 Makefile 中的指令（应该说是规则）。
																			#在 Makefile文件中描述了整个工程所有文件的编译顺序、编译规则。
        install_deps "${pkgs}"												#安装依赖工具
        wget http://htsat.vicp.cc:804/cryptopp-CRYPTOPP_5_6_5.zip			#网络下载cryptopp包
        print_info $? get-crypto											#检查是否安装成功
        unzip cryptopp-CRYPTOPP_5_6_5.zip									#解压zip包
        print_info $? unzip-crypto											#检查是否安装成功
        ;;
esac
cd cryptopp-CRYPTOPP_5_6_5
make																		#编译包
make libcryptopp.so															#编译libcryptopp.so库
make install																#编译安装

cat << EOF >> ./Cryptopp_test.cc											#添加内容到cryptopp_test.cc源文件.该文件为c++源文件与.cpp意思一致
    #include <cryptopp/randpool.h>
    #include <cryptopp/rsa.h>
    #include <cryptopp/hex.h>
    #include <cryptopp/files.h>
    #include <iostream>
    using namespace std;
    using namespace CryptoPP;
    #pragma comment(lib, "cryptlib.lib")
    //------------------------
    // 函数声明
    //------------------------
    void GenerateRSAKey(unsigned int keyLength, const char *privFilename, const char *pubFilename, const char *seed);
    string RSAEncryptString(const char *pubFilename, const char *seed, const char *message);
    string RSADecryptString(const char *privFilename, const char *ciphertext);
    RandomPool & GlobalRNG();
    //------------------------
    // 主程序
    //------------------------
    int main()
    {
        char priKey[128] = {0};
        char pubKey[128] = {0};
        char seed[1024] = {0};
        // 生成 RSA 密钥对
        strcpy(priKey, "pri"); // 生成的私钥文件
        strcpy(pubKey, "pub"); // 生成的公钥文件
        strcpy(seed, "seed");
        GenerateRSAKey(1024, priKey, pubKey, seed);
        //RSA 加解密
        char message[1024] = {0};
        cout<<"Origin Text:\t"<<"just a test!"<<endl<<endl;
        strcpy(message, "just a test!");
        string encryptedText = RSAEncryptString(pubKey, seed, message); // RSA 加密
        cout<<"Encrypted Text:\t"<<encryptedText<<endl<<endl;
        string decryptedText = RSADecryptString(priKey, encryptedText.c_str()); // RSA  解密
        cout<<"Decrypted Text:\t"<<decryptedText<<endl<<endl;
        return 0;
    }
    //------------------------
    //生成 RSA 密钥对
    //------------------------
    void GenerateRSAKey(unsigned int keyLength, const char *privFilename, const char *pubFilename, const char *seed)
    {
           RandomPool randPool;
           randPool.Put((byte *)seed, strlen(seed));
           RSAES_OAEP_SHA_Decryptor priv(randPool, keyLength);
           HexEncoder privFile(new FileSink(privFilename));
           priv.DEREncode(privFile);
           privFile.MessageEnd();
           RSAES_OAEP_SHA_Encryptor pub(priv);
           HexEncoder pubFile(new FileSink(pubFilename));
           pub.DEREncode(pubFile);
           pubFile.MessageEnd();
    }
    //------------------------
    // RSA 加密
    //------------------------
    string RSAEncryptString(const char *pubFilename, const char *seed, const char *message)
    {
           FileSource pubFile(pubFilename, true, new HexDecoder);
           RSAES_OAEP_SHA_Encryptor pub(pubFile);
           RandomPool randPool;
           randPool.Put((byte *)seed, strlen(seed));
           string result;
           StringSource(message, true, new PK_EncryptorFilter(randPool, pub, new HexEncoder(new StringSink(result))));
           return result;
    }
    //------------------------
    // RSA  解密
    //------------------------
    string RSADecryptString(const char *privFilename, const char *ciphertext)
    {
           FileSource privFile(privFilename, true, new HexDecoder);
           RSAES_OAEP_SHA_Decryptor priv(privFile);
           string result;
           StringSource(ciphertext, true, new HexDecoder(new PK_DecryptorFilter(GlobalRNG(), priv, new StringSink(result))));
           return result;
    }
    //------------------------
    // 定义全局的随机数池
    //------------------------
    RandomPool & GlobalRNG()
    {
           static RandomPool randomPool;
           return randomPool;
    }
EOF
g++ -lcryptopp -lpthread Cryptopp_test.cc -o Cryptopp_test				#编译源文件为可执行文件Cryptopp_test,-o参数表示命名		
export LD_LIBRARY_PATH=/lib:$LD_LIBRARY_PATH							#Linux export命令用于设置或显示环境变量。export命令用于将shell变量输出为环境变量，
																		#或者将shell函数输出为环境变量，这里是临时设置共享库环境变量，使的编译过后的文件可以移植运行
sudo ldconfig															#ldconfig命令的用途主要是在默认搜寻目录/lib和/usr/lib以及动态库配置文件/etc/ld.so.conf内所列的目录下，
																		#搜索出可共享的动态链接库（格式如lib*.so*）,进而创建出动态装入程序(ld.so)所需的连接和缓存文件。
																		#缓存文件默认为/etc/ld.so.cache，此文件保存已排好序的动态链接库名字列表，为了让动态链接库为系统所共享，
																		#需运行动态链接库的管理命令ldconfig，此执行程序存放在/sbin目录下。
																		#ldconfig通常在系统启动时运行，而当用户安装了一个新的动态链接库时，就需要手工运行这个命令。
./Cryptopp_test >> crytest.log
print_info $? compile-cpp												#验证compile-cpp是否成功（编译执行步骤）
str=`grep -Po "Encrypted Text" crytest.log`								#grep -o 只输出匹配的部分
TCID="crypto-policies-test"
if [ "$str" != "" ];then
    lava-test-case $TCID --result pass
else
    lava-test-case $TCID --result fail
fi
case $distro in
     "centos")
         #yum remove gcc gcc-c++ make -y
         remove_deps "${pkgs}"											#移除已安装包
         print_info $? remove-package
         ;;
esac