#!/bin/bash

# Author: klion
# 2020.5.6

# 先去VPS上去执行一些初始操作 ( 如下以 Ubuntu 16.04 LTS 64bit为例 )
# passwd								# 改密码
# echo "Korc" > /etc/hostname  			# 修改机器名	
# echo 127.0.0.1 Korc >> /etc/hosts     # 修改解析
# shutdown -r now   					# 最后,重启系统使之生效

# 执行脚本 [ 用source执行 ]
# source ./VPS_Env_install.sh

# 渗透的VPS可能换的比较勤,脚本的作用就是将平时经常会用到的一些系统 "依赖库" , "各类语言执行环境(python2/3 + Golang + JDK)" 和 一些"小工具" 进行自动安装配置,避免重复劳动

# 判断当前用户权限
if [ `id -u` -ne 0 ];then
	echo -e "\n\033[33m请以 root 权限 运行该脚本! \033[0m\n"
	exit
fi

echo -e "\n\e[92m系统正在进行初始配置,请稍后... \e[0m\n" && sleep 2

apt-get update  >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	echo -e "\e[92m准备安装各种常用工具及依赖库,请稍后... \e[0m" && sleep 2
	if [ $? -eq 0 ] ;then
		apt-get install gcc gdb make cmake socat telnet tree tcpdump iptraf iftop nethogs lrzsz git unzip p7zip-full curl wget vim openssl libssl-dev libssh2-1-dev -y >/dev/null 2>&1
		if [ $? -eq 0 ] ;then
			echo -e "\e[94m常用基础工具及相关依赖库安装已完成 ! \e[0m\n"
			sleep 2 && cd
		else
			echo -e "基础工具及常用依赖库安装失败,请检查后重试 !"
			exit
		fi
	fi
fi

# 安装配置nc
which "add-apt-repository" > /dev/null
if [ $? -eq 0 ];then
	add-apt-repository universe >/dev/null 2>&1
	if [ $? -eq 0 ];then
		apt-get install netcat-traditional -y >/dev/null 2>&1
		if [ $? -eq 0 ];then
			echo -e "\e[94mNc 安装成功! \e[0m"
			update-alternatives --set nc /bin/nc.traditional >/dev/null 2>&1
			if [ $? -eq 0 ];then
				echo -e "\e[94mNc 配置成功! \e[0m\n"
				sleep 1
			else
				echo -e "Nc 配置失败,请检查后重试!"
				exit
			fi
		else
			echo -e "Nc 安装失败,请检查后重试!"
			exit
		fi
	else
		echo -e "PPA 添加失败,请检查后重试!"
		exit
	fi
else
	echo -e "add-apt-repository 命令不存在,请尝试安装后重试!"
	exit
fi


echo -e "\e[92m准备配置SSH服务 ! \e[0m"
apt-get install openssh-server -y  >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	echo -e "TCPKeepAlive yes\nAllowTcpForwarding yes\nGatewayPorts yes" >> /etc/ssh/sshd_config && systemctl restart sshd.service
	if [ $? -eq 0 ] ;then
		echo -e "\e[94mSSH 服务配置已完成 ! \e[0m\n"
		sleep 2 && cd
	else
		echo -e "SSH安装配置失败,请检查后重试 !"
		exit
	fi
fi

# 注,此处的环境变量可按自己的日常操作习惯随意增加
echo -e "\e[92m准备配置当前用户环境变量 ! \e[0m" && sleep 2
echo -e "vi='vim'\npg='ping www.google.com -c 5'\ngrep='grep --color=auto'\n" >> ~/.bashrc && source ~/.bashrc
if [ $? -eq 0 ] ;then
	echo -e "\e[94m当前用户环境变量配置已完成 ! \e[0m\n"
	sleep 2 && cd
else
	echo -e "当前用户环境变量配置失败,请检查后重试 !"
	exit
fi

# 注,此处的VI编辑配置可按自己的日常操作习惯随意增加
echo -e "\e[92m准备配置当前用户 VI 编辑器 ! \e[0m" && sleep 2
cat << \EOF > ~/.vimrc
set nu              " 显示行号
syntax on           " 语法高亮  
autocmd InsertLeave * se nocul  " 用浅色高亮当前行  
autocmd InsertEnter * se cul    " 用浅色高亮当前行  
set ruler           " 显示标尺  
set showcmd         " 输入的命令显示出来，看的清楚些
set nocompatible
set fencs=utf-8,ucs-bom,shift-jis,gb18030,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8
set fileencodings=ucs-bom,utf-8,cp936
set fileencoding=utf-8
EOF
if [ $? -eq 0 ] ;then
	echo -e "\e[94mVI 配置已完成! \e[0m\n"
	sleep 2 && cd
