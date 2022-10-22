---
title: "前端攻防几个小案例"
date: 2022-09-06T12:00:00+08:00
draft: false
author: "r0fus0d & kitezzzGrim"

---

俗话说好记性不如烂笔头,记录一些平时测试的案例，省的下次遇到再重新摸索

{{% admonition info "info" %}}
关键信息均已打码,漏洞均已提交相关 src 修复
{{% /admonition %}}

<!--more-->

---

# 登陆点1

常规前端加密,f12找password加密JS代码来进行一个爆破

![](../../img/js-case/10.png)

这里是password的关键算法代码，可以看出该key，猜测是用了des加密

寻找password多断点，然后在登录框输入密码

![](../../img/js-case/14.png)

进入调试状态，一步步调试到加密算法这一步

不难猜出，s是加密后的结果，`object(l["a"])`是加密函数，e.loginform.password是输入的密码，后面就是key值。

所以我们可以编写一个js代码测试，输入的密码为jfhack
```js
let jiami = Object(l["a"])("jfhack", "6c81d5508f6578f7a6071e70");console.log(jiami);
```

控制台调用加密函数测试

![](../../img/js-case/12.png)

用 cyberchef 测试

![](../../img/js-case/13.png)

可以看到加密是一致的，这里可以直接控制台用js来生成字典

```js
let iii = 0;
let passdic = new Array();
passdic = ['123456','000000','88888']  // 这里写字典
for (iii=0;iii<passdic.length;iii++){
    let jiami = Object(l["a"])(passdic[iii], "6c81d5508f6578f7a6071e70");
    console.log(jiami);
}
```

---

# 登陆点2

遇到另外一个系统，密码也加密了，但密码好像加入了时间算法会一直变化。

![](../../img/js-case/15.png)

![](../../img/js-case/16.png)

关键代码是:

```js
data.password = common.encryptPassword(data.password);
```

于是编写了如下JS代码

```js
let jiami =common.encryptPassword('123');jiami
```

![](../../img/js-case/17.png)

可以看到 多次输出一样的原生密码，加密后的密码是一直在变化

后面有朋友提示思路，可以编写JS触发发包，无需写生成字典的JS代码，这个要根据目标登录部分的代码进行修改，参考代码如下：

```js
const array1 = ['a', 'b', 'c'];

array1.forEach(element => {
    // console.log(element)
    e.loginForm.password = element
    e.$store.dispatch("user/login" , e.loginForm)
});
```

---

# jsrpc 练手案例

看了 https://www.svenbeast.com/post/kn2fEdp4Q/ 的案例后，发现 jsrpc 可以很方便的满足我们js加密场景的一些需求，然后便找了一个站进行测试。

先简单抓个包看下密文

![](../../img/js-case/1.png)

`ec6a6536ca304edf844d1d248a4f08dc`,去 cmd5 反查下就知道了是2次md5

![](../../img/js-case/2.png)

这种情况一般直接在 burp 的 intruder 模块中，payload processing 进行处理即可

这里用jsrpc来练手，先f12找相关的加密函数

小技巧
- 全局搜索登陆点 url
- 全局搜索 password、encrypto 这种关键词

![](../../img/js-case/3.png)

![](../../img/js-case/4.png)

其实这里可以看到,目标就是直接调用的 https://github.com/emn178/js-md5 库

不管，装作看不见👀，现在目标是通过jsrpc实现，只要找到加密函数就行

在控制台，对js中的函数和值进行输出，看是否可以得到我们需要的结果

![](../../img/js-case/5.png)

参考项目issue https://github.com/jxhczhl/JsRpc/issues/4 中的方法可以将局部函数暴露给全局使用，这样就不用卡在断点中去调用函数了(ps:举个例,我这个场景比较简单，都不需要断点)

```
window.test = md5
test(test('1234'));
```

![](../../img/js-case/6.png)

此时控制台能正常调用加密函数了，也把目标函数改为全局函数了，接下来控制台直接复制 jsenv.js 的代码,同时本地启动 jsrpc 服务,连接通信
```
var demo = new Hlclient("ws://127.0.0.1:12080/ws?group=zzz&name=hlg");
```

在控制台注册js方法 通过传递函数名调用
```js
demo.regAction("testtttt", function (resolve,param) {
    console.log(param);
    var testttt123 = test(test(param));
    resolve(testttt123);
})
```

访问远程调用
```
http://127.0.0.1:12080/go?group=zzz&name=hlg&action=testtttt&param='1234'
```

![](../../img/js-case/9.png)

后续可以参考文章 https://www.svenbeast.com/post/kn2fEdp4Q/ 中的方案，通过本地 mitm 自动替换 payload,进行爆破

**能不能在控制台直接触发发包**

当然可以，将目标发送请求的部分修改后在控制台执行即可

```js
axios.post("/******/login", {name: "admin",password: test(test('1234'))})
```

![](../../img/js-case/19.png)
