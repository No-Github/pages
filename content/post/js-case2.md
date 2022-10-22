---
title: "[技术]前端攻防案例续集"
date: 2022-09-19T01:00:00+08:00
draft: false
author: "r0fus0d & kitezzzGrim"

---

参考 kitezzzGrim 分享的案例做个总结

<!--more-->

---

# 一个 DES 案例

登录点就不放图了，先抓个包看看

![](../../img/js-case2/1.png)

可以看到目标站点对username和password都进行了加密

f12 看看 js

![](../../img/js-case2/2.png)

挺好，直接表示了是 des 加密，还用的 des.js

那么其实现在在控制台就可以调用加密函数了
```js
DES.Encrypt("admin")
```

![](../../img/js-case2/3.png)

当然，我们可以看下 des.js 文件，找下key

![](../../img/js-case2/4.png)

做了混淆，搜了下，是类似 eval(function(p,a,c,k,e,r){}) 的加密，有在线还原的站点
- https://wangye.org/tools/scripts/eval/

![](../../img/js-case2/5.png)

得到 key

---

# 一个 AES 案例

登录点不放图

随便输个账户密码，抓包看看

![](../../img/js-case2/6.png)

f12 看下

![](../../img/js-case2/7.png)

从以上代码可以看出userLogin()函数中调用encrypt()函数对用户名和进行了加密

挺好，控制台可调
```js
encrypt('admin')
```

![](../../img/js-case2/8.png)

接下来查看encrypt()函数

![](../../img/js-case2/9.png)

可以看出使用了AES加密，ECB模式，填充模式pkcs7padding，密钥key=1234567887654321

![](../../img/js-case2/10.png)

---

# BurpCrypto 插件

上面那2个案例可以配合这个插件进行爆破

- https://github.com/whwlsfb/BurpCrypto

![](../../img/js-case2/11.png)

![](../../img/js-case2/12.png)

---

# 一个 RSA 案例

登录点不放图

随便输个账户密码，抓包看看

![](../../img/js-case2/13.png)

长的一比，很大可能是rsa加密

f12 看下

![](../../img/js-case2/14.png)

可以看到publickey和encodeRSA关键字，目标站点对用户和密码都进行了rsa加密，但我们可以利用公钥加密字典来进行爆破

此时，控制台可调
```js
var publicKey = 'xxxxx';
encodeRSA('admin', publicKey)
```

![](../../img/js-case2/15.png)

![](../../img/js-case2/16.png)

---

# 总结

前端加密用JSEncrypt库的很多，为了节省时间，可以直接试试搜一些jsencrypt相关的方法名，如setPublicKey、encrypt等,定位加密函数