fi

# 开启系统路由转发
echo -e "\e[92m准备开启系统路由转发 ! \e[0m"
sleep 2
echo 1 > /proc/sys/net/ipv4/ip_forward
if [ $? -eq 0 ] ;then
	sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf && sysctl -p >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		echo -e "\e[94m系统路由转发已开启 ! \e[0m\n"
		sleep 2 && cd
	else
		echo -e "路由转发开启失败,请检查后重试 !"
		exit
	fi
fi

echo -e "=========================================================================================================\n"

echo -e "\e[92m开始编译安装各种常用语言环境 [ Jdk 1.8 + Python 2.7 + Python 3.8 + Golang 1.14.2 ] 请耐心等待... \e[0m\n" && sleep 2

# 安装配置 Jdk 1.8
echo -e "\e[92m准备下载jdk-8u202-linux-x64.tar.gz 耗时可能较长,请耐心等待... \e[0m" && sleep 2
wget https://repo.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	echo -e "\e[94mjdk-8u202-linux-x64.tar.gz 下载完成 ! \e[0m"
	tar xf jdk-8u202-linux-x64.tar.gz && mv jdk1.8.0_202/ /usr/local/ && ln -s /usr/local/jdk1.8.0_202/ /usr/local/jdk
	if [ $? -eq 0 ] ;then
		echo -e "export JAVA_HOME=/usr/local/jdk/\nexport PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH\nexport CLASSPATH=.\$CLASSPATH:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib/tools.jar" >> /etc/profile && source /etc/profile
		if [ $? -eq 0 ] ;then
			echo -e "\e[94mJdk 1.8 安装配置已完成 ! \e[0m\n"
			sleep 2 && cd && rm -fr jdk*
		else
			echo -e "Jdk 1.8 安装配置失败,请检查后重试 !"
			exit
		fi
	fi
else
	echo -e "jdk-8u202-linux-x64.tar.gz下载失败,请检查后重试 !"
	exit
fi


# 安装Python 2.7 + Pip2.7
echo -e "\e[92m准备安装Python 2.7 + Pip2.7 请稍后... \e[0m" && sleep 2
if [ $? -eq 0 ] ;then
	apt-get install python2.7 python2.7-dev -y >/dev/null 2>&1 && sleep 2 && apt-get install python-pip -y >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		python2.7 -m pip install --upgrade pip >/dev/null 2>&1
		if [ $? -eq 0 ] ;then
			pip2.7 install setuptools >/dev/null 2>&1 && pip2.7  install requests >/dev/null 2>&1 && pip2.7 install urllib3 >/dev/null 2>&1
			if [ $? -eq 0 ] ;then
				echo -e "\e[94mPython 2.7 + Pip2.7 已安装成功 ! \e[0m\n"
				sleep 2 && cd
			else
				echo -e "Python 2.7 + Pip2.7 安装失败 !"
				exit
			fi
		fi
	fi
fi

# 编译安装Python3.8 + Pip3.8
echo -e "\e[92m准备安装Python3.8 + Pip3.8 请稍后... \e[0m" && sleep 2
if [ $? -eq 0 ] ;then
	apt-get install build-essential libncursesw5-dev libgdbm-dev libc6-dev zlib1g-dev libsqlite3-dev tk-dev openssl libffi-dev -y >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		echo -e "\e[94m开始下载Python-3.8.3.tar.xz ! \e[0m" && sleep 2
		wget https://www.python.org/ftp/python/3.8.3/Python-3.8.3.tar.xz >/dev/null 2>&1
		if [ $? -eq 0 ] ;then
			echo -e "\e[94mPython-3.8.3.tar.xz下载完成,准备编译安装,耗时较长,请耐心等待... \e[0m"
			tar xf Python-3.8.3.tar.xz && cd Python-3.8.3/ && ./configure --enable-optimizations >/dev/null 2>&1 && make>/dev/null 2>&1 && make install >/dev/null 2>&1
			if [ $? -eq 0 ] ;then
				echo -e "\e[94mPython-3.8.3 已编译安装成功 ! \e[0m" && sleep 2
				python3.8 -m pip install --upgrade pip >/dev/null 2>&1
				if [ $? -eq 0 ] ;then
					pip3.8 install wheel >/dev/null 2>&1 && pip3.8 install setuptools >/dev/null 2>&1 && pip3.8 install requests >/dev/null 2>&1
					if [ $? -eq 0 ] ;then
						echo -e "\e[94m常用Py3依赖安装成功 ! \e[0m\n"
						sleep 2 && cd && rm -fr Python-3.8.2*
					else
						echo -e "常用Py3依赖失败 !"
						exit
					fi
				else
					echo -e "Pip3.8 安装失败 !"
					exit
				fi
			else
				echo -e "Python 3.8.3 编译安装失败 !"
				exit
			fi
		else
			echo -e "Python-3.8.3.tar.xz 下载失败 !"
			exit
		fi
	fi
