---
title: "弱口令案例大礼包"
date: 2022-03-30T08:08:03+08:00
draft: false
author: "r0fus0d"
categories: ["技术"]

---

最近翻看以前的渗透案例,发现不少有意思的入口点,基本都是弱口令+信息泄漏打进去,然后这里上传那里注入这样的后台打法,干脆总结个弱口令案例分享出来

{{% admonition info "info" %}}
关键信息均已打码,漏洞均已提交 edusrc 和 cnvd 并修复
{{% /admonition %}}

<!--more-->

---

# 某学院学工系统信息泄漏案例

通过前期的信息收集找到目标学院的一个学工系统登录点

![](../../img/weak-password/1.png)

这一看就是 ruoyi 的站嘛。。直接用ruoyi 默认的 admin 和 ry 账号去测试登录,提示没有该用户，那尝试其他渠道搜集下用户

右下角有个明晃晃的在线帮助文档，点进去看看

![](../../img/weak-password/2.png)

文档描述对应小程序的使用方法，不过这个不是重点，翻到最下面

![](../../img/weak-password/3.png)

默认123456，肯定有很多学生是不改的，那这只剩下弄到用户了，这2张图上有登录的账号，放大看看

![](../../img/weak-password/4.png)

可以，收获一个学号，不过注意到这个帮助文档有不同用户角色的介绍，点击任务发布者的看看

> 管理员的我点进去，他全部删干净了，啥都没有

![](../../img/weak-password/5.png)

点击图片详情，上面是任务发布者权限账号

现在到后台测试登录，很幸运，任务发布者和学生的这2个账号都没有修改过密码

![](../../img/weak-password/6.png)

那剩下的就简单了，后台翻翻，找到了一个查询点，里面有学生的任务记录，关键是响应包里有相应的学号，直接导出json格式的返回包

![](../../img/weak-password/7.png)

用jq进行格式化处理，得到学号信息，由于有验证码无法批量爆破,手动测试了几个,基本都是 123456，这波收集到大量的学生学号，测这个学校其他分站就容易多了

![](../../img/weak-password/8.png)

---

# 根据官网上的人员姓名生成字典突破的案例

这个站没截前台的图，只有后台的图，大致描述下，主页有个主要领导的链接，点进去是这个单位的一些领导的介绍，复制名字，根据中文用户名生产用户名字典

比如
```
张三
zhangsan
zhangs
san.zhang
zs
```

后来证明我想多了，他用户名就是中文的。。。。。

![](../../img/weak-password/9.png)

![](../../img/weak-password/10.png)

---

# 三顾茅庐的某站点

为啥说是三顾茅庐呢，因为这个站测了3次，修了3次

![](../../img/weak-password/11.png)

第一次，admin/123456,没啥好说的

第二次,发现有sourcemap，下载下来，用shuji进行还原
```
wget https://xx.xxxxxx.com/xxxxx/static/js/app.aa2478xxxxxxxxxe0c.js.map

shuji xxxx.map -o folder
```

![](../../img/weak-password/12.png)

在js中翻到有2个vue的变量 /api 和 /dev_liufeng

猜想这个 liufeng 会不会是测试人员的姓名呢，登录试试

![](../../img/weak-password/13.png)

好吧

第三次，在历经了前2次的测试后，按弱口令爆破顺序，依次爆破账号
```
常见用户名
中文名转拼音
数字/工号
常用测试邮箱
常用测试手机号
```

终于，在爆破到测试手机号的时候，又爆破出来了

![](../../img/weak-password/14.png)

![](../../img/weak-password/15.png)
