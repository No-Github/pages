---
title: "宝塔 7.9.47 绕过手机号绑定"
date: 2022-10-03T12:00:00+08:00
draft: false
author: "r0fus0d"
categories: ["技术"]

---

最近看到Tide安全团队的文章，介绍了宝塔的新旧版绑定相关功能点，尝试对新版的手机号绑定进行绕过
- https://mp.weixin.qq.com/s/Ty7iOxfep2M2PXWqtwzm1w

<!--more-->

---

## 绕过手机号绑定

### 麻烦且粗暴的方法

经过一番摸索，可以不用绑定，但后台几处功能点无法正常使用,比较蛋疼

用户协议 确认

```python
/www/server/panel/data/licenes.pl

True
```

建一个假的userInfo.json

```json
/www/server/panel/data/userInfo.json

{
    "uid": 111111,
    "address": "127.0.0.1",
    "access_key": "",
    "secret_key": "",
    "addtime": 1664633884,
    "username": "11111111111",
    "idc_code": "",
    "state": 1,
    "serverid": "1111111111111111111111111111111111111111111111111111111111111111",
    "ukey": ""
  }
```

```python
/www/server/panel/data/sid.pl

111
```

修改 softList 的值

```python
/www/server/panel/class/panelPlugin.py

990-994行
把以下5行
if not 'list' in softList:
            if 'msg' in softList:
                raise public.PanelError(softList['msg'])
            else:
                raise public.PanelError('获取插件列表失败!')

改为
softList={"list":[]}
```

删除get_pd

```python
/www/server/panel/BTPanel/__init__.py

855行
defs = ('get_lines', 'php_info', 'change_phpmyadmin_ssl_port', 'set_phpmyadmin_ssl', 'get_phpmyadmin_ssl','get_pd','get_pay_type',
            'check_user_auth', 'to_not_beta', 'get_beta_logs', 'apple_beta', 'GetApacheStatus', 'GetCloudHtml',
            'get_load_average', 'GetOpeLogs', 'GetFpmLogs', 'GetFpmSlowLogs', 'SetMemcachedCache', 'GetMemcachedStatus',
            'GetRedisStatus', 'GetWarning', 'SetWarning', 'CheckLogin', 'GetSpeed', 'GetAd', 'phpSort', 'ToPunycode',
            'GetBetaStatus', 'SetBeta', 'setPHPMyAdmin', 'delClose', 'KillProcess', 'GetPHPInfo', 'GetQiniuFileList','get_process_tops','get_process_cpu_high',
            'UninstallLib', 'InstallLib', 'SetQiniuAS', 'GetQiniuAS', 'GetLibList', 'GetProcessList', 'GetNetWorkList',
            'GetNginxStatus', 'GetPHPStatus', 'GetTaskCount', 'GetSoftList', 'GetNetWorkIo', 'GetDiskIo', 'GetCpuIo','ignore_version',
            'CheckInstalled', 'UpdatePanel', 'GetInstalled', 'GetPHPConfig', 'SetPHPConfig','log_analysis','speed_log','get_result','get_detailed')

改为
defs = ('get_lines', 'php_info', 'change_phpmyadmin_ssl_port', 'set_phpmyadmin_ssl', 'get_phpmyadmin_ssl','get_pay_type',
            'check_user_auth', 'to_not_beta', 'get_beta_logs', 'apple_beta', 'GetApacheStatus', 'GetCloudHtml',
            'get_load_average', 'GetOpeLogs', 'GetFpmLogs', 'GetFpmSlowLogs', 'SetMemcachedCache', 'GetMemcachedStatus',
            'GetRedisStatus', 'GetWarning', 'SetWarning', 'CheckLogin', 'GetSpeed', 'GetAd', 'phpSort', 'ToPunycode',
            'GetBetaStatus', 'SetBeta', 'setPHPMyAdmin', 'delClose', 'KillProcess', 'GetPHPInfo', 'GetQiniuFileList','get_process_tops','get_process_cpu_high',
            'UninstallLib', 'InstallLib', 'SetQiniuAS', 'GetQiniuAS', 'GetLibList', 'GetProcessList', 'GetNetWorkList',
            'GetNginxStatus', 'GetPHPStatus', 'GetTaskCount', 'GetSoftList', 'GetNetWorkIo', 'GetDiskIo', 'GetCpuIo','ignore_version',
            'CheckInstalled', 'UpdatePanel', 'GetInstalled', 'GetPHPConfig', 'SetPHPConfig','log_analysis','speed_log','get_result','get_detailed')

```

修改`check_user_auth`函数的返回

```python
/www/server/panel/class/ajax.py

把1300行左右的
				try:
            userInfo = json.loads(public.ReadFile(u_path))
        except:
            if os.path.exists(u_path): os.remove(u_path)
            return public.returnMsg(False,'宝塔帐户绑定已失效，请在[设置]页面重新绑定!')

改为
				try:
            userInfo = json.loads(public.ReadFile(u_path))
        except:
            userInfo = json.loads(public.ReadFile(u_path))

把1300行左右的
if result == '0':
            if os.path.exists(u_path): os.remove(u_path)
            return public.returnMsg(False,'宝塔帐户绑定已失效，请在[设置]页面重新绑定!')

改为
if result == '0':
            session[m_key] = public.returnMsg(True,'绑定有效!')
            return session[m_key]

```

修改 `is_verify_unbinding` 函数的判断

```python
/www/server/panel/class/panelPlugin.py

把 3050行左右的
							if not list_body['status']:
                if os.path.exists(path):os.remove(path)
                return False
这3行删掉
```

命令 bt 然后 1 重启服务即可，后台docker(专业版)和防火墙(专业版)和软件商店无法正常使用,其余正常
