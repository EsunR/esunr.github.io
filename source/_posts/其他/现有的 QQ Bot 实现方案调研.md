---
title: 现有的 QQ Bot 实现方案调研
tags:
  - QQ
  - Bot
  - 聊天机器人
categories:
  - 其他
date: 2024-12-21 16:41:51
---
> QQ 目前已有官方机器人可以供普通用户申请使用，但是在 QQ 群中只能主动接收到 At 消息，可以参考官方的接入方案：[文档](https://bot.q.qq.com/wiki/)

# 1. 被历史遗弃的 QQ 机器人项目

## CQHTTP

[项目地址](https://github.com/kyubotics/coolq-http-api)

CQHTTP 插件是 2017 年初出现的基于 CKYU 机器人平台的一款开源免费插件，它使用户能够通过 HTTP 或 WebSocket 对 CKYU 的事件进行上报以及接收请求来调用 CKYU 的 DLL 接口，从而可以使用其它语言（不方便编译到原生二进制的语言）编写 CKYU 插件。

因此 CQHTTP 即是一款插件，又被当做了一种 HTTP 请求调用 QQ 机器人的标准。

## mirai

[项目地址 14.5k](https://github.com/mamoe/mirai)

基于 Java 编写的 QQ 机器人平台，通过在 Linux 环境下模拟 QQ 登录实现，通过 http 插件可以实现发布订阅消息。同时 Mirai 也有一个庞大的社区，有着丰富的插件生态，因此即使用户不会编程，也可以轻松使用。

目前该实现方案受到严重的风控影响，使用第三方签名登录也不能很好的绕过风控，因此属于过时的方案。

## go-cqhttp

[项目地址 10.4k](https://github.com/Mrs4s/go-cqhttp)

基于 Mirai 以及 MiraiGo 的 OneBot Golang 原生实现，其与 mirai 不同的是并没有被设计为一个支持各种插件的平台，而只是提供了 OneBot 相关协议的具体实现，用户可以使用自己喜欢的编程语言来通过 Http 或者 websocket 来调用该平台。

## oicq

[项目地址 2.7k](https://github.com/takayama-lily/oicq)

# 2.  标准协议的创建

由于各种 QQ 机器人的平台总是面临着被风控、作者放弃维护的风险，导致如果针对平台来开发机器人插件（比如使用 Java 开发 Mirai 的插件），如果平台没了就得重新开发。因此为了避免这种情况的出现，OneBot 协议诞生了。

OneBot 协议规范了所有聊天机器人框架应该对外部提供的 API，并且协议并不只是针对 QQ 定制的，Telegram、钉钉等其他平台机器人的实现都可以遵循改标准，这样使用各种语言开发的机器人插件就不会由于机器人框架本身的迭代或者失效而作废。

协议地址：

- [OneBot 11](https://github.com/botuniverse/onebot-11)
- [OneBot 12（待定）](https://12.onebot.dev/)

此外，还有一个 Satori 协议：[Satori 介绍](https://satori.js.org/zh-CN/introduction.html)

# 3. NTQQ 生态

> 由于QQ官方针对协议库的围追堵截，Mirai 类的方案已经无力继续维护。同时`NTQQ`的出现让我们可以使用官方 **完美** 实现的协议实现来继续开发Bot, 不再担心由于协议实现不完美而导致被识别。我们建议所有QQBot项目开始做好迁移至无头`NTQQ`或类似基于官方客户端技术的准备以应对未来的彻底封锁。
> 
> 摘录自：[QQ Bot的未来以及迁移建议 #2471](https://github.com/Mrs4s/go-cqhttp/issues/2471)

## LiteLoaderQQNT

[项目地址 6.2k](https://liteloaderqqnt.github.io/)

LiteLoaderQQNT 与机器人没有多大关系，其是一款基于 NT 版 QQ 的插件加载器，它需要安装在 NTQQ 的客户端上，可以轻松实现防撤回、美化、定时消息等功能。

当然，你可以基于 LiteLoaderQQNT 提供的接口来实现 QQ 机器人。

## LLOneBot

[项目地址 2.2k](https://github.com/LLOneBot/LLOneBot)

LLOneBot 就是基于 LiteLoaderQQNT 实现兼容 OneBot11、Satori 协议的机器人插件。用户可以将其安装在 QQ 客户端中，其内部会开启一个服务器，来对外提供对 OneBot 协议的 API，由于其完全基于官方客户端运行，因此理论上没有被风控的风险。

## NapCatQQ

[项目地址 2.8k](https://github.com/NapNeko/NapCatQQ?tab=readme-ov-file)

NapCatQQ 是一个实现了多种 Bot 协议的无头版本的 QQNT，不依赖框架加载，内存占用低，非常适合在服务端运行。

## Lagrange

[项目地址](https://github.com/LagrangeDev/Lagrange.Core)

Lagrange 是一组项目，分别为：

Lagrange.Core 是一个开源的基于 C# 的 NTQQ 协议实现，你可以利用该项目来开发一个完全属于自己的 QQ 客户端。

Lagrange.OneBot 是一个基于 Core 并实现了 OneBot 协议 API 的服务程序。

LagrengeGo：Lagrenge 的 Go 语言实现。

lagrenge-python：Lagrenge 的 Python 语言实现。

# 4. 其他

## OpenShamrock

## Koishi.js


