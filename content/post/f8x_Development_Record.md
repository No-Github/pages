---
title: "f8x 开发日计"
date: 2021-03-02T23:08:03+08:00
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

![](https://gitee.com/asdasdasd123123/pic/raw/master/blog/3/2.png)

![](https://gitee.com/asdasdasd123123/pic/raw/master/blog/3/3.png)

f8x 工具中使用 `cat /etc/*-release | head -n 1` 来匹配发行版和具体版本,期间也使用过 `lsb_release -c` 命令,但是在 docker 环境中无法兼容,所以使用上述命令来提高兼容性

![](https://gitee.com/asdasdasd123123/pic/raw/master/blog/3/4.png)

然并卵,在部分云平台的机器中,甚至连 `/etc/*-release` 文件都没有!要么就是直接把 `/etc/*-release` 文件改的妈都不认识,说的就是你,Azure

所以在后来的版本中加上了手动输入发行版的功能

![](https://gitee.com/asdasdasd123123/pic/raw/master/blog/3/5.png)

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

![](https://gitee.com/asdasdasd123123/pic/raw/master/blog/3/6.png)

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

![](https://gitee.com/asdasdasd123123/pic/raw/master/blog/3/9.png)

这里由于不同发行版锁文件都不同,依旧做了版本判断

---

# 单文件还是多文件?

在开发过程中也考虑过采用多文件的方式进行编写,拆分一下结构,后来想一想,本来就是个脚本,在搞5、6个文件夹，没有意义，脚本就是要快，一条命令安装，一条命令使用✌