---
categories:
  - 其他
---
是不是每次都找不到遥控器而烦恼？是不是想要语音控制投影仪的关闭和开启？

如果你是苹果用户，那么本文将教你实现如何让极米投影仪（其他电视设备同理）接入到苹果 HomeKit 生态，实现搭配 HomePod 使用 Siri 唤醒或关闭投影仪，并且可以直接使用 IOS 集成在系统控制中心的电视遥控器来直接控制投影仪，超级方便！

# 1. 实现思路

极米投影仪类似的设备支持使用 APP 在局域网环境下进行设备操控，这实际上就是通过 APP 在向局域网中的极米投影仪的设备 IP 发送一个 **UDP 数据包**，当设备收到请求后就能执行相对应的操作了，如调节音量、方向控制等。

我们可以通过抓包去获取 APP 向局域网设备发送的  UDP 数据包，获取到具体的 API 规范。好在论坛已经有大佬整理出来了([原文](https://bbs.hassbian.com/thread-4998-1-1.html))，具体如下：

一套是复杂指令，一套是简单的按键输入，所有指令均是通过upd连接到目标机器上，复杂api的端口是16750，简单按键api的端口是16735。

复杂指令内容如以下格式：

```
{"action":20000,"controlCmd":{"delayTime":0,"mode":6,"time":0,"type":0},"msgid":"2"}
```

简单指令就只有一段文本（并不是 JSON 结构体），如 `KEYPRESSES:116` 代表电源按键，其他的按键及其对应的指令如下：

```
"power" => 'KEYPRESSES:116',
"vol+" => "KEYPRESSES:115",
"vol-" => "KEYPRESSES:114",
"menu" => "KEYPRESSES:139",
"back" => "KEYPRESSES:48",
"pause" => "KEYPRESSES:49",
"paly" => "KEYPRESSES:49",
"down" => "KEYPRESSES:38",
"up" => "KEYPRESSES:36",
"left" => "KEYPRESSES:50",
"right" => "KEYPRESSES:37",
"home" => "KEYPRESSES:35",
```

有了 API 后就要思考如何调用这些 API，NodeRed 就是一个很好用的工具。

NodeRed 是一个基于浏览器的可视化工具，如果你使用过苹果的 **快捷指令** APP，那么就很容易理解 NodeRed 的操作。它可以通过拖拽节点方式构建应用程序，并通过连接它们来定义其行为，帮助用户轻松创建流程，并使设备、API和在线服务互相协作，在 IoT 领域被很多人使用。

举例来说，我们只需要简答的拖拽一个 `inject` 节点作为触发节点，再拖拽一个 `udp` 节点并双击节点进行配置，就可以将 inject 节点中填写的 payload 信息作为 udp 报文内容发送给局域网中的某一设备：

![image.png](https://s2.loli.net/2023/07/20/raRAj6NfPQnl8C3.png)

平台也有了，那么就要思考如何让 HomeAssistant 调用 NodeRed 的服务，最简单的方式就是使用 MQTT 协议来调用我们写的 NodeRed 服务。MQTT 是一个物联网领域的常用通信协议（可以不用深入了解），HomeAssistant 支持 MQTT 消息的发布([通过 MQTT 插件](https://www.home-assistant.io/integrations/mqtt/))，而 NodeRed 支持 MQTT 消息的接收（当然也支持发布），这样 HomeAssistant 和 NodeRed 之间就可以互动了，比如让 HomeAssistant 发送 MQTT 指令触发 NodeRed 的 udp 节点发送一个 udp 请求，进而让极米投影仪执行指令对应的行为。到这一步，其实已经可以通过编写一个 HomeAssistant MQTT 控件以及对应的 NodeRed 的服务来实现 HomeAssistant 控制极米投影仪了。

但是我们最终的目的是将极米投影仪接入 HomeKit 生态，NodeRed 其中一个强大之处就是支持安装第三方插件，从而获得更多类型的控制节点，社区中有 HomeKit 服务相关的节点，可以帮助我们创建一个虚拟的 HomeKit 配件，我们使用家庭 APP 连接到这个虚拟配件后，当我们对这个虚拟配件进行操作时，NodeRed 中该 HomeKit 服务节点就会获得一个输入信号，那么我们只要将这个输入信号进行编码，让其发送对应的 udp 数据包到投影仪上，那么就可以实现 HomeKit 控制投影仪的功能。

最后还有一个开关机的难题，因为关机后设备处于离线状态，那么就无法跟设备通信了，就没法开机了。对于极米投影仪的解决方案是可以使用一个小米智能插座来解决，因为极米投影仪的高级设置中支持通电自动开机，那么只需要在收到关机指令后等待投影仪关机完成，插座自动断电，当收到开机指令时，插座再通电即可实现设备的唤醒。

# 2. 具体实现

 整套服务的整体架构图如下：

![](https://s2.loli.net/2023/07/20/pELi52doCvuzHFg.png)

这套架构的核心是在 NodeRed 平台上实现的 MQTT 服务，MQTT 服务不用考虑上游的实现，只专注实于现接收到 MQTT 消息时如何处理消息，如果是上下左右、调节音量等指令，那么就创建一个 UDP 报文，发送给设备端。但如果是开关机指令，则需要通过 MQTT 服务与 HomeAssistant 服务进行通信，请求关闭或开启小米智能插座。

 而 MQTT 服务的上游可以是多种的，比如 HomeAssistant 发来的 MQTT 消息（这个我们不做实现），还有就是我们后面需要使用 NodeRed 搭建的 HomeKit 服务发来的 MQTT 消息。如果你还想用其他方式来创建投影仪的控制器，你都可以自行实现，但只要控制器的输出是一个约定好的 MQTT 消息，那么就能通过核心的 MQTT 服务来对投影仪进行操作。

## 2.1 MQTT 服务搭建

首先要在系统中安装 MQTT 服务，否则一切都白搭，可以按照 [这个教程](https://www.jianshu.com/p/a13e888c93fb) 来安装 MQTT 服务。

安装完成后，在 NodeRed 平台导入如下配置：

[MQTT 服务](https://gist.githubusercontent.com/EsunR/ec2ea06ef4768b3ddaf2d74fe9ff22f3/raw/mqtt-service.json)

> 导入方式：NodeRed 右上角菜单 - 导入 - 粘贴链接中的配置

导入成功后会出现如下的流程图：

![](https://s2.loli.net/2023/07/20/hsczo91td82QpIW.png)

导入完成以后需要修改一下『极米控制指令广播』这个节点，将发送 UDP 报文的目标地址需要修改为你投影仪的局域网 IP：

> 这里请务必将投影仪的 IP 在路由器中设置为一个固定的静态 IP，否则每次开机都可能改变

![](https://s2.loli.net/2023/07/20/49fPby7OMtNgG3Z.png)

然后点击『部署』按钮部署节点。

为了让该服务可以控制投影仪插座，你需要将小米智能插座接入到 HomeAssistant 后，创建两个 HomeAssistant 的自动化，分别控制插座的开关，自动化的触发条件要设置为接收到 MQTT 消息。

收到投影仪关机 MQTT：

![](https://s2.loli.net/2023/07/20/uiIWJS3G5m91DsK.png)

收到投影仪开机 MQTT：

![](https://s2.loli.net/2023/07/20/eE4uYMir3tAlRGF.png)

## 2.2 HomeKit 服务搭建

首先点击右上角菜单，选择『节点管理』，点击安装面板，分别安装 `node-red-contrib-homekit-bridged` 和 `node-red-node-ping` 这两个节点插件（需要设备科学上网环境，否则可能会安装失败），然后导入如下配置：

[HomeKit 服务](https://gist.githubusercontent.com/EsunR/ec2ea06ef4768b3ddaf2d74fe9ff22f3/raw/homekit-service.json)

![](https://s2.loli.net/2023/07/20/nIgavwc246BdlCQ.png)

这个配置无需修改，成功部署后直接在家庭 APP 中搜索设备即可查找到创建的投影仪设备，配对码即为 HomeKit 节点下显示的数字，如果想要修改虚拟 HomeKit 设备信息，则选中 HomeKit 服务节点，选择新增 homekit-standalone 节点后填写入信息即可。

![](https://s2.loli.net/2023/07/20/ls6cigDb2ZH1MOu.png)

> 如果查找不到，可能是科学上网的问题，暂时关闭试试。