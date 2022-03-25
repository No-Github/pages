---
title: "f8x 开发记录"
date: 2021-12-01T23:08:03+08:00
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
# ===================== Modify CentOS YUM sources =====================
Update_CentOS_Mirror(){

    case $Linux_Version_Num in
        "8 Stream")
            Echo_INFOR "pass"
            ;;
        8)
            rm -f /etc/yum.repos.d/CentOS-Base.repo.bak > /dev/null 2>&1 && cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak > /dev/null 2>&1 && Echo_INFOR "Backed up Yum sources"
            curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo > /dev/null 2>&1 && Echo_INFOR "Downloaded aliyun Yum sources" || Echo_ERROR "aliyun Yum sources download failed,"
            ;;
        7)
            rm -f /etc/yum.repos.d/CentOS-Base.repo.bak > /dev/null 2>&1 && cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak > /dev/null 2>&1 && Echo_INFOR "Backed up Yum sources"
            curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo > /dev/null 2>&1 && Echo_INFOR "Downloaded aliyun Yum sources" || Echo_ERROR "aliyun Yum sources download failed,"
            ;;
        6)
            rm -f /etc/yum.repos.d/CentOS-Base.repo.bak > /dev/null 2>&1 && cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak > /dev/null 2>&1 && Echo_INFOR "Backed up Yum sources"
            curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-6.repo > /dev/null 2>&1 && Echo_INFOR "Downloaded aliyun Yum sources" || Echo_ERROR "aliyun Yum sources download failed,"
            ;;
        *)
            Echo_ERROR "Version error"
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
                *"impish"*)
                    Linux_Version_Num="21.10"
                    Linux_Version_Name="impish"
                    ;;
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
                ...
                *)
                    Echo_ERROR "Unknown Ubuntu Codename"
                    exit 1
                    ;;
            esac
            ;;
