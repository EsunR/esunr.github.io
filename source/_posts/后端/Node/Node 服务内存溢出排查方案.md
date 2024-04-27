---
title: Node 服务内存溢出排查方案
tags:
  - node
  - 内存溢出
categories:
  - 后端
  - Node
date: 2023-12-27 19:46:32
---
# 对于本地可复现的进行调试

使用 `ab` 指令可以在本地进行压测，如：

```sh
ab -n 2000 -c 100 http://localhost:8090/home
```

然后通过 `--inspect` 指令链接 chrome 调试器进行调试：

```sh
node --inspect --heapsnapshot-signal=SIGUSR2 ./server.js
```

> `--heapsnapshot-signal=SIGUSR2` 表示接收到 SIGUSR2 信号时生成堆内存快照。

然后使用浏览器访问 [chrome://inspect/#devices](chrome://inspect/#devices)，点击 inspect：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240427195201.png)
弹出调试面板后就可以在 Memory 选项卡下生成堆快照了：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240427195442.png)

通常我们可以在项目启动时进行一次快照生成，然后在压测完成后再生成一个快照，在选项卡中选择展示两个快照的对比结果，就能展示出来压测后新创建的内存信息，这里的排序通常按照 `Retained Size` 表示当前对象及自身所占的内存其引用对象的总内存：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240427195949.png)

上面结果中发现 array 类型和 string 类型的数据内存占用很大，比较可疑，可以对其进行展开操作，并展示其具体值：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240427200401.png)

由上图的对象信息可以查看到其创建对象的变量名、以及调用位置：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240427200447.png)

我们对变量和函数名称进行查找，就能发现具体原因是因为创建了一个未销毁的全局变量：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240427200652.png)

# 对于线上存在的内存溢出问题

# 为了防止内存溢出我们应该做什么？

1. 注意全局变量；
2. 内存溢出的本质就是对象被占用，只要确保对象没有没持续引用，哪怕是控制台输出其都是一个被占用的状态；
3. 为某个对象添加重复的监听事件也可能导致内存不被销毁；
4. 避免使用匿名函数，这会让代码调试变得很难，调试时也注意关闭 terser 等代码压缩和混淆；
5. TODO 。。。