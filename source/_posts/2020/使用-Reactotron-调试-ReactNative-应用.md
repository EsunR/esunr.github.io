---
title: 使用 Reactotron 调试 ReactNative 应用
tags: [ReactNative]
categories:
  - Front
  - React
date: 2020-07-19 12:51:35
---

# 使用 Reactotron 进行调试

[Chain React 2018: Debugging and Beyond with Reactotron](https://www.youtube.com/watch?v=UiPo9A9k7xc)

安装 Reactotron 客户端：

> https://github.com/infinitered/reactotron/releases

在项目中安装 Reactotron:

```shell
$ yarn add reactotron-react-native
```

在根目录创建 `Reactotron.js` 文件，文件内容如下：

```js
import Reactotron from 'reactotron-react-native';

Reactotron.configure({
  host: 'localhost', // 连接真机测试必须添加该配置项
})
  .useReactNative() // add all built-in react native plugins
  .connect(); // let's connect!

```

在 `App.js` 或者 `index.js` 文件中对 Reactotron 脚本进行引入和调用：

```js
// 添加：
if (__DEV__) {
  import('./ReactotronConfig').then(() => console.log('Reactotron Configured'));
}
```

如果是使用真机进行调试，则需要调用 adb 指令进行端口转发：

```bash
$ adb reverse tcp:9090 tcp:9090
```

Tips：

- 在运行完端口转发的指令之后，需要手动 live reload 一下应用，才能连接上 Reactotron
- 每次 live reload 后 Reactotron 都会生成一个新设备