```

然并卵,在部分云平台的机器中,甚至连 `/etc/*-release` 文件都没有!要么就是直接把 `/etc/*-release` 文件改的妈都不认识,说的就是你,Azure

所以在后来的版本中加上了手动输入发行版的功能
```bash
            Echo_ERROR "Unknown version"
            echo -e "\033[1;33m\nPlease enter distribution Kali[k] Ubuntu[u] Debian[d] Centos[c] RedHat[r] Fedora[f] AlmaLinux[a] VzLinux[v] Rocky[r]\033[0m" && read -r input
            case $input in
                [kK])
                    Linux_Version="Kali"
                    ;;
                [uU])
                    Linux_Version="Ubuntu"
                    echo -e "\033[1;33m\nPlease enter the system version number [21.10] [21.04] [20.10] [20.04] [19.10] [18.04] [16.04] [15.04] [14.04] [12.04]\033[0m" && read -r input
                    Linux_Version_Name=$input
                    ;;
                [dD])
                    Linux_Version="Debian"
                    echo -e "\033[1;33m\nPlease enter the system version number [11] [10] [9] [8] [7]\033[0m" && read -r input
                    Linux_Version_Name=$input
                    ;;
                [cC])
                    Linux_Version="CentOS"
                    echo -e "\033[1;33m\nPlease enter the system version number [8] [7] [6]\033[0m" && read -r input
                    Linux_Version_Name=$input
                    ;;
                [rR])
                    Linux_Version="RedHat"
                    ;;
                [aA])
                    Linux_Version="AlmaLinux"
                    ;;
                [fF])
                    Linux_Version="Fedora"
                    echo -e "\033[1;33m\nPlease enter the system version number [34] [33] [32]\033[0m" && read -r input
                    Linux_Version_Name=$input
                    ;;
                [vV])
                    Linux_Version="VzLinux"
                    ;;
                [rR])
                    Linux_Version="Rocky"
                    ;;
                *)
                    Echo_ERROR "Unknown version"
                    exit 1
                    ;;
            esac
```

目前我也没没有找到较好的解决方案,以 docker 官方的安装脚本 https://get.docker.com 为例,在部分 kali 是无法运行的,因为 kali 不分具体版本号,直接不兼容了🤣

![](../../img/f8x/1.png)

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

```bash
f8x -update
```

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

每次 f8x 的更新,action 都会自动运行,对 f8x 实际效果感兴趣的话,但手头没有机器的,不妨去看一下运行结果
- https://github.com/ffffffff0x/f8x/actions

在 github action 中一些需要输入的情况会被忽略或报错,这与之前的代理请求造成了冲突,于是添加了一个 /tmp/IS_CI 的判断,在 action 运行开始就创建这个文件,f8x 检测到这个文件存在就默认忽略代理

![](../../img/f8x/7.png)

![](../../img/f8x/8.png)

这里要说明一下,action 里面部分工具安装失败有以下几种原因:
1. 机器内存不够
2. 无法进行交互,比如按 Y/N
3. python 库找不到(这个是大坑)

---

# 锁

想必你一定见过以下这种报错
```
无法获得锁 /var/lib/apt/lists/lock - open (11: 资源暂时不可用)

E: Unable to correct problems, you have held broken packages.

dpkg: error: parsing file '/var/lib/dpkg/updates/0023' near line 0

/var/run/yum.pid 已被锁定，PID 为 1610 的另一个程序正在运行。
另外一个程序锁定了 yum；等待它退出……
```

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

这里由于不同发行版锁文件都不同,依旧做了版本判断,当运行时,会自动除锁

当然,你也可以手动运行进行除锁
```
f8x -rmlock
```

---

# 单文件还是多文件?

在开发过程中也考虑过采用多文件的方式进行编写,拆分一下结构,后来想一想,本来就是个脚本,在搞5、6个文件夹，没有意义，脚本就是要快，一条命令安装，一条命令使用✌

---

# 混淆

之前接触混淆还是在搞免杀的时候,顺手一搜,没想到 shell 也有混淆的项目,https://github.com/Bashfuscator/Bashfuscator

还原是比较困难了,但是用在项目上没啥意义,也许以后渗透中 bypass 命令执行时可以用到🤔

---

# 供应链安全

2021-4-22 : 最近正好护网，某红队人员公开了 weblogic_cmd_plus ,没想到带后门,看到 DeadEye安全团队发的文章才意识到被黑吃黑了🤣

总结经验教训
- 以后要少用直接打包,不公开源码的工具
- "开源软件"做混淆,必有蹊跷
- 用之前,传vt扫一下把
- 只在vps跑工具

---

## 问题解答

### 我需要的工具不在里面怎么办?

直接提 issue ,说明工具名称和项目地址

### 为啥不直接装 kali?

kali 是非常优秀的发行版，f8x 配合 kali 可以让你的工具库更加全面。并且支持各种 ctf 工具的安装。

所以不是为了代替什么,更多的是辅助

### f8x 未来的方向？

目前 f8x 已经可以做到兼容大部分 linux 发行版，并且支持部署 120+ 款安全工具，所以后续将不断优化兼容性，更新软件版本号等

而 f8x-ctf 还有大量的工作要完成，例如 web、iot、pwn 等方向工具的添加，所以后续重头会放在 f8x-ctf 上

### 如何保证安装的工具的安全性

工具大部分都是从 github 官方仓库下载，少部分如 anew、marshalsec 为我自己 fork 并编译 release

剩下一些无法直接官方下载的，比如 cs、jdk 等，我就传到 github 仓库中做存档

对安全性存疑，可以手动删除这些下载的工具

### 目前兼容那些 linux

测试过的
* Ubuntu (12.04/14.04/15.04/16.04/18.04/19.10/20.04/20.10/21.04/21.10)
* CentOS (6/7/8/8 Stream)
* Debian (7/8/9/10/11)
* Fedora (32/33/34/35)
* Kali (2020/2021)
* AlmaLinux
* VzLinux
* Rocky

### 后续会不会做出 win、mac 版本的 f8x

win 版本不太可能，mac 版有想法，明年可以试下

### 结尾在推荐几个我们的项目

* 1earn - ffffffff0x 团队维护的安全知识框架 - https://github.com/ffffffff0x/1earn
* AboutSecurity - 用于渗透测试的 payload 和 bypass 字典 - https://github.com/ffffffff0x/AboutSecurity
* Digital-Privacy - 关于数字隐私搜集、保护、清理集一体的方案,外加开源信息收集(OSINT)对抗 - https://github.com/ffffffff0x/Digital-Privacy
* BerylEnigma - 为渗透测试与CTF而制作的工具集 - https://github.com/ffffffff0x/BerylEnigma

整个使用过程中遇到的任何问题，欢迎在项目 issue 提出,我会及时解答并处理
