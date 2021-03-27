---
title: "f8x 开发记录"
date: 2021-03-05T23:08:03+08:00
draft: false
author: "r0fus0d"

---

记录开发 f8x 工具过程中的一些思路和问题,想到哪里写哪里,长期更新

<!--more-->

---

# 系统兼容

系统兼容是个非常重要的问题,如果只能在 centos 上跑,而不能在 ubuntu 上跑,这个部署工具一定是失败的

那么问题来了,shell 脚本本来就是由 linux 命令组成,怎么会换一个发行版就不能跑

原因比较复杂,例如 : 不同的包管理器,不同的防火墙,不同的网络配置文件,等

其中最麻烦的就是不同的包管理工具,牵扯到不同的安装命令,不同的镜像源配置方式,甚至同发行版下不同版本的源地址,包管理器进程的锁处理,贼烦

```bash
case $Linux_Version in
    *"CentOS"*|*"RedHat"*|*"Fedora"*)
        yum install -y gdb 1> /dev/null 2>> /tmp/f8x_error.log && echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32m已安装 gdb 工具\033[0m" || echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;31m[ERROR]\033[0m - \033[1;31m安装 gdb 工具失败,请查看日志 /tmp/f8x_error.log \n\033[0m"
        ;;
    *"Kali"*|*"Ubuntu"*|*"Debian"*)
        apt-get install -y gdb 1> /dev/null 2>> /tmp/f8x_error.log && echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32m已安装 gdb 工具\033[0m" || echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;31m[ERROR]\033[0m - \033[1;31m安装 gdb 工具失败,请查看日志 /tmp/f8x_error.log \n\033[0m"
        ;;
    *) ;;
esac
```

```bash
# ===================== 修改 CentOS YUM 源 =====================
Update_CentOS_Mirror(){

    case $Linux_Version_Num in
        8)
            rm -rf /etc/yum.repos.d/CentOS-Base.repo.bak 1> /dev/null 2>> /tmp/f8x_error.log && cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak 1> /dev/null 2>> /tmp/f8x_error.log && echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32m已备份本地 Yum 源\033[0m"
            curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo 1> /dev/null 2>> /tmp/f8x_error.log && echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32m已下载 aliyun Yum 源\033[0m" || echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;31m[ERROR]\033[0m - \033[1;31maliyun Yum 源下载失败,请查看日志 /tmp/f8x_error.log \n\033[0m"
            ;;
        7)
            rm -rf /etc/yum.repos.d/CentOS-Base.repo.bak 1> /dev/null 2>> /tmp/f8x_error.log && cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak 1> /dev/null 2>> /tmp/f8x_error.log && echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32m已备份本地 Yum 源\033[0m"
            curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo 1> /dev/null 2>> /tmp/f8x_error.log && echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32m已下载 aliyun Yum 源\033[0m" || echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;31m[ERROR]\033[0m - \033[1;31maliyun Yum 源下载失败,请查看日志 /tmp/f8x_error.log \n\033[0m"
            ;;
        6)
            rm -rf /etc/yum.repos.d/CentOS-Base.repo.bak 1> /dev/null 2>> /tmp/f8x_error.log && cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak 1> /dev/null 2>> /tmp/f8x_error.log && echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32m已备份本地 Yum 源\033[0m"
            curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-6.repo 1> /dev/null 2>> /tmp/f8x_error.log && echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32m已下载 aliyun Yum 源\033[0m" || echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;31m[ERROR]\033[0m - \033[1;31maliyun Yum 源下载失败,请查看日志 /tmp/f8x_error.log \n\033[0m"
            ;;
        *)
            echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;31m[ERROR]\033[0m - \033[1;31m版本错误,此项 pass\n\033[0m"
            ;;
    esac

}
```

f8x 工具中使用 `cat /etc/*-release | head -n 1` 来匹配发行版和具体版本,期间也使用过 `lsb_release -c` 命令,但是在 docker 环境中无法兼容,所以使用上述命令来提高兼容性

