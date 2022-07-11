---
title: 使用 Vercel 全自动部署个人网站
tags:
  - Vercel
  - CICD
  - 前端工程化
  - 自动部署
categories:
  - 前端
  - 前端工程化
date: 2022-07-11 19:17:39
---

# 1. 什么是 Vercel

Vercel 是一个全自动的 Web 应用部署、预览、上线平台。他类似与 Github Page 与 Github Action 的结合，但是与其有如下几个特性：

- 支持应用模板，可以帮助开发人员快速搭建一个应用并完成上线流程；
- 支持 Github 项目导入与联动；
- Gtihub Action 是 CICD 流水线，而 Vercel 只专注于项目部署，其他的事情，比如 npm 自动发包、持续集成测试，不是 Vercel 的业务范围；
- 支持零配置部署到全球的边缘网络，访问速度比 Github Page 快得多，无需关心 CDN、HTTPS，Vercel 会帮你做好这一切；
- Vercel 可以部署多种环境，出了项目主要的生产环境之外，它可以将你的其他分支视为预览分支进行部署（当然这些预览环境会加上对应的响应头防止被搜索引擎收录）

# 2. 使用

这里我们用 [EsunR/Blog-Index](https://github.com/EsunR/Blog-Index) 项目做示例，使用 Vercel 对其进行部署。

## 2.1 创建 Github 仓库

首先，点击项目的 Fork 按钮，将项目同步到自己的 Github 仓库中：

![](https://s2.loli.net/2022/07/11/etzGPTsFjDpxwmK.png)

然后将该仓库 clone 到本地，按项目说明，进行装包、修改配置文件、调试等一系列工作后，将变更提交，并推送到该仓库。

## 2.2 Vercel 平台接入

登入 [Vercel 官网](https://vercel.com/login) 完成账号注册，进入到工作台后，授权你的 Github 仓库权限给 Vercel：

![](https://s2.loli.net/2022/07/11/VUmDLCS91YqFe3d.png)

授权完成后导入项目：

![](https://s2.loli.net/2022/07/11/A2NcE8XJiUbYfT3.png)

对项目进行配置，并手动调整构建语句配置：

![](https://s2.loli.net/2022/07/11/pJUD3hMkXmSBYFv.png)

完成后点击 `Deploy` 即可开始部署，完成后便可前往项目控制台查看 Vercel 为你分配的域名了：

![](https://s2.loli.net/2022/07/11/BW91HG3pF7lUCcL.png)

当然，在项目设置中可以帮你你自己的域名：

![](https://s2.loli.net/2022/07/11/HV2dbZUJtchgOK9.png)

后续你只需要修改你仓库中 Fork 下的代码即可，推送到 github 上时便会自动触发 Vercel 的重新部署流程。

如果你想切换默认部署的分支，可以将 Production Branch 设置为别的分支即可：

![](https://s2.loli.net/2022/07/11/DszltROMCBhI6bH.png)