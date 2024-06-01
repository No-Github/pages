---
title: "代理检测"
date: 2024-06-01T12:00:00+08:00
draft: false
author: "r0fus0d"
categories: ["技术"]

---

{{% admonition info "info" %}}
书接上文 https://r0fus0d.blog.ffffffff0x.com/post/webrtc/ 来看看检测 bp/代理访问 有哪些方法
{{% /admonition %}}

<!--more-->

---

# burp favicon

[http://burp/favicon.ico](http://burp/favicon.ico) 路径有 icon 图标

![Untitled](../../img/proxy-case/Untitled.png)

检测方式

```html
<h2 id='indicator'>Loading...</h2>
<script>
    function burp_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'Burp FOUND !!!';
    }

    function burp_not_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'Burp not found.';
    }
</script>
<img style="display: none;" src='http://burp/favicon.ico' onload='burp_found()' onerror='burp_not_found()'/>
```

![Untitled](../../img/proxy-case/Untitled%201.png)

用 heimdallr 可以阻断请求

![Untitled](../../img/proxy-case/Untitled%202.png)

也可以在 Proxy -> Options -> Miscellaneous 中勾选 Disable web interface at [http://burp](http://burp/)

![Untitled](../../img/proxy-case/Untitled%203.png)

或者是删除 jar 包中的 favicon.ico

```
zip -d burpsuite_pro.jar "resources/Media/favicon.ico"
```

---

# burp 导出证书接口

[http://burp/cert](http://burp/cert) 是下证书的接口

![Untitled](../../img/proxy-case/Untitled%204.png)

检测方法类似

```html
<h2 id='indicator'>Loading...</h2>
<script>
    function burp_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'Burp FOUND !!!';
    }

    function burp_not_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'Burp not found.';
    }
</script>
<script style="display: none;" src='http://burp/cert' onload='burp_found()' onerror='burp_not_found()'></script>
```

可以在 Proxy -> Options -> Miscellaneous 中勾选 Disable web interface at [http://burp](http://burp/)

---

# 报错页面

除此上面 2 种之外，还有个广为流传的检测方法，就是访问个不存在的页面

正常浏览器

![Untitled](../../img/proxy-case/Untitled%205.png)

挂了 burp 后

![Untitled](../../img/proxy-case/Untitled%206.png)

网上的一种检测方式

```html
<h2 id='indicator'>Loading...</h2>
<script>
    function burp_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'Burp FOUND !!!';
    }

    function burp_not_found() {
        is_burp_not_found = true;
        let e = document.getElementById('indicator');
        e.innerText = 'Burp not found.';
    }
</script>
<script>
    fetch('http://not_exists_domain/not_exist', {method: 'GET', mode: 'no-cors'}).then((r)=>{burp_found();}).catch((e)=>{burp_not_found();});
    // 200 -> fetch 成功, 触发 then, burp 存在. 超时 -> fetch 失败, 触发 catch, burp 不存在.
</script>
```

不知道在哪里看到的修复方案，在 Proxy -> Options -> Miscellaneous 中勾选 Suppress Burp error messages in browser

然而，实际测试，发现就算勾选了502也是一样 检测出有 burp

![Untitled](../../img/proxy-case/Untitled%207.png)

所以，为啥 502 也是检测成功呢？原因就是这个检测脚本有 bug

![Untitled](../../img/proxy-case/Untitled%208.png)

顺便一提，edge 不走代理，默认也是返 502

![Untitled](../../img/proxy-case/Untitled%209.png)

要是用这方法实际部署检测，那误报会有点多

我理解，旧版本 burp 在访问不存在的地址时可能会返 200，但随着 burp 版本迭代，这个检测方法失去了通用性

---

# 浏览器扩展判断(burp)

在console可以通过输入`navigator.plugins`来获取扩展信息

![Untitled](../../img/proxy-case/Untitled%2010.png)

但是这无法用来获取插件信息，那么如何判断浏览器安装的扩展信息呢?

比如在burp自带的chromium中，默认就安装并启用了扩展`Burp Suite`

![Untitled](../../img/proxy-case/Untitled%2011.png)

我们如何判断访问者是否安装这个扩展呢，经过搜索不难得知，我们可以通过判断扩展的资源是否存在来确认

比如

```jsx
var extensionid = '扩展的id';
 
var image = document.createElement('img');
image.src = 'chrome-extension://' + extensionid + '/icon.png';
image.onload = function () {
    setTimeout(function () {
        alert('installed-enabled');
    }, 2000);
};
image.onerror = function () {
    alert('not-installed');
};
```

当`'chrome-extension://' + extensionid + '/icon.png'`路径的资源存在时，我们便可以认为目标安装了burp插件

找找burp插件默认有哪些资源

![Untitled](../../img/proxy-case/Untitled%2012.png)

![Untitled](../../img/proxy-case/Untitled%2013.png)

可以，就`'chrome-extension://' + extensionid + '/images/BurpSuite-Container-16.png'`路径即可

测试一下

![Untitled](../../img/proxy-case/Untitled%2014.png)

搜下报错，原来扩展的web_accessible_resources配置控制着扩展可被外部页面访问的资源

看下burp manifest.json的web_accessible_resources配置

![Untitled](../../img/proxy-case/Untitled%2015.png)

找个可以访问

```html
<!DOCTYPE HTML>
<html>
<body>
<script>
var extensionid = 'mjkpmmepbabldbhphljoffinnkgncjkm';
 
var image = document.createElement('img');
image.src = 'chrome-extension://' + extensionid + '/images/BurpSuite-Container-16.png';
image.onload = function () {
    setTimeout(function () {
        alert('installed-enabled');
    }, 2000);
};
image.onerror = function () {
    alert('not-installed');
};
</script>
</body>
</html>
```

![Untitled](../../img/proxy-case/Untitled%2016.png)

同理，对其他扩展的检测也可以这么做

> burp本地插件的id是随机的😅,但是其他本地插件不是比如Heimdallr
> 

当然如果硬是要多找几种检测指定扩展的方法，不如直接搜 “如何检测adblock” 将其思路进行运用😙

---

# 浏览器扩展判断(Heimdallr)

这个和burp有点不同，因为content.js是js文件不能当图片进行加载判断

```jsx
<!DOCTYPE HTML>
<html>
<body>
<script>
var extensionid = 'kkggffkhdfcdcijcokeoajakgilejmka';

var script = document.createElement('script');
script.src = 'chrome-extension://' + extensionid + '/resource/inject/content.js';
document.getElementsByTagName('head')[0].appendChild(script);
script.onload = function () {
    alert('检测到安装Heimdallr');
};
script.onerror = function () {
    alert('not-installed');
};
</script>
</body>
</html>
```

![Untitled](../../img/proxy-case/Untitled%2017.png)

---

# 时间一致性

- https://proxy.incolumitas.com/proxy_detect.html?loc=us

对比访问 IP时区 与 浏览器时区来判断是否是通过代理访问

如果检测是代理池/vpn会有用，如果检测是 bp 可能没啥用

---

# Yakit favicon

和 bp 类似

- [http://mitm/static/favicon.ico](http://mitm/static/favicon.ico)

```
<h2 id='indicator'>Loading...</h2>
<script>
    function yakit_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'yakit FOUND !!!';
    }

    function yakit_not_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'yakit not found.';
    }
</script>
<img style="display: none;" src='http://mitm/static/favicon.ico' onload='yakit_found()' onerror='yakit_not_found()'/>
```

![Untitled](../../img/proxy-case/Untitled%2018.png)

---

# Yakit 导出证书接口

和 bp 类似

- [http://mitm/download-mitm-crt](http://mitm/download-mitm-crt)

```
<h2 id='indicator'>Loading...</h2>
<script>
    function Yakit_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'Yakit FOUND !!!';
    }

    function Yakit_not_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'Yakit not found.';
    }
</script>
<script style="display: none;" src='http://mitm/download-mitm-crt' onload='Yakit_found()' onerror='Yakit_not_found()'></script>
```

![Untitled](../../img/proxy-case/Untitled%2019.png)

---

# xray 导出证书接口

和 bp 类似

- [http://proxy.xray.cool/ca.crt](http://proxy.xray.cool/ca.crt)

```
<h2 id='indicator'>Loading...</h2>
<script>
    function Xray_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'Xray FOUND !!!';
    }

    function Xray_not_found() {
        let e = document.getElementById('indicator');
        e.innerText = 'Xray not found.';
    }
</script>
<script style="display: none;" src='http://proxy.xray.cool/ca.crt' onload='Xray_found()' onerror='Xray_not_found()'></script>
```

![Untitled](../../img/proxy-case/Untitled%2020.png)