```bash
case $(cat /etc/*-release | head -n 1) in
    *"Kali"*|*"kali"*)
        Linux_Version="Kali"
        case $(cat /etc/*-release | head -n 4) in
            *"2021"*)
                Linux_Version_Num="kali-rolling"
                Linux_Version_Name="buster"
                ;;
            *"2020"*)
                Linux_Version_Num="kali-rolling"
                Linux_Version_Name="buster"
                ;;
            *)
                Linux_Version_Num="kali-rolling"
                Linux_Version_Name="stretch"
                ;;
        esac
        ;;
    *"Ubuntu"*|*"ubuntu"*)
        Linux_Version="Ubuntu"
        case $(cat /etc/*-release | head -n 4) in
            *"hirsute"*)
                Linux_Version_Num="21.04"
                Linux_Version_Name="hirsute"
                ;;
            *"groovy"*)
                Linux_Version_Num="20.10"
                Linux_Version_Name="groovy"
                ;;
            *"focal"*)
                Linux_Version_Num="20.04"
                Linux_Version_Name="focal"
                ;;
            *"eoan"*)
                Linux_Version_Num="19.10"
                Linux_Version_Name="eoan"
                ;;
            *"bionic"*)
                Linux_Version_Num="18.04"
                Linux_Version_Name="bionic"
                ;;
            *"xenial"*)
                Linux_Version_Num="16.04"
                Linux_Version_Name="xenial"
                ;;
            *)
                echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;31m[ERROR]\033[0m - \033[1;31m未知版本\033[0m"
                exit 1
                ;;
        esac
        ;;
esac
```

然并卵,在部分云平台的机器中,甚至连 `/etc/*-release` 文件都没有!要么就是直接把 `/etc/*-release` 文件改的妈都不认识,说的就是你,Azure

所以在后来的版本中加上了手动输入发行版的功能

```bash
*)
    echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;31m[ERROR]\033[0m - \033[1;31m未知系统\033[0m"
    echo -e "\033[1;33m\n请手动输入你的系统发行版 Kali[k] Ubuntu[u] Debian[d] Centos[c] RedHat[r] Fedora[f]\033[0m" && read -r input
    case $input in
        [kK])
            Linux_Version="Kali" ;;
        [uU])
            Linux_Version="Ubuntu"
            echo -e "\033[1;33m\n请手动输入你的系统版本号 [21.04] [20.10] [20.04] [19.10] [18.04] [16.04]\033[0m" && read -r input
            Linux_Version_Name=$input
            ;;
        [dD])
            Linux_Version="Debian"
            echo -e "\033[1;33m\n请手动输入你的系统版本号 [11] [10] [9] [8] [7]\033[0m" && read -r input
            Linux_Version_Name=$input
            ;;
        [cC])
            Linux_Version="CentOS"
            echo -e "\033[1;33m\n请手动输入你的系统版本号 [8] [7] [6]\033[0m" && read -r input
            Linux_Version_Name=$input
            ;;
        [rR])
            Linux_Version="RedHat" ;;
        [fF])
            Linux_Version="Fedora"
            echo -e "\033[1;33m\n请手动输入你的系统版本号 [34] [33] [32]\033[0m" && read -r input
            Linux_Version_Name=$input
            ;;
        *)
            echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;31m[ERROR]\033[0m - \033[1;31m未知版本\033[0m"
            exit 1
            ;;
    esac
    ;;
```

目前我也没没有找到较好的解决方案,以 docker 官方的安装脚本 https://get.docker.com 为例,在部分 kali 是无法运行的,因为 kali 不分具体版本号,直接不兼容了🤣

