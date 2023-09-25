---
title: "nuclei 模板编写踩坑"
date: 2023-09-25T12:00:00+08:00
draft: false
author: "r0fus0d"
categories: ["技术"]

---

一点吐槽

<!--more-->

---

## yaml格式

多一个空格都不行，真的很严格

![Untitled](../../img/nuclei/Untitled.png)

## 请求合并

请求合并是非常优秀的功能，但是在部分场景下会无法合并,例如

```jsx
http:
  - method: GET
    path:
      - "{{BaseURL}}"
```

```jsx
http:
  - method: GET
    path:
      - "{{BaseURL}}"

    host-redirects: true
    max-redirects: 2
```

![Untitled](../../img/nuclei/Untitled%201.png)

又例如

```
http:
  - method: GET
    path:
      - "{{BaseURL}}"

    host-redirects: true
    max-redirects: 2
```

```
http:
  - method: GET
    path:
      - "{{BaseURL}}"
      - "{{BaseURL}}/aaa"

    host-redirects: true
    max-redirects: 2
```

![Untitled](../../img/nuclei/Untitled%202.png)

## workflow的请求合并

在workflow的扫描流程中

即使finger的扫描请求完全一致，请求也是拆分出来的，无法自动合并，估计是实现逻辑上的问题。

```
id: test1-workflow

info:
  name: test1 workflow
  author: aaaa

workflows:
  - template: /tmp/test1-detect.yaml
    subtemplates:
      - template: /tmp/test1/
```

```
id: test2-workflow

info:
  name: test2 workflow
  author: aaaa

workflows:
  - template: /tmp/test2-detect.yaml
    subtemplates:
      - template: /tmp/test2/
```

```
id: test1-detect

info:
  name: test1-detect
  author: aaa
  severity: info
  tags: tech

http:
  - method: GET
    path:
      - "{{BaseURL}}"

    host-redirects: true
    max-redirects: 2
```

```
id: test2-detect

info:
  name: test2-detect
  author: aaa
  severity: info
  tags: tech

http:
  - method: GET
    path:
      - "{{BaseURL}}"

    host-redirects: true
    max-redirects: 2
```

![Untitled](../../img/nuclei/Untitled%203.png)

## 变量解析

之前遇到的问题了

提的issue

```
requests:
  - method: GET
    path:
      - "{{BaseURL}}/{{123123}}"
      - "{{BaseURL}}/{{aaabbb}}"
      - "{{BaseURL}}/{{123*123}}"
      - "{{BaseURL}}/{{123!123}}"
```

主要在于解析的情况不一致

[https://github.com/projectdiscovery/nuclei/issues/1497](https://github.com/projectdiscovery/nuclei/issues/1497)

后面在版本更新中得以解决

## 低质量 wordpress cve poc

怎么这么多人喜欢刷这种低质量的cve编号

关键是怎么还就有人喜欢写这种低质量漏洞的poc,闲的蛋疼吗。。。

![Untitled](../../img/nuclei/Untitled%204.png)

![Untitled](../../img/nuclei/Untitled%205.png)

![Untitled](../../img/nuclei/Untitled%206.png)

![Untitled](../../img/nuclei/Untitled%207.png)

---

## 总结

nuclei无疑是近年来安全行业最火热的工具之一，这也和其开发团队的努力脱不开联系，就以外网打点，漏洞扫描来看，不说自己二开、集成，就能把模板自己写写，优化好误报漏报，其实就能发挥很大的威力了。

最后推荐下官方的和我的burp插件，用来辅助编写模板

**nuclei-burp-plugin**

[https://github.com/projectdiscovery/nuclei-burp-plugin](https://github.com/projectdiscovery/nuclei-burp-plugin)

**nu_te_gen**

[https://github.com/ffffffff0x/burp_nu_te_gen](https://github.com/ffffffff0x/burp_nu_te_gen)