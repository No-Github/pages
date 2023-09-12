---
title: "浅谈 ja3"
date: 2023-09-12T12:00:00+08:00
draft: false
author: "r0fus0d"
categories: ["技术"]

---

ja3是蓝队的好朋友

<!--more-->

---

# 什么是ja3

JA3 是一种 TLS 指纹识别方法

ja3 由 `ClientHello 的版本`、`可接受的加密算法`、`扩展列表中的每一个 type 值`、`支持的椭圆曲线`和`支持的椭圆曲线格式` 生成

## 如何计算ja3值

计算ja3值，也就是提取客户端发送的 TLS 握手包的 Client Hello 部分的 Version/Cipher Suites/Extensions 值，再 md5 一下

在[https://github.com/salesforce/ja3](https://github.com/salesforce/ja3)项目中提供了计算指定pcap包里tls指纹的工具

这里我抓取一下本地burp访问随便一个ip的tls握手包，计算一下看看

```bash
git clone https://github.com/salesforce/ja3
cd ja3/python

python3 ja3.py test.pcap
```

![Untitled](../../img/ja3/Untitled.png)

wireshark也很贴心的提供了ja3的值,直接找到握手包展开详情就可以看到

![Untitled](../../img/ja3/Untitled%201.png)

```bash
[JA3 Fullstring [truncated]: 771,4866-4865-4867-49196-49195-52393-49200-52392-49199-159-52394-163-158-162-49188-49192-49187-49191-107-106-103-64-49198-49202-49197-49201-49190-49194-49189-49193-49162-49172-49161-49171-57-56-51-50-49157-49167-49156-49166-157-156-61-60-53-47-49160-49170-22-19-49155-49165-10-255,5-10-11-17-23-35-13-43-45-50-51,29-23-24-25-30-256-257-258-259-260,0]
[JA3: dc44ae2eaf1dba93fa619c437fb20ca4]
```

这里也可以手动计算一下，看看具体的实现

先看下这个包的 Version + Cipher Suites

![Untitled](../../img/ja3/Untitled%202.png)

依次为转换为16进制为

```bash
771 4866 4865 4867 49196 49195 52393 后面略。。
```

再看下 Extensions 部分

![Untitled](../../img/ja3/Untitled%203.png)

对应的第二段

```bash
5-10-11-17-23-35-13-43-45-50-51
```

最后，再看到Extension: supported_groups

![Untitled](../../img/ja3/Untitled%204.png)

```bash
29-23-24-25-30-256-257-258-259-260
```

最后的最后，看到Extension: ec_point_formats

![Untitled](../../img/ja3/Untitled%205.png)

```bash
0
```

组合起来就是

```bash
771,4866-4865-4867-49196-49195-52393-49200-52392-49199-159-52394-163-158-162-49188-49192-49187-49191-107-106-103-64-49198-49202-49197-49201-49190-49194-49189-49193-49162-49172-49161-49171-57-56-51-50-49157-49167-49156-49166-157-156-61-60-53-47-49160-49170-22-19-49155-49165-10-255,5-10-11-17-23-35-13-43-45-50-51,29-23-24-25-30-256-257-258-259-260,0
```

md5一下

![Untitled](../../img/ja3/Untitled%206.png)

与ja3.py和wireshark计算的结果一致

当我们用burp访问其他的站点时，如果抓取握手包，会发现，由于上述几个TLS 握手包的 Client Hello 部分不变，所以其ja3指纹是一致的，这也就是识别burp的一种方式，或者说特征

如下，换个目标访问,可以看到ja3结果一致

![Untitled](../../img/ja3/Untitled%207.png)

不同的软件所使用的 TLS 库是不同的，所以对于Cipher Suites和Extension的一些配置和支持也肯定不同，同时其位置顺序也会影响ja3结果的生成，所以通过 ja3 特征识别恶意客户端行为是waf、ips等安全设备的一个比较有效的识别/拦截手段。

大量客户端工具ja3指纹的维护，较为麻烦，比如webshell连接，c2连接，目前github上也没啥开源的ja3指纹库，但基于常见工具+常见编程语言版本+默认配置维护一个黑名单库，还是有价值的。

上述计算ja3指纹的方法是针对指定包进行处理的工具，如果要监听一个接口，持续不断的计算ja3指纹，那么推荐[https://github.com/Macr0phag3/ja3box](https://github.com/Macr0phag3/ja3box)这个工具

```bash
sudo python ja3box.py -i eth0
```

![Untitled](../../img/ja3/Untitled%208.png)

## sni

在文章[https://mp.weixin.qq.com/s/Cha_hTGOh-GGVkaZRdFujw](https://mp.weixin.qq.com/s/Cha_hTGOh-GGVkaZRdFujw)中,提到了域名访问和IP访问存在2个不同的ja3指纹，原因是域名有sni和ip无sni。

随便抓个包测试下,通过域名访问

```bash
771,4866-4865-4867-49196-49195-52393-49200-52392-49199-159-52394-163-158-162-49188-49192-49187-49191-107-106-103-64-49198-49202-49197-49201-49190-49194-49189-49193-49162-49172-49161-49171-57-56-51-50-49157-49167-49156-49166-157-156-61-60-53-47-49160-49170-22-19-49155-49165-10-255,0-5-10-11-16-17-23-35-13-43-45-50-51,29-23-24-25-30-256-257-258-259-260,0
dfd0bc4a6d8c21e500d6be9121fd44d7
```

通过ip访问

```bash
771,4866-4865-4867-49196-49195-52393-49200-52392-49199-159-52394-163-158-162-49188-49192-49187-49191-107-106-103-64-49198-49202-49197-49201-49190-49194-49189-49193-49162-49172-49161-49171-57-56-51-50-49157-49167-49156-49166-157-156-61-60-53-47-49160-49170-22-19-49155-49165-10-255,5-10-11-17-23-35-13-43-45-50-51,29-23-24-25-30-256-257-258-259-260,0
dc44ae2eaf1dba93fa619c437fb20ca4
```

可以发现，多出来2个，一个0，一个16，wireshark查看对应的Extensions

![Untitled](../../img/ja3/Untitled%209.png)

其中`Extension: server_name`为sni信息,点开可以看到是访问的目标域名，所以这个在ip访问的时候是没有的。

![Untitled](../../img/ja3/Untitled%2010.png)

在维护内部ja3黑名单库时，无需考虑域名结果，只需考虑ip访问结果即可，因为计算ja3时，可以忽略sni的部分,也就是通过域名访问的client hello包,忽略`Extension: server_name`和`Extension: application_layer_protocol_negotiation`2个部分，也可以计算出ip访问的ja3值。

---

## curl

curl是比较常见的命令行网络访问请求工具，我们来看下它的ja3值

在linux上curl 7.64.0的ja3值如下

```python
域名
771,4866-4867-4865-49196-49200-159-52393-52392-52394-49195-49199-158-49188-49192-107-49187-49191-103-49162-49172-57-49161-49171-51-157-156-61-60-53-47-255,0-11-10-13172-16-22-23-49-13-43-45-51-21,29-23-30-25-24,0-1-2
f436b9416f37d134cadd04886327d3e8

ip
771,4866-4867-4865-49196-49200-159-52393-52392-52394-49195-49199-158-49188-49192-107-49187-49191-103-49162-49172-57-49161-49171-51-157-156-61-60-53-47-255,11-10-13172-16-22-23-49-13-43-45-51-21,29-23-30-25-24,0-1-2
0d85f6adde9dc6aa98804d6cfa2f90c1
```

在mac上curl 7.84.0的ja3值如下

```python
域名
771,4867-4866-4865-52393-52392-52394-49200-49196-49192-49188-49172-49162-159-107-57-65413-196-136-129-157-61-53-192-132-49199-49195-49191-49187-49171-49161-158-103-51-190-69-156-60-47-186-65-49169-49159-5-4-49170-49160-22-10-255,43-51-0-11-10-13-16,29-23-24-25,0
375c6162a492dfbf2795909110ce8424

ip
771,4867-4866-4865-52393-52392-52394-49200-49196-49192-49188-49172-49162-159-107-57-65413-196-136-129-157-61-53-192-132-49199-49195-49191-49187-49171-49161-158-103-51-190-69-156-60-47-186-65-49169-49159-5-4-49170-49160-22-10-255,43-51-11-10-13-16,29-23-24-25,0
4f2655722e37c542ebeaf1eed48cbbbb
```

curl的作者在 [https://daniel.haxx.se/blog/2022/09/02/curls-tls-fingerprint/](https://daniel.haxx.se/blog/2022/09/02/curls-tls-fingerprint/) 文章中介绍了 [https://github.com/lwthiker/curl-impersonate](https://github.com/lwthiker/curl-impersonate) 这个项目，是一个修改过的curl，用来模拟真实浏览器相同的tls握手.

实际测试抓包看看

使用 curl_chrome100 访问几个站点试试

![Untitled](../../img/ja3/Untitled%2011.png)

可见，ja3box给出了不同的ja3结果，但ja3_no_grease结果是相同的，接下来稍微了解这个grease是啥

---

## GREASE机制

参考wireshark的这个issue [https://gitlab.com/wireshark/wireshark/-/issues/17942](https://gitlab.com/wireshark/wireshark/-/issues/17942) 正确计算ja3值需要排除grease

GREASE是Generate Random Extensions And Sustain Extensibility的缩写，由Google的David Benjamin发明,在RFC8701中被正式定义。

也就是客户端在握手时可以发送一组服务器要忽略的伪版本号，来防止TLS协议在将来进行扩展的时候受到阻碍。

参考这个文章的描述 [https://zhuanlan.zhihu.com/p/343562875](https://zhuanlan.zhihu.com/p/343562875)

```python
TLS在握手阶段首先需要客户端向服务器发送ClientHello记录，里面记录了自己支持的TLS版本、CipherSuites类型以及一些Extension等，如果服务器可以处理，会返回一个ServerHello记录，里面记录了选择的CipherSuite和一些Extension，为了保证协议的可扩展性，cipher和extension等字段的取值会有一些保留值，留待之后的版本使用，比如在TLSv1.2中就增加了AEAD类型的Cipher。

GREASE机制就是对这些参数分别限定了一些保留值，称为GREASE值，这些值在目前的TLS协议中是没有意义的，比如用于CipherSuites和Application-Layer Protocol Negotiation (ALPN)

协议规定在客户端发送ClientHello的时候可能会选择一个或多个GREASE放到对应字段发送给服务器。

而如果客户端在接收到服务器发送的记录（如ServerHello，Certificate，EncryptedExtensions等）中发现了GREASE值，客户端必须拒绝此记录并关闭连接

同时规定了服务器在发现ClientHello中的GREASE值的时候：

1. 不能使用这些GREASE值进行进一步协商，而必须把它们当作普通保留值
2. 必须忽略这些值，并使用此参数的其他值进行协商

这是一种很巧妙的设计，类似于囚徒困境，每个TLS软件库既有可能被用于客户端，也可能被用于服务端，而由于目前存在多款应用广泛的TLS软件库，无法保证客户端使用的TLS库一定与服务端使用的TLS库相同，为了保证自己的库能够与其他库正常交互，各个软件库在实现的时候就不得不遵循这一约定。

同样，对于一些由服务器端首先发出的参数，此文档用相似的方式规定了客户端和服务器的行为。
```

GREASE机制的具体实现可以参考 [https://www.rfc-editor.org/rfc/rfc8701](https://www.rfc-editor.org/rfc/rfc8701)

在 [https://engineering.salesforce.com/tls-fingerprinting-with-ja3-and-ja3s-247362855967/](https://engineering.salesforce.com/tls-fingerprinting-with-ja3-and-ja3s-247362855967/) 一文中的描述为

```python
We also needed to introduce some code to account for Google’s GREASE (Generate Random Extensions And Sustain Extensibility) as described here. Google uses this as a mechanism to prevent extensibility failures in the TLS ecosystem. JA3 ignores these values completely to ensure that programs utilizing GREASE can still be identified with a single JA3 hash.
```

大意就是在计算ja3时最好忽略grease值

---

## burpsuite

再回到burp上，作为web安全人员最常用的工具之一，如果我想修改burp自身的ja3指纹该如何操作呢？

打开 `Project options` -- `TLS` 

![Untitled](../../img/ja3/Untitled%2012.png)

这里我的burp版本默认选择的是 `Use all supported protocols and ciphers of your Java installation`

选择 `Use custom protocols and ciphers`,可以发现，允许我们自选协议和ciphers suites支持

![Untitled](../../img/ja3/Untitled%2013.png)

随便修改下 Cipher,比如勾选图中4个选项 ,再次抓包看看ja3值

![Untitled](../../img/ja3/Untitled%2014.png)

```bash
771,4866-4865-4867-49196-49195-52393-49200-52392-49199-159-52394-163-158-162-49188-49192-49187-49191-107-106-103-64-49198-49202-49197-49201-49190-49194-49189-49193-49162-49172-49161-49171-57-56-51-50-49157-49167-49156-49166-157-156-61-60-53-47-49160-49170-22-19-49155-49165-10-255-167-166-49177-109,0-5-10-11-16-17-23-35-13-43-45-50-51,29-23-24-25-30-256-257-258-259-260,0
b0aca4c8b85f2c1f6d067382f5e334e7
```

![Untitled](../../img/ja3/Untitled%2015.png)

![Untitled](../../img/ja3/Untitled%2016.png)

可以看到对应的多出了4个`Extension`,这样通过自定义 Cipher Suites 可以简单快速的修改 ja3 特征

[https://github.com/sleeyax/burp-awesome-tls](https://github.com/sleeyax/burp-awesome-tls)

这个扩展也可以修改burp的ja3指纹

---

## nuclei+httpx

httpx和nuclei作为projectdiscovery重点的2个项目，也是国内外红队必备的工具

这里分别抓下httpx和nuclei的ja3指纹试试

httpx 1.2.4

```bash
域名
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,0-5-10-11-13-65281-18-43-51,29-23-24-25,0
473cd7cb9faa642487833865d516e578

ip
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,5-10-11-13-65281-18-43-51,29-23-24-25,0
19e29534fd49dd27d09234e639c4057e
```

nuclei 2.7.7

```bash
域名
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,0-5-10-11-13-65281-18-43-51,29-23-24-25,0
473cd7cb9faa642487833865d516e578

ip
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,5-10-11-13-65281-18-43-51,29-23-24-25,0
19e29534fd49dd27d09234e639c4057e
```

竟然是一样的，那换个版本试试？

httpx 1.2.3

```bash
域名
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,0-5-10-11-13-65281-18-43-51,29-23-24-25,0
473cd7cb9faa642487833865d516e578

ip
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,5-10-11-13-65281-18-43-51,29-23-24-25,0
19e29534fd49dd27d09234e639c4057e
```

httpx 1.2.2

```bash
域名
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,0-5-10-11-13-65281-18-43-51,29-23-24-25,0
473cd7cb9faa642487833865d516e578

ip
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,5-10-11-13-65281-18-43-51,29-23-24-25,0
19e29534fd49dd27d09234e639c4057e
```

httpx 1.1.5

```bash
域名
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,0-5-10-11-13-65281-18-43-51,29-23-24-25,0
473cd7cb9faa642487833865d516e578

ip
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,5-10-11-13-65281-18-43-51,29-23-24-25,0
19e29534fd49dd27d09234e639c4057e
```

httpx从1.2.4到1.1.5有10个月时间，这其中ja3一直没有变过，蓝队要是单独做了拦截，还是很有效果的。

同样的，测试了在mac上的结果，nuclei和httpx ja3指纹不变

![Untitled](../../img/ja3/Untitled%2017.png)

subfinder作为子域名收集工具，主要是向各家api去请求，并没有直接对目标的访问，当然抓一下对api的访问，其实会发现其ja3指纹和httpx一样的。

![Untitled](../../img/ja3/Untitled%2018.png)

---

## xray

再来看看被动扫描器里面比较常见的xray,当然xray也有主动扫描功能，一并测测

xray 1.9.3 主动扫描 linux/mac一致

```bash
域名
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,0-5-10-11-13-65281-18-43-51,29-23-24-25,0
473cd7cb9faa642487833865d516e578

ip
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,5-10-11-13-65281-18-43-51,29-23-24-25,0
19e29534fd49dd27d09234e639c4057e
```

xray 1.9.3 被动扫描 linux/mac一致

```bash
域名
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,0-5-10-11-13-65281-18-43-51,29-23-24-25,0
473cd7cb9faa642487833865d516e578

ip
771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,5-10-11-13-65281-18-43-51,29-23-24-25,0
19e29534fd49dd27d09234e639c4057e
```

![Untitled](../../img/ja3/Untitled%2019.png)

![Untitled](../../img/ja3/Untitled%2020.png)

---

## crawlergo

crawlergo的ja3结果在排除`GREASE`值的情况下也是固定的

```bash
771,4865-4866-4867-49195-49199-49196-49200-52393-52392-49171-49172-156-157-47-53,0-23-65281-10-11-35-16-5-13-18-51-45-43-27-21,29-23-24,0
b32309a26951912be7dba376398abc3b
```

![Untitled](../../img/ja3/Untitled%2021.png)

---

# 什么是ja3s

JA3S 是用于 SSL/TLS 通信的服务器端的 JA3，用于识别服务器如何响应特定客户端。

ja3s 由 `Server Hello 版本`、`可接受的加密算法`和`扩展列表中的每一个 type 值`生成,也就是提取 Server Hello 数据包中的：`Server Hello 版本`、`可接受的加密算法`和`扩展列表中的每一个 type 值`
。然后用`,`来分隔各个字段、用使用`-`来分隔各个字段中的各个值，连接在一起后，计算 `MD5`.

例如我访问fofa

![Untitled](../../img/ja3/Untitled%2022.png)

这里对server hello生成ja3s

上面所讲,识别恶意客户端行为可以用ja3，而识别很多c2的tls通信，可以则是采用ja3+ja3s，不用考虑IP、域名或证书等信息。也就是通过一来一回的交互来辅助研判。

---

# 什么是JARM

JARM是通过主动扫描生成的目标特征。

与ja3、ja3s不同，jarm用途主要用于服务端tls指纹测绘，例如识别c2服务器，自建域前置节点，指定jdk版本的服务等。

工作原理是向目标服务器发送10个特殊构造的TLS Client Hello包，以在TLS服务器中提取独特的响应，并捕获TLS Server Hello响应的特定属性，然后以特定的方式对聚合的TLS服务器响应进行hash，生成JARM指纹。

JARM发送10个TLS客户端Hello数据包，目的就是提取TLS服务器中的唯一响应。

查看具体代码实现 [https://github.com/salesforce/jarm#L467](https://github.com/salesforce/jarm#L467)

```python
def main():
    #Select the packets and formats to send
    #Array format = [destination_host,destination_port,version,cipher_list,cipher_order,GREASE,RARE_APLN,1.3_SUPPORT,extension_orders]
    tls1_2_forward = [destination_host, destination_port, "TLS_1.2", "ALL", "FORWARD", "NO_GREASE", "APLN", "1.2_SUPPORT", "REVERSE"]
    tls1_2_reverse = [destination_host, destination_port, "TLS_1.2", "ALL", "REVERSE", "NO_GREASE", "APLN", "1.2_SUPPORT", "FORWARD"]
    tls1_2_top_half = [destination_host, destination_port, "TLS_1.2", "ALL", "TOP_HALF", "NO_GREASE", "APLN", "NO_SUPPORT", "FORWARD"]
    tls1_2_bottom_half = [destination_host, destination_port, "TLS_1.2", "ALL", "BOTTOM_HALF", "NO_GREASE", "RARE_APLN", "NO_SUPPORT", "FORWARD"]
    tls1_2_middle_out = [destination_host, destination_port, "TLS_1.2", "ALL", "MIDDLE_OUT", "GREASE", "RARE_APLN", "NO_SUPPORT", "REVERSE"]
    tls1_1_middle_out = [destination_host, destination_port, "TLS_1.1", "ALL", "FORWARD", "NO_GREASE", "APLN", "NO_SUPPORT", "FORWARD"]
    tls1_3_forward = [destination_host, destination_port, "TLS_1.3", "ALL", "FORWARD", "NO_GREASE", "APLN", "1.3_SUPPORT", "REVERSE"]
    tls1_3_reverse = [destination_host, destination_port, "TLS_1.3", "ALL", "REVERSE", "NO_GREASE", "APLN", "1.3_SUPPORT", "FORWARD"]
    tls1_3_invalid = [destination_host, destination_port, "TLS_1.3", "NO1.3", "FORWARD", "NO_GREASE", "APLN", "1.3_SUPPORT", "FORWARD"]
    tls1_3_middle_out = [destination_host, destination_port, "TLS_1.3", "ALL", "MIDDLE_OUT", "GREASE", "APLN", "1.3_SUPPORT", "REVERSE"]
    #Possible versions: SSLv3, TLS_1, TLS_1.1, TLS_1.2, TLS_1.3
    #Possible cipher lists: ALL, NO1.3
    #GREASE: either NO_GREASE or GREASE
    #APLN: either APLN or RARE_APLN
    #Supported Verisons extension: 1.2_SUPPPORT, NO_SUPPORT, or 1.3_SUPPORT
    #Possible Extension order: FORWARD, REVERSE
    queue = [tls1_2_forward, tls1_2_reverse, tls1_2_top_half, tls1_2_bottom_half, tls1_2_middle_out, tls1_1_middle_out, tls1_3_forward, tls1_3_reverse, tls1_3_invalid, tls1_3_middle_out]
    jarm = ""
```

在main函数，jarm定义了10种TLS Client Hello数据包生成的结构，分别包含了待扫描的目标、端口、tls客户端加密套件、TLS扩展列表

```python
iterate = 0
    while iterate < len(queue):
        payload = packet_building(queue[iterate])
        server_hello, ip = send_packet(payload)
        #Deal with timeout error
        if server_hello == "TIMEOUT":
            jarm = "|||,|||,|||,|||,|||,|||,|||,|||,|||,|||"
            break
        ans = read_packet(server_hello, queue[iterate])
        jarm += ans
        iterate += 1
        if iterate == len(queue):
            break
        else:
            jarm += ","
```

依次遍历这10种TLS Client Hello结构生成数据包，并使用packet_building函数生成对应的TLS Client Hello数据包，通过send_packet发送数据包，使用read_packet解析返回TLS Server Hello，并拼接为如下格式：

![Untitled](../../img/ja3/Untitled%2023.png)

```python
服务器返回的加密套件 | 服务器返回选择使用的TLS协议版本 |  TLS扩展ALPN协议信息 | TLS扩展列表
```

通过发送10次TLS Client Hello并解析为以上格式，将10次解析的结果拼接以后最终调用jarm_hash算出最终的结果。

实际测试比如对CobaltStrike的识别，jarm主要和jdk版本相关，和CobaltStrike没有强关联性,JARM比较适合用于识别不同JDK环境下的TLS服务。

---

# 总结

整体来看，通过ja3指纹库识别一些常见自动化工具的扫描非常有效，但对于一些java gui的程序由于不同jdk版本、不同平台都会有影响，所以维护成本会很大。

当然ja3本质上是一种规则，一种思路，可以根据ja3的规则去生成md5，也可以根据你自己的判断挑选一些Version + Cipher Suites + Extension生成类似ja3的指纹去辅助研判，并且忽略排序顺序。但是切记要排除`GREASE`值。

**彩蛋**

为啥取名叫ja3？

因为是由Salesforce的工程师 John Althouse、Jeff Atkinson、Josh Atkins 三位创建的。

为啥用md5?

除了因为md5计算较快,具有不错的单一性，还因为md5不会太长，足以放到推文里

![Untitled](../../img/ja3/Untitled%2024.png)

---

# Source & Reference

- [https://xz.aliyun.com/t/3889](https://xz.aliyun.com/t/3889)
- [https://github.com/salesforce/ja3](https://github.com/salesforce/ja3)
- [https://rmb122.com/2022/08/14/burpsuite-特征识别及其对抗措施/](https://rmb122.com/2022/08/14/burpsuite-%E7%89%B9%E5%BE%81%E8%AF%86%E5%88%AB%E5%8F%8A%E5%85%B6%E5%AF%B9%E6%8A%97%E6%8E%AA%E6%96%BD/)
- [https://www.tr0y.wang/2020/06/28/ja3/](https://www.tr0y.wang/2020/06/28/ja3/)
- [https://mp.weixin.qq.com/s/Cha_hTGOh-GGVkaZRdFujw](https://mp.weixin.qq.com/s/Cha_hTGOh-GGVkaZRdFujw)
- [https://engineering.salesforce.com/easily-identify-malicious-servers-on-the-internet-with-jarm-e095edac525a/](https://engineering.salesforce.com/easily-identify-malicious-servers-on-the-internet-with-jarm-e095edac525a/)
- [https://engineering.salesforce.com/tls-fingerprinting-with-ja3-and-ja3s-247362855967/](https://engineering.salesforce.com/tls-fingerprinting-with-ja3-and-ja3s-247362855967/)
- [https://www.cobaltstrike.com/blog/a-red-teamer-plays-with-jarm/](https://www.cobaltstrike.com/blog/a-red-teamer-plays-with-jarm/)
- [https://www.anquanke.com/post/id/225627](https://www.anquanke.com/post/id/225627)
- [https://www.anquanke.com/post/id/276546](https://www.anquanke.com/post/id/276546)
- [https://infosecwriteups.com/demystifying-ja3-one-handshake-at-a-time-c80b04ccb393](https://infosecwriteups.com/demystifying-ja3-one-handshake-at-a-time-c80b04ccb393)
- https://gitlab.com/wireshark/wireshark/-/issues/17942
- [https://zhuanlan.zhihu.com/p/343562875](https://zhuanlan.zhihu.com/p/343562875)
- [https://daniel.haxx.se/blog/2022/09/02/curls-tls-fingerprint/](https://daniel.haxx.se/blog/2022/09/02/curls-tls-fingerprint/)
- [https://bjun.tech/blog/xphp/140](https://bjun.tech/blog/xphp/140)
- [https://blog.cloudflare.com/monsters-in-the-middleboxes/](https://blog.cloudflare.com/monsters-in-the-middleboxes/)
