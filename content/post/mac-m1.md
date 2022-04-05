---
title: "mac m1 能不能作为安全渗透工作主力机"
date: 2022-04-05T08:08:03+08:00
draft: false
author: "r0fus0d"

---

年初换了自己的主力机成 macbook ,由于是 arm 架构，一开始还比较担心兼容性问题，不过在实际使用了2个月后发现其实大部分兼容问题都可以解决，下面分享一些使用体验和解决方案。

<!--more-->

---

# 能不能打游戏

不能，开windows虚拟机也勉强不了，如果要开黑玩游戏，还是用 windows

---

# 能不能完成渗透任务

可以，基本没有问题

目前许多渗透软件都是开源的，大部分都是 python、go、java 平台的，python 和 java就不用说了，自己安装好环境，直接 clone 下来运行或编译就行，go的话，除了自己编译，大部分现在也提供了 mac 平台 arm 架构 的打包版本。

以 f8x 中的渗透工具为例，在 mac 上基本都可以安装，就算有个别确实安装不了，在 linux 虚拟机上也是可以运行的，目前 f8x 已支持在 linux arm 架构上进行安装

![](../../img/mac-m1/1.png)

---

# 能不能运行 windows 虚拟机

可以，前提是你需要(购买/弄到) Parallels 虚拟机软件

![](../../img/mac-m1/2.png)

![](../../img/mac-m1/3.png)

而且目前只能运行 windows11 arm 虚拟机，其他windows版本都不行

当然 windows11 arm 虚拟机里可以直接运行 x86,x64,arm 应用，兼容性还不错

---

# 刚需

- 虚拟机软件 (Parallels)
    - VMware Fusion 说实话没有 Parallels 好用,如果条件允许，买个 Parallels 会方便很多
- 内存要大
    - 不知道是不是我使用方式的问题，只开 chrome 微信啥的日常占用就 10G 了,选购的时候内存往上加加吧

---

# 细节调优

国光师傅的这3篇文章介绍了 mac 系统下的一些配置优化调整，非常全，推荐
- https://www.sqlsec.com/2022/01/monterey.html
- https://www.sqlsec.com/2019/12/macos.html
- https://www.sqlsec.com/2019/11/macbp.html

我自己也总结了mac的使用技巧和备忘录
- https://github.com/ffffffff0x/1earn/blob/master/1earn/Plan/Mac-Plan.md
