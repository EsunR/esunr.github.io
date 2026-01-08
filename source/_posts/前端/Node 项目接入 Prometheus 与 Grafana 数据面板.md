---
title: Node 项目接入 Prometheus 与 Grafana 数据面板
tags:
  - NodeJS
  - 前端工程化
categories:
  - 前端
date: 2026-01-08 14:15:13
---
# 1. 概述

Prometheus 是一个开源的监控与告警系统，在 Pull 模式下，其会以 HTTP 轮询的方式向目标应用的数据采集路径发起请求并获取数据。其会将收集到的数据按照时间序列进行存储，用户可以使用 PromQL 来进行查询，从而生成一个某一时间段的图表或者是用于监控警告。

Grafana 是一款开源的数据可视化与分析平台，主要用于将各种数据源中的指标、日志和追踪数据，以仪表盘（Dashboard）的形式直观展示出来，广泛应用于 监控、运维、数据分析和业务可视化场景。Grafana 支持 Prometheus 的时序数据库，因此 Grafana 经常用作 Prometheus 采集数据展示的前端进行使用。

# 2. Prometheus 的接入

对于 NodeJS 应用，可以使用 [prom-client](https://www.npmjs.com/package/prom-client) 进行接入，官方的接入说明有点绕，这也是我写本文的目的。

prom-client 存在如下几个基本概念：

- Registry：指标注册器，或者可以理解为一个数据的寄存器，当我们准备记录应用的指标值的时候必须创建一个 Registry。prom-client 内部也实例化好了一个默认的 Registry，如无必要，我们直接使用默认的寄存器即可，在下文示例中我们就直接引默认寄存器；
- Default Metrics：默认指标，prom-clint 提供了一个函数 `collectDefaultMetrics`，当我们想要采集应用的内存占用、CPU 占用等性能信息时，可以不用手动收集，直接用这个函数包裹 Registry 实例即可完成收集；
- Custom Metrics：指标，我们最常用的一个概念，也是 Prometheus 的核心。prom-client 提供了很多组件帮助我们收集一些自定义的业务指标，比如如果我们想收集 HTTP 的请求数量，就可以创建一个 Counter 组件实例，调用 `counter.inc()` 来计数，此外还有各种各样的组件；
- Label：标签，所有收集到的数据都可以添加标签，比如我们收集 HTTP 请求数量，收集时可以为原始数据添加请求方法的标签，这样我们就能区分出 GET、POST 请求的数量；

### 基础示例

创建指标收集器：

> 当我们直接声明 Custom Metrics 组件时，会将数据自动写入到 prom-client 默认的 Registry 中，因此下面的代码并没有实例化 Registry 和绑定 Custom Metrics 组件的过程。

```js
import promClient from 'prom-client';

const {Counter} = promClient;

export const counter = {
    // Request
    requestCounter: new Counter({
        name: 'http_request_count',
        help: 'HTTP 请求数量',
        labelNames: ['method'],
    }),
    // Response
    responseCounter: new Counter({
        name: 'success_response_count',
        help: '服务端返回的成功响应数量',
        labelNames: ['method', 'statusCode'],
    })
} as const;
```

使用示例：

```js
handleRequest(req, res) {
	const method = req.method;
	counter.requestCounter.inc({method});
}

handleResponse(req, res) {
	const method = req.method;
	const statusCode = res.statusCode;
	counter.responseCounter.inc({method, statusCode})
}
```

创建 `/metrics` 路径用于 Prometheus 获取数据（nitro 实现）：

```js
import {register} from 'prom-client';

export default defineEventHandler(async event => {
    const metrics = await register.metrics();
    return send(event, metrics, register.contentType);
});
```

### Node 集群示例

单应用模式下上面的示例已经足够使用了，但是当我们的应用是基于 [Node 集群](https://nodejs.cn/api/cluster.html)情况就略显复杂了。

这里简单介绍一下 Node 集群的工作方式：由于 NodeJS 是单线程的，只能利用一个 CPU 核心，因此我们可以通过创建多个进程的方式来充分利用 CPU，从而处理更多的并发。如果你使用 pm2，则可以开启 cluster 功能来快速实现，当然我们也可以通过写一个启动器的方式来实现。简单的示例如下：

```js
// start.js
import {fileURLToPath} from 'url';
import cluster from 'cluster';
import path from 'path';
import {createApp, createRouter, defineEventHandler, setResponseHeader, setResponseStatus, toNodeListener} from 'h3';
import {AggregatorRegistry} from 'prom-client';
import http from 'http';
import os from 'os';

export const clusterRegistry = new AggregatorRegistry();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const numCPUs = os.cpus().length;

if (cluster.isPrimary) {
    // 如果是主进程，创建多个工作进程
    console.log(`Master process started with PID: ${process.pid}`);
    // 根据 CPU 核心数启动工作进程
    for (let i = 0; i < numCPUs; i++) {
        const worker = cluster.fork({
            ...process.env,
        });
        worker.on('exit', (code, signal) => {
            console.log(`Worker process exited with code: ${code}, signal: ${signal}, trying to restart...`);
            // 重启工作进程
            cluster.fork();
        });
    }

    // 监听工作进程的退出
    cluster.on('exit', (worker, code, signal) => {
        console.log(`Primary process ${worker.process.pid} died`);
    });
} else {
    // 如果是工作进程，加载并运行 index.mjs
    // index.mjs 即服务器的程序入口代码
    import(path.resolve(__dirname, './index.mjs'))
        .then(module => {
            console.log('Worker process started with PID:', process.pid);
        })
        .catch(err => {
            console.error('Error starting worker:', err);
        });
}
```

启动指令由原来的 `node index.mjs` 改为 `node start.mjs`。

不难看出原理其实就是利用 Worker 来创建多个进程，而最顶层则是由一个 Primary（或者叫 Master）进程控制。woerk 们是可以复用同一个端口的，当 HTTP 请求访问端口时候，cluster 会根据负载情况自动将请求转发到任意一个实例上。

但是如果请求是 Prometheus 的数据采集那就乱套了，Prometheus 每次拉取数据拉的可能不是一个固定的应用实例，而是任意一个实例的数据，比如上一秒拉取的请求数是自实例 A 的 100，下一秒获取的请求数是来自实例 B 的 200，数据就乱套了。

好在 prom-client 提供了集群模式下的解决方案 `AggregatorRegistry` 收集器（新版可能叫`ClusterRegistry`）。其内部的工作原理是当我们访问 AggregatorRegistry 收集器时，其会向当前进程所有的 worker 都发送一条 postMessage 通知，worker 们收到响应后，会将各自的数据进行返回，然后 AggregatorRegistry 将这些数据进行汇总，返回给数据请求者。

这就要求我们在 Primary 进程中创建一个额外的 http 服务专门用于集群数据的请求，实现代码如下：

```js
import {fileURLToPath} from 'url';
import cluster from 'cluster';
import os from 'os';
import path from 'path';
import {createApp, createRouter, defineEventHandler, setResponseHeader, setResponseStatus, toNodeListener} from 'h3';
import {AggregatorRegistry} from 'prom-client';
import http from 'http';

export const clusterRegistry = new AggregatorRegistry();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const numCPUs = os.cpus().length;
const MASTER_PORT = 4000;

if (cluster.isPrimary) {
    // 如果是主进程，创建多个工作进程
    console.log(`Master process started with PID: ${process.pid}`);
    // 根据 CPU 核心数启动工作进程
    for (let i = 0; i < numCPUs; i++) {
        const worker = cluster.fork({
            ...process.env,
        });
        worker.on('exit', (code, signal) => {
            console.log(`Worker process exited with code: ${code}, signal: ${signal}, trying to restart...`);
            // 重启工作进程
            cluster.fork();
        });
    }

    // 监听工作进程的退出
    cluster.on('exit', (worker, code, signal) => {
        console.log(`Primary process ${worker.process.pid} died`);
    });

    const app = createApp();
    const router = createRouter();
    app.use(router);
    router.get(
        '/cluster_metrics',
        defineEventHandler(async event => {
            try {
                const metrics = await clusterRegistry.clusterMetrics();
                setResponseHeader(event, 'Content-Type', clusterRegistry.contentType);
                return metrics;
            } catch (err) {
                console.error(err);
                setResponseStatus(event, 500);
                return 'Error retrieving metrics';
            }
        })
    );
    const server = http.createServer(toNodeListener(app));
    server.listen(MASTER_PORT, '0.0.0.0', () => {
        console.log(`Cluster metrics server listening to ${MASTER_PORT}, metrics exposed on /system/cluster_metrics`);
    });
} else {
    // 如果是工作进程，加载并运行 server/index.mjs
    import(path.resolve(__dirname, './index.mjs'))
        .then(module => {
            console.log('Worker process started with PID:', process.pid);
        })
        .catch(err => {
            console.error('Error starting worker:', err);
        });
}

```

当我们访问 `4000` 端口的 `/cluster_metrics` 时获取的就是集群的整体数据。当然你也可以通过 Label 打上 worker id 的标签来将每个实例的数据进行区分。

> 需要特别注意的是，如果 `start.mjs` 是独立于主应用打包的，一定要保证运行时 `start.mjs` 主进程与子进程们引用的 prom-client 是同一个地方的（也就是同一块内存），否则指标会收集不到。比如如果使用 NuxtJS，一定要将 prom-client 作为 extranl 进行引用。

# 3. Grafana 的配置