fi

# 安装配置Golang 1.14.2
echo -e "\e[92m准备安装配置Golang 1.14.2 请稍后... \e[0m" && sleep 2
wget https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	echo -e "\e[94mgo1.14.2.linux-amd64.tar.gz下载完成 ! \e[0m" && sleep 2
	tar xf go1.14.2.linux-amd64.tar.gz && mv go /usr/local
	if [ $? -eq 0 ] ;then
		echo -e "export GOROOT=/usr/local/go\nexport GOPATH=~/work\nexport GOBIN=\$GOROOT/bin\nexport PATH=\$PATH:\$GOROOT/bin:\$GOBIN" >> /etc/profile && source /etc/profile
		if [ $? -eq 0 ] ;then
			go version >/dev/null 2>&1 && go env >/dev/null 2>&1
			if [ $? -eq 0 ] ;then
				echo -e "\e[94mGolang 1.14.2 已安装配置成功 ! \e[0m\n"
				sleep 2 && cd && rm -fr go*
			else
				echo -e "Golang 1.14.2 安装配置失败 !"
				exit
			fi
		fi
	fi
fi

echo -e "=========================================================================================================\n"

echo -e "\e[92m准备安装各种常用小工具 ! \e[0m\n" && sleep 2

# 编译安装最新版Masscan
apt-get install git gcc make libpcap-dev clang -y >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	git clone --recursive https://github.com/robertdavidgraham/masscan.git >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		cd masscan/ && rm -fr .git* .t* && make >/dev/null 2>&1 && mv bin/masscan /usr/bin/ && cd && rm -fr masscan*
		if [ $? -eq 0 ] ;then
			echo -e "\e[94mMasscan 已编译安装成功 ! \e[0m" && sleep 2
		else
			echo -e "Masscan 编译安装失败 !"
			exit
		fi
	fi
fi

# 编译安装 Nmap [ 此处有条件的情况,最好还是不要直接从下载编译,可以把自己已经事先处理好的nmap(主要是各种扫描特征处理)传上去编译安装]
apt-get install openssl libssh2-1-dev build-essential -y >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	wget https://nmap.org/dist/nmap-7.80.tar.bz2 >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		tar xf nmap-7.80.tar.bz2 && cd nmap-7.80 && rm -fr .git* .t* && chmod +x ./* && ./configure >/dev/null 2>&1 && make  >/dev/null 2>&1 && make install >/dev/null 2>&1
		if [ $? -eq 0 ] ;then
			cd && rm -fr nmap* && nmap -h >/dev/null 2>&1
			echo -e "\e[94mNmap 已编译安装成功 ! \e[0m" && sleep 2
		else
			echo -e "Nmap 编译安装失败 !"
			exit
		fi
	else
		echo -e "nmap-7.80.tar.bz2 下载失败 !"
		exit
	fi
fi


# 编译安装最新版Medusa
apt-get install build-essential libpq5 libpq-dev libssh2-1 libssh2-1-dev libgcrypt11-dev libgnutls28-dev libsvn-dev freerdp-x11 libfreerdp-dev -y >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	wget http://www.foofus.net/jmk/tools/medusa-2.2.tar.gz >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		tar xf medusa-2.2.tar.gz && cd medusa-2.2/ && rm -fr .git* .t* && ./configure >/dev/null 2>&1 && make >/dev/null 2>&1 && make install >/dev/null 2>&1
		if [ $? -eq 0 ] ;then
			echo -e "\e[94mMedusa 已编译安装成功 ! \e[0m" && sleep 2
			cd && rm -fr medusa*
		else
			echo -e "Medusa 编译安装失败 !"
			exit
		fi
	else
		echo -e "medusa-2.2.tar.gz 下载失败 !"
		exit
	fi
fi

# 编译安装最新版hydra
apt-get install git libssh-dev libidn11-dev libpcre3-dev libgtk2.0-dev libmysqlclient-dev libpq-dev libsvn-dev firebird-dev libgcrypt11-dev libncurses5-dev -y >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	git clone --recursive https://github.com/vanhauser-thc/thc-hydra.git >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		cd thc-hydra && rm -fr .git* .t* && chmod +x ./* && ./configure >/dev/null 2>&1 && make >/dev/null 2>&1 && make install >/dev/null 2>&1
		if [ $? -eq 0 ] ;then
			echo -e "\e[94mhydra 已编译安装成功 ! \e[0m" && sleep 2
			cd && rm -fr thc-hydra*
		else
			echo -e "hydra 编译安装失败 !"
			exit
		fi
	fi
