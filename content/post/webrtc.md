---
title: "浏览器特征追踪对抗"
date: 2023-01-19T12:00:00+08:00
draft: false
author: "r0fus0d"
categories: ["技术"]

---

前一段时间看到了 [Heimdallr](https://github.com/graynjo/Heimdallr) 项目,感觉非常有用,学习下几个功能的实现

<!--more-->

---

# WebRTC

WebRTC，名称源自网页即时通信（英语：Web Real-Time Communication）的缩写，是一个支持网页浏览器进行实时语音对话或视频对话的 API。

WebRTC采用STUN（Session Traversal Utilities for NAT）、TURN和ICE等协议栈对VoIP网络中的防火墙或者NAT进行穿透。用户发送请求至服务器，STUN服务器会返回用户所用系统的IP地址和局域网地址。返回的请求可以通过JavaScript获取，但由于这个过程是在正常的XML/HTTP请求过程之外进行的，所以在开发者控制台看不到。

可以在这个站点测试 [https://ip.voidsec.com/](https://ip.voidsec.com/)

![Untitled](../../img/webrtc/Untitled.png)

在页面源码中可以看到是向google的stun服务器发送请求

```bash
<script type="58f67369e5bd5410552801c0-text/javascript">
			function findIP(onNewIP) {
				var myPeerConnection = window.RTCPeerConnection || window.mozRTCPeerConnection || window.webkitRTCPeerConnection;
				var pc = new myPeerConnection({iceServers: [{urls: "stun:stun.l.google.com:19302"}]}),
				noop = function() {},
				localIPs = {},
				ipRegex = /([0-9]{1,3}(\.[0-9]{1,3}){3}|[a-f0-9]{1,4}(:[a-f0-9]{1,4}){7})/g,
				key;

				function ipIterate(ip) {
					if (!localIPs[ip]) onNewIP(ip);
					localIPs[ip] = true;
				}

				pc.createDataChannel("");

				pc.createOffer(function(sdp) {
					sdp.sdp.split('\n').forEach(function(line) {
						if (line.indexOf('candidate') < 0) return;
						line.match(ipRegex).forEach(ipIterate);
					});
					pc.setLocalDescription(sdp, noop, noop);
				}, noop);

				pc.onicecandidate = function(ice) {
					if (!ice || !ice.candidate || !ice.candidate.candidate || !ice.candidate.candidate.match(ipRegex)) return;
					ice.candidate.candidate.match(ipRegex).forEach(ipIterate);
				};
			}

			function addIP(ip) {
				//console.log('got ip: ', ip);
				var li = document.createElement('li');
				li.textContent = ip;
				document.getElementById("IPLeak").appendChild(li);
			}
			findIP(addIP);
		</script>
```

wireshark 抓包查看,可以看到返回包中有访问者的ip

![Untitled](../../img/webrtc/Untitled%201.png)

来看看Heimdallr插件如何做处理的

![Untitled](../../img/webrtc/Untitled%202.png)

将 `chrome.privacy.network.webRTCIPHandlingPolicy` 配置为 `disable_non_proxied_udp` 修改浏览器WebRTC IP 处理策略

再次访问

![Untitled](../../img/webrtc/Untitled%203.png)

在火狐中类似的配置，在地址栏输入 `about:config`，搜索 `media.peerconnection.enabled` 并双击将值改为 “false”，关闭 WebRTC 。

![Untitled](../../img/webrtc/Untitled%204.png)

![Untitled](../../img/webrtc/Untitled%205.png)

---

# Canvas指纹

浏览器指纹一般是通过 Javascript 能提取或计算得到的一些具有一定**稳定性**和**独特性**的参数，而Canvas指纹也是其中的一个特征。

Canvas指纹的原理，每一种浏览器都会使用不同的图像处理引擎，不同的导出选项，不同的压缩等级，所以每一台电脑绘制出的图形都会有些许不同，这些图案可以被用来给用户设备分配特定编号（指纹），也就是说可以用来识别不同用户。

可以在这个站点测试 [https://fingerprintjs.github.io/fingerprintjs/](https://fingerprintjs.github.io/fingerprintjs/)

来看看Heimdallr插件如何做处理的,通过对当前网页注入内容脚本增加Canvas画布噪点防止特征锁定

```bash
if (HConfig.canvasInject == true){
      chrome.scripting.getRegisteredContentScripts(function(injectContentScript){
        if (injectContentScript != null && injectContentScript.length == 0){
          chrome.scripting.registerContentScripts([{"allFrames":true, "id":"HInject", "js":["resource/inject/inject.js"], "runAt":"document_start", "matches":["http://*/*","https://*/*","file://*/*"]}], function(){
              console.log("注册Content Script: Canvas interference")
            })
        }
      })
```

再来看看inject.js的内容

![Untitled](../../img/webrtc/Untitled%206.png)

访问时加载content.js

![Untitled](../../img/webrtc/Untitled%207.png)

测试指纹结果

![Untitled](../../img/webrtc/Untitled%208.png)

![Untitled](../../img/webrtc/Untitled%209.png)

---

# DNS泄漏

在某些情况下，即使连接到匿名网络，操作系统仍将继续使用其默认 DNS 服务器，而不是匿名网络分配给您的计算机的匿名 DNS 服务器。

因此向dns服务器发出的请求并不通过代理或vpn(指没有进行指定配置的情况)。

注意dns泄漏获取不到真实ip，只能用于辅助判断出口地区

可以通过这个站点进行测试 [https://dnsleaktest.com/](https://dnsleaktest.com/)

![Untitled](../../img/webrtc/Untitled%2010.png)

抓包可以看到向多个子域站点发送了请求

![Untitled](../../img/webrtc/Untitled%2011.png)

**如何防止dns泄漏的问题**

就以burp为例，可以设置通过socks代理服务器进行dns解析

![Untitled](../../img/webrtc/Untitled%2012.png)

再次进行测试

![Untitled](../../img/webrtc/Untitled%2013.png)

从浏览器插件的角度，对dnsleak这种探测来源地区的方式没有有效的防御方法。

---

# Source & Reference

- [https://stackoverflow.com/questions/62582674/how-to-set-the-value-of-chrome-privacy-network-webrtciphandlingpolicy-using-sele](https://stackoverflow.com/questions/62582674/how-to-set-the-value-of-chrome-privacy-network-webrtciphandlingpolicy-using-sele)
- [https://bugs.chromium.org/p/chromium/issues/detail?id=767304](https://bugs.chromium.org/p/chromium/issues/detail?id=767304)
- [https://mp.weixin.qq.com/s/qEEO-1lyFbYS7Saa2L-n0A](https://mp.weixin.qq.com/s/qEEO-1lyFbYS7Saa2L-n0A)
- [https://cloud.tencent.com/developer/article/2161459](https://cloud.tencent.com/developer/article/2161459)
- [https://github.com/aghorler/WebRTC-Leak-Prevent/blob/master/js/background.js](https://github.com/aghorler/WebRTC-Leak-Prevent/blob/master/js/background.js)