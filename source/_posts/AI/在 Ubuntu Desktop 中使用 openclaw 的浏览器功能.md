---
title: 在 Ubuntu Desktop 中使用 openclaw 的浏览器功能
tags:
  - AI
  - OpenClaw
categories:
  - AI
date: 2026-02-22 16:44:57
---
# 安装正确的 Chrome 浏览器

Ubuntu Desktop 默认会安装一个 Chromium 浏览器，但是由于默认的应用被 snap 沙箱化了，导致 openclaw 无法正常调用，因此当你使用 `openclaw browser start` 时大概率会收到 `Failed to start Chrome` 的错误。

在官方文档中也有提到这一点：https://docs.openclaw.ai/tools/browser-linux-troubleshooting

解决方法为安装 Chrome 的 deb 包：

```
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y  # if there are dependency errors
```

安装完成后，需要将 openclaw 的配置文件（~/.openclaw/openclaw.json）的 browser 字段改为：

```
{
  "browser": {
    "enabled": true,
    "defaultProfile": "openclaw",
    "executablePath": "/usr/bin/google-chrome-stable",
    "headless": true,
    "noSandbox": true
  }
}
```

然后就可以正常调用浏览器，但也正如配置中所写的，只能以无头模式进行浏览。在这个模式下，浏览器是在后台进行操作的，如果想要人工介入就比较麻烦了。

既然我们已经使用的是 Ubuntu Desktop，那么我们更期望的是可以以 Headful 的模式运行浏览器，假如遇到页面中需要人工干预的部分，比如人机验证，我们就可以干预操作。

# 使用 headful 模式调用浏览器

当你把 headless 改为 true 后，并使用 `openclaw browser start` 后大概率会出现 `gateway timeout` 的错误。这是因为 Chrome 如果使用 headful 模式启动，则必须连接显示器，在 ssh 连接的命令行环境中如果宿主机没有登录到桌面，那么 Chrome 是无法打开的。

如果你确实成功登录了桌面，但是仍然 timeout，那么大概率是因为你登录到桌面的用户与运行 openclaw 的用户不一致导致的，比如你是用 root 用户运行的 openclaw，但是默认情况下 Ubuntu Desktop 是使用普通用户进行登录的，你需要按照 [这个教程](https://askubuntu.com/questions/1192471/login-as-root-on-ubuntu-desktop) 开启允许 root 用户登录到桌面，并成功登录 root 用户。

但是你还会发现，当你使用 root 用户登录成功之后，Chrome 应用打不开了，这是因为在 root 用户下，Chrome 默认是禁止使用的，你必须使用 `--no-sandbox` 才能启动 chrome，在 root 用户中启动 chrome 的流程为，打开终端并输入 `google-chrome --no-sandbox`。同样的，你需要将 openclaw 配置文件中的 `browser.noSandbox` 设置为 `true` 才可以。

至此，你应该可以诶正常使用 chrome 的 headful 模式了。