---
title: "CVE-2024-38077 打补丁补充"
date: 2024-08-12T12:00:00+08:00
draft: false
author: "r0fus0d"
categories: ["技术","杂项","蓝队"]

---

某大型多人运动已展开数周，由于0day 通报，估计大家都在忙着打CVE-2024-38077的补丁

自己在打补丁时遇到了不少坑，在此补充打补丁的一些信息

<!--more-->

---

## 前置补丁和目标补丁

直接下载目标补丁是不能装的，得安装前置补丁
```
windows server 2008
kb5039341 --> KB5040490

windows server 2008 R2
kb4474419 --> kb5039339 --> KB5040498
KB4522133?--> kb5039339 --> KB5040498

windows server 2012
KB5040570 --> KB5040485

windows server 2012 R2
KB5040569 --> KB5040456

windows server 2016
kb5040562 --> KB5040434

windows server 2019
kb5005112 --> KB5040430
```

## 08/12系统打不上的 bypass 方案

有人开阿里云 win08 验证打补丁方案，这个和实际场景是不一样的，阿里云的 08 是自带的 ESU 的，但是实际生产环境里除非用破解方案不然不带 ESU 是打不上的。

BypassESU-v12_u.7z

Windows 7 和 Server 2008 R2 ESU 更新绕过工具

- [https://forums.mydigitallife.net/threads/bypass-windows-7-extended-security-updates-eligibility.80606/](https://forums.mydigitallife.net/threads/bypass-windows-7-extended-security-updates-eligibility.80606/)

BypassESU-Blue-v2.7z

Windows 8 and Server 2012 R2 ESU 更新绕过工具

- [https://forums.mydigitallife.net/threads/bypass-esu-blue.86548/](https://forums.mydigitallife.net/threads/bypass-esu-blue.86548/)