![](https://gitee.com/asdasdasd123123/pic/raw/master/blog/3/1.png)

---

# 环境变量

环境变量的问题是在装 go 时初次发现的,后来在装 CobaltStrike 时愈发严重, CobaltStrike 运行需要用 keytool 工具生成 cobaltstrike.store , 而这个 keytool 工具需要 java 设置 bin 目录的环境变量,在 f8x 自动装完 oraclejdk 后,有时也无法使用 keytool 因为在 shell 脚本中环境变量使用 export, 只在脚本中有效，退出这个脚本，设置的变量就没有了,所以我采用直接写入 bashrc 长期修改环境变量这种方法,但实际场景还是需要使用者手动再开一个 shell 窗口加载环境变量运行 cs

当然使用 source 命令也可以解决问题,因为执行一个脚本文件是在一个子 shell 中运行的,而 source 则是在当前 shell 环境中运行的,这么多环境变量设置我怕影响运行,还是不推荐

---

# SAST

搞安全的怎么可以不扫扫自己开发的东西,shell 脚本的 dast 是不存在的,sast 倒是有一两个,
- [koalaman/shellcheck](https://github.com/koalaman/shellcheck)

不过扫出来的很多是语法上的错误,也是挺有学习价值的。

---

# 更新

无意中发现 shell 脚本可以自己删除自己,这么一说更新功能岂不是挺容易实现的,直接 curl -o f8x https://cdn.jsdelivr.net/gh/ffffffff0x/f8x@main/f8x 覆盖自身即可🤣

---

# 代理

代理功能是 f8x 的精髓,就像我在 readme 中缩写的 -p 会执行以下操作
1. 替换你的 DNS(默认为 223.5.5.5), 如果判断是 debian 系还会帮你安装 resolvconf, 长期修改 DNS
2. 检查基础的编译环境是否安装, 并通过默认的包管理器安装 gcc,make,unzip 这些基本软件
3. 可选的从 https://github.com/rofl0r/proxychains-ng 或 ffffffff0x.com 下载 Proxychains-ng 的源码, 编译安装
4. 要求你修改 /etc/proxychains.conf 文件
5. 修改 pip 代理为 https://mirrors.aliyun.com/pypi/simple/
6. 修改 docker 代理为 https://docker.mirrors.ustc.edu.cn , 并重启 docker 服务

事实上,在大部分选项运行时都会询问是否要走代理,这里就有一个开关的 Tricks

```bash
# ===================== 代理开关 =====================
Porxy_Switch(){

    if test -e /tmp/IS_CI
    then
        echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32mIS_CI\033[0m"
    else
        echo -e "\033[1;33m\n>> 安装时是否需要走代理? [y/N,默认No] \033[0m" && read -r input
        case $input in
            [yY][eE][sS]|[Yy])
                export GOPROXY=https://goproxy.io,direct
                if test -e /etc/proxychains.conf
                then
                    echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32m正在调用 Proxychains-ng\033[0m"
                    Porxy_OK=proxychains4
                else
                    echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;33m[ALERT]\033[0m - \033[1;33m未检测到 Proxychains-ng,正在执行自动安装脚本\033[0m"
                    Proxychains_Install
                    Porxy_OK=proxychains4
                fi
                ;;
            *)
                echo -e "\033[1;36m$(date +"%H:%M:%S")\033[0m \033[1;32m[INFOR]\033[0m - \033[1;32mPass~\033[0m"
                ;;
        esac
    fi

}
```

如果选择那么所有带 Porxy_OK 变量的命令都会自动走 proxychains4,同时该子 shell 中 go 的代理也被配置为 goproxy.io,同时如果并没有安装 proxychains4,那么会自动进行安装

---

# CI

github 提供 action 的 CI 服务, 挺好用的, 我也不用每次都开 vultr 的机器跑试试了, 不过只支持 ubuntu 18 和 20 比较遗憾

在 github action 中一些需要输入的情况会被忽略或报错,这与之前的代理请求造成了冲突,于是添加了一个 /tmp/IS_CI 的判断,在 action 运行开始就创建这个文件,f8x 检测到这个文件存在就默认忽略代理

![](https://gitee.com/asdasdasd123123/pic/raw/master/blog/3/7.png)

![](https://gitee.com/asdasdasd123123/pic/raw/master/blog/3/8.png)

---

# 锁

这里的锁指的是在使用包管理工具进行安装时,中断造成的问题,由于 f8x 基本不会输出任何报错信息在前台,所以有时候出现假死的状态只有手动以 bash -xv f8x 的方式运行排错,还是挺麻烦的,所以我做了个除锁模块

```bash
# ===================== 除锁模块 =====================
Rm_Lock(){

    case $Linux_Version in
        *"CentOS"*|*"RedHat"*|*"Fedora"*)
            rm -f /var/run/yum.pid 1> /dev/null 2>> /tmp/f8x_error.log
            rm -f /var/cache/dnf/metadata_lock.pid 1> /dev/null 2>> /tmp/f8x_error.log
            ;;
        *"Kali"*|*"Ubuntu"*|*"Debian"*)
            rm -rf /var/cache/apt/archives/lock 1> /dev/null 2>> /tmp/f8x_error.log
            rm -rf /var/lib/dpkg/lock-frontend 1> /dev/null 2>> /tmp/f8x_error.log
            rm -rf /var/lib/dpkg/lock 1> /dev/null 2>> /tmp/f8x_error.log
            rm -rf /var/lib/apt/lists/lock 1> /dev/null 2>> /tmp/f8x_error.log
            apt-get --fix-broken install 1> /dev/null 2>> /tmp/f8x_error.log
            rm -rf /var/cache/apt/archives/lock 1> /dev/null 2>> /tmp/f8x_error.log
            rm -rf /var/lib/dpkg/lock-frontend 1> /dev/null 2>> /tmp/f8x_error.log
            rm -rf /var/lib/dpkg/lock 1> /dev/null 2>> /tmp/f8x_error.log
            rm -rf /var/lib/apt/lists/lock 1> /dev/null 2>> /tmp/f8x_error.log
            ;;
        *) ;;
    esac

}
```

这里由于不同发行版锁文件都不同,依旧做了版本判断

---

# 单文件还是多文件?

在开发过程中也考虑过采用多文件的方式进行编写,拆分一下结构,后来想一想,本来就是个脚本,在搞5、6个文件夹，没有意义，脚本就是要快，一条命令安装，一条命令使用✌

---

# 混淆

之前接触混淆还是在搞免杀的时候,顺手一搜,没想到 shell 也有混淆的项目,https://github.com/Bashfuscator/Bashfuscator

还原是比较困难了,但是用在项目上没啥意义,也许以后渗透中 bypass 命令执行时可以用到🤔