fi

# 下载OneForAll
git clone --recursive https://github.com/shmilylty/OneForAll.git >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	cd OneForAll/ && rm -fr .git* .t* && python3.8 -m pip install -U pip setuptools >/dev/null 2>&1 && pip3 install -r requirements.txt >/dev/null 2>&1
	echo q | python3 oneforall.py -h >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		echo -e "\e[94mOneForAll 已安装成功 ! \e[0m" && sleep 2 && cd 
	else
		echo -e "OneForAll 安装失败 !"
		exit
	fi
fi

# Sublist3r 安装成功
git clone --recursive https://github.com/aboul3la/Sublist3r.git >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	cd Sublist3r/ && rm -fr .git* .t* && pip2.7 install -r requirements.txt >/dev/null 2>&1 && python sublist3r.py -h >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		echo -e "\e[94mSublist3r 已安装成功 ! \e[0m" && sleep 2 && cd 
	else
		echo -e "Sublist3r 安装失败 !"
		exit
	fi
fi


# 下载 sqlmap
git clone --recursive https://github.com/sqlmapproject/sqlmap.git >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	cd sqlmap/ && rm -fr .git* .t* && python sqlmap.py -hh >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		echo -e "\e[94mSQLmap 已安装成功 ! \e[0m" && sleep 2 && cd 
	else
		echo -e "SQLmap 安装失败 !"
		exit
	fi
fi

# 下载 dirsearch
git clone --recursive https://github.com/maurosoria/dirsearch.git >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	cd dirsearch && rm -fr .git* .t* && python3 dirsearch.py -h >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		echo -e "\e[94mdirsearch 已安装成功 ! \e[0m" && sleep 2 && cd 
	else
		echo -e "dirsearch 安装失败 !"
		exit
	fi
fi

# 下载 theHarvester
git clone --recursive https://github.com/laramies/theHarvester.git >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	cd theHarvester && rm -fr .git* .t* && python3 -m pip install -r requirements/base.txt >/dev/null 2>&1 && python3 theHarvester.py -h  >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		echo -e "\e[94mtheHarvester 已安装成功 ! \e[0m" && sleep 2 && cd
	else
		echo -e "theHarvester 安装失败 !"
		exit
	fi
fi

# 下载 wafw00f
git clone --recursive https://github.com/EnableSecurity/wafw00f.git >/dev/null 2>&1
if [ $? -eq 0 ] ;then
	cd wafw00f/ && rm -fr .git* .t* && python2.7 setup.py install >/dev/null 2>&1 && wafw00f -h >/dev/null 2>&1
	if [ $? -eq 0 ] ;then
		echo -e "\e[94mwafw00f 已安装成功 ! \e[0m\n" && sleep 2 && cd && rm -fr wafw00f
	else
		echo -e "wafw00f 安装失败 !"
		exit
	fi
fi

echo -e "=========================================================================================================\n"
# 清除所有操作记录,方便日后快速排查问题
history -c –w && > .bash_history && cat /dev/null > /var/log/wtmp && cat /dev/null > /var/log/btmp && cat /dev/null > /var/log/lastlog && cat /dev/null > /var/log/auth.log
if [ $? -eq 0 ] ;then
	echo -e "\e[92m基础 VPS 环境现已全部部署完毕,玩的愉快 !  \e[0m\n" && sleep 2 && cd
fi

# 安装破解AWVS 13 [可选]
# apt-get install libxdamage1 libgtk-3-0 libasound2 libnss3 libxss1 -y >/dev/null 2>&1
# if [ $? -eq 0 ] ;then
# 	7z x Acunetix_13.0.200217097_x64_Linux.7z && cd Acunetix_13.0.200217097_x64_Linux/ && chmod +x acunetix_13.0.200217097_x64_.sh && ./acunetix_13.0.200217097_x64_.sh && cp wvsc /home/acunetix/.acunetix/v_200217097/scanner/ && cp license_info.json /home/acunetix/.acunetix/data/license/
# 	if [ $? -eq 0 ] ;then
# 		systemctl restart acunetix.service
# 		if [ $? -eq 0 ] ;then
# 			echo -e "\e[94mAWVS 13 破解安装成功 ! \e[0m" && sleep 2 && cd 
# 		fi
# 	fi
# fi


