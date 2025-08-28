---
title: 使用 Android Studio 模拟器对应用进行抓包
tags:
  - Android
  - 抓包
categories:
  - 其他
date: 2025-08-28 12:45:00
---

# 背景

在 iOS 上，由于本身对第三方应用上架的强监管，以及企业 DMD 审查流量的需求，用户安装第三方证书用于抓包是很常规的操作，但是在安卓端不然。

在 Android 7.0 以后，Google 对用户安装的第三方证书默认采取了不信任的策略，导致 Charles 这类基于安装第三方证书实现 HTTPS 流量拦截和解密的抓包工具集体失效了。具体的表现为安装完证书后系统会一直提示你在使用一个未经信认的第三方证书，并且抓包工具也只能看到 TCP 连接，并不能解析包的内容。

如果是自己开发的应用还好，可以通过 `network_security_config.xml` 的配置来指定信任某个证书，但是对于第三方应用就没有常规手段可以用了。

当然，非常规手段还是有的，就是 Root + 万能的 Magisk 框架。Root 就是获取 Android 操作系统的最高权限，在早年的刷机时代中获取 Root 权限已经是常规操作了。而 Magisk 简单来说就是一个 Root 权限的管理工具、以及插件运行框架。Magisk 插件可以在第三方应用的运行时以 Hook 等方式注入执行脚本，还可以以挂载的方式修改 System 分区，从而修改一些系统层面的内容。因此不难想到，Magisk 可以帮助我们绕过安卓默认的证书信任策略，来信任用户所有的证书。

但是，刷机时代已经是过去式了，现有的手机基本上很难获取 Root 权限，更别说安装 Magisk 了。话又说回来，是各大厂商限制了用户获取 Root 的权利，并不代表 Android 本身无法获取，我们可以搞一台装了未经魔改的 Android 的手机，比如 Pixel（一加也成），可能唯一的问题就是没钱吧，没关系，Android Studio 里面一大堆免费的 Pixel 任君挑选。

所以 Android Studio 模拟器 + Magisk，有没有搞头？有的兄弟，有的

# 安装 Android Studio 模拟器

安装完 Android Studio 之后，进入 More action - Virtual Device Manager，点击左上角加号创建一个模拟器：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151506253.png)

 创建时建议选择 Android13（相对比较新，并且大部分的 Magisk 插件都支持），对应的 API 版本为 33，并且一定要选择带 Google Play 的模拟器，这样可以避免一些 Google 服务框架不全的问题，不知道怎么选就建议选 Pixel4：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151508694.png)

完事之后就可以安装 SDK、启动模拟器。

# 使用 rootAVD 获取 Root 权限

针对 Android Studio 模拟器获取 Root 权限的方案，社区有 [rootAVD](https://gitlab.com/newbit/rootAVD) 项目可以一键调用，帮你把 Root 权限搞定，并且安装好 Magisk。

首先要安装 adb（安卓命令行工具）路径为：

Android Studio -> SDK Manager -> Android SDK -> SDK Tools -> Check on **Android SDK Platform-Tools** -> Apply

安装后如果终端可以使用 `adb shell` 指令即说明安装成功。

然后将 rootAVD 项目 Clone 到本地：

```sh
git clone https://gitlab.com/newbit/rootAVD.git
```

进入项目目录，执行脚本：

```sh
./rootAVD.sh ListAllAVDs
```

会列出来所有已的安卓模拟器，根据你的情况，比如前面选的 Android 13（API 33），那么就在列表中找到对应的模拟器路径，并复制对应的指令：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151517303.png)

粘贴指令到终端后会执行脚本，直至看到类似下图的输出说明脚本执行成功：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151526003.png)

此时安卓模拟器会自动重启并推出，如果弹出对话框，随便选 YES 或 NO，模拟器也会退出。但是此时不要在模拟器管理列表中直接点启动，否则模拟器会一直黑屏卡死，而是在更多选项中选择 Cloud Boot：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151529501.png)

重新进入模拟器页面后就能在应用抽屉中找到 Magisk 了：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151531052.png)

进入 Magisk 后会提示手机重启，点击 OK。然后再进入设置页面，开启 Zygisk，这是一个向 APP 隐藏 Root 信息的功能，不开启的话部分应用会检测到 Root 并禁止启动。

之后当我们安装一些需要 Root 的应用，比如 Root Explore，当应用需要 Root 授权时就会弹出弹窗，选择授权后就可以在 Magisk 的超级用户 Tab 下看到授权信息，这里由于我们不会用到 Root 授权功能，不再讨论。

# 安装抓包工具的证书

这里我推荐使用 [mitmproxy](https://www.mitmproxy.org/) 来替代 Charles，功能只多不少并且开源免费。

首先大多数的抓包工具都是通过创建一个对局域网开放的代理服务来实现流量捕获的，因此要通过设置设备的局域网代理来让设备接入到抓包工具。对于 Android Studio 模拟器来说，点击右侧更多操作按钮，然后在弹出的设置菜单中选择 Setting-Proxy，将代理配置选择为手动，并指向抓包工具的端口，对于 mitmproxy 来说，服务端口为 8080：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151546510.png)

当我们访问普通的 https 页面出现了证书错误，说明代理接入成功了。

然后在模拟器中访问 `mitm.it` 网站，下载证书：

![image.png|603](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151548213.png)

下载完成之后会出现系统弹窗提示需要安装。我们进入设置 - 安全 - 更多安全设置 - 加密与凭据 - 安装证书 - CA 证书 - 仍然安装，然后选择我们刚才下载的证书，会提示安装成功，并且在状态栏也会弹出证书提醒，在 “可信凭据” 中可以查看到我们刚才安装的证书：

![image.png|520](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151552815.png)

但是这时候你会发现应用发起的请求并不能成功接收到响应，因为我们现在还没有让系统信任我们安装的证书，对于不信任的请求安卓会直接将包丢弃掉。

# 使用 Magisk 插件信任用户证书

从 [Github release](https://github.com/NVISOsecurity/AlwaysTrustUserCerts/releases) 下载 Always Trust User Certs 插件。然后进入 Magisk - 模块 - 从本地安装，选择下载的 zip 包，然后会自动执行安装脚本，安装完成后点击重启按钮进行重启：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151608483.png)

重启完成之后状态栏仍有不信任证书的提醒，但是进入应用后会发现，进入 mitmproxy 的 web 控制台也能看到成功抓到并解密了 HTTPS 请求：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202508151623198.png)
# 后记：使用其他抓包工具

如果你觉得 MitmProxy 不好用，还有别的代理工具可以选择：

- [Whistle](https://github.com/avwo/whistle)
- [ProxyPin](https://github.com/wanghongenpin/proxypin)

但是你可能会发现这些抓包工具在设置了代理、安装了证书后还是没法抓包，这可能与 Android Studio 的网络代理模式相关 [issues](https://github.com/avwo/whistle/issues/1248)。

为了解决这个问题，首先需要将 Android Studio 模拟器设置中的代理进行关闭，然后安装这个软件：[AppProxy](https://github.com/ys1231/appproxy)，在软件中创建一个 VPN 代理来连接到代理工具，并在配置选项卡中勾选应用即可。
