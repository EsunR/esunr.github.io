---
title: 使用 alipay-sdk-nodejs 让 node 应用接入支付宝付款
tags:
  - Node
  - 支付宝
categories:
  - 前端
  - Javascript
date: 2019-10-22 22:20:28
---
# 1. 开发构思

我们的总体需求是让 node js 应用接入支付宝，完成用户付款，具体流程是：

- 当用户在商户应用点击付款后，页面跳转到支付宝界面，这时会出现两种情况：
	- 手机用户唤醒支付宝应用
	- PC 唤醒支付宝收银台
- 用户在支付宝页面进行付款，并完成付款
- 支付宝检测用户完成付款后向商户应用发送一个 POST 请求作为支付完成的异步回调
- 商户应用对回调信息进行验证后，对订单状态进行变更
- 用户返回商户应用，刷新订单界面，显示该订单已支付

# 2. 前期准备
我们以 Koa 为例，简单演示一下接入支付宝的具体流程，首先安装 Koa 本体以及所需的中间件：

```sh
npm install koa koa-router koa-static koa-bodyparser -S
```

之后需要安装阿里官方提供的 nodejs 端的支付宝 sdk：

```sh
npm install alipay-node-sdk -S
```

当所有的开发依赖准备完成之后，我们可以直接申请应用，同时也可以到支付宝开放平台上使用 [沙箱环境](https://openhome.alipay.com/platform/appDaily.htm) 来模拟真实应用。在此我们以沙箱环境进行开发演示，在沙箱界面需要记住 **APPID**：

![image.png](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9pLmxvbGkubmV0LzIwMTkvMTAvMjIvaTdWaGUxY3B3MkFiTFBZLnBuZw?x-oss-process=image/format,png)
同时点击下方的 RSA2 密钥，并下载密钥生成工具，分别生成私钥和公钥。我们要将生成的 **应用私钥** 记录下来，存放到 `private-key.pem` 文件中；之后再将 "应用公钥" 填写到页面中，从而会生成一个 **支付宝公钥** ，记录该公钥到 `public-key.pem` 文件中，前期准备工作完成。如果还不清楚以上流程，参考 [说明文档](https://docs.open.alipay.com/291/105971#LDsXr)。

我们来整理一下文件，将密钥文件整理在一起，这样前期准备工作就完成了：
```js
.
├── package.json
├── package-lock.json
├── serve.js // 主服务
└── static
    ├── index.html // 客户端
    └── pem // 密钥存放文件夹
        ├── private-key.pem
        └── public-key.pem
```

# 3. 部署应用

## 3.1 alipay-node-sdk 的使用
当用户点击付款信按钮，会触发我们服务器上的一个路由条件，在这个路由中，我们的服务器主动向支付宝服务器发送了一个请求，请求中携带着该条支付的信息（如订单号、商品价格等），同时还携带了私钥信息，当支付宝服务器收到该条请求后，会向我们的服务器返回一个付款 url，我们的服务器再将该条 url 信息转发到前端页面上，由前端页面完成跳转逻辑。

而使用 `alipay-node-sdk` 就简化了我们的服务器向支付宝服务器发送请求信息的这一过程，它会将必要的参数与加密信息处理好，我们只需要传入业务参数就可以了。

#### 构建 Sdk 实例

当我们引入 `alipay-node-sdk` 时首先要对其进行实例化以及全局参数的设置：

```js
const AlipaySdk = require('alipay-sdk').default;
const alipaySdk = new AlipaySdk({
   appId: '2016**********710', // 之前我们所记录的沙箱环境的 sdk
   privateKey: fs.readFileSync('./static/pem/private-key.pem', 'ascii'), // 传入私钥
   gateway: "https://openapi.alipaydev.com/gateway.do" // 沙箱环境的请求网关与正式环境不一样，需要在此更改，如果是使用正式环境则去掉此处的设置
 });
```

#### alipaySdk.exec()

`alipaySdk.exec()`  方法可以帮我们简便的发送一个业务请求，在 [支付API文档](https://docs.open.alipay.com/api_1) 中我们可以查看到所有的业务请求列表，我们以发送一个 [统一收单交易关闭接口(alipay.trade.close)](https://docs.open.alipay.com/api_1/alipay.trade.close) 为例：

```js
const result = await alipaySdk.exec('alipay.trade.close', {
  notifyUrl: 'http://notify_url',
  appAuthToken: '',
  // 通过 bizContent 传递请求参数
  bizContent: {
    tradeNo: '',
    outTradeNo: '',
    operatorId: '',
  },
});

// 从官方文档看到，result 包含 tradeNo、outTradeNo 2 个 key
console.log('tradeNo: %s, outTradeNo: %s', result.tradeNo, result.outTradeNo);
```

> 这是 alipay-sdk-nodejs 官方提供的演示 demo

这就引出了我们接下来需要用到的两个接口：

-  [alipay.trade.wap.pay(手机网站支付接口2.0)](https://docs.open.alipay.com/api_1/alipay.trade.wap.pay/)：用于返回手机端的支付唤起地址
- [alipay.trade.page.pay(统一收单下单并支付页面接口)](https://docs.open.alipay.com/api_1/alipay.trade.page.pay/)：用于返回 PC 端的支付宝收银台地址

#### AlipayFormData.addField()

如果我们按照上述的方式去请求 alipay.trade.wap.pay 以及 alipay.trade.page.pay 两个接口的话是会返回错误信息的。因为这两个接口属于页面类接口，页面类接口默认返回的数据为 html 代码片段。这类接口我们需要创建一个 FormData 去请求，**而不能直接使用 `alipaySdk.exec()` 传入业务参数**。

Sdk 提供了一个 `AlipayFormData` 可以方便我们的创建，这里我们以 alipay.trade.page.pay 接口为示例：

```js
// TypeScript
// import AlipayFormData from 'alipay-sdk/lib/form'; 

// js
const AlipayFormData = require('alipay-sdk/lib/form').default

const formData = new AlipayFormData();
// 调用 setMethod 并传入 get，会返回可以跳转到支付页面的 url，否则返回的是一个表单的 html 片段
formData.setMethod('get');

formData.addField('notifyUrl', 'http://www.com/notify'); // 当支付完成后，支付宝主动向我们的服务器发送回调的地址
formData.addField('returnUrl', 'http://www.com/return'); // 当支付完成后，当前页面跳转的地址
formData.addField('bizContent', {
  outTradeNo: 'out_trade_no',
  productCode: 'FAST_INSTANT_TRADE_PAY',
  totalAmount: '0.01',
  subject: '商品',
  body: '商品详情',
});

const result = await alipaySdk.exec(
  'alipay.trade.page.pay',
  {},
  { formData: formData },
);

// result 为可以跳转到支付链接的 url
console.log(result);
```

在这里要特别注意，支付宝在用户付款完成后，会向我们的服务器发送一条 **POST 方式** 的异步回调，这个回调地址必须是外网可以访问到的，也就是说这一过程我们必须在线上开发。

## 3.2 Demo

介绍完了alipay-node-sdk 的使用，那么接下来就上一个完整的示例进行整体的演示，由于上面已经演示了如何请求 alipay.trade.page.pay(统一收单下单并支付页面接口)，那么接下来就演示一下如何请求 alipay.trade.wap.pay(手机网站支付接口2.0) 让用户进行手机支付：

> 注意项目必须在线上开发！否则只会跳转到支付宝界面而接收不到支付宝的异步回调！

整体目录：

```sh
├── package.json
├── package-lock.json
├── serve.js 
└── static
    ├── index.html
    └── pem 
        ├── private-key.pem
        └── public-key.pem
```

serve.js

```js
const Koa = require('koa')
const Router = require('koa-router')
const static = require('koa-static')
const path = require('path')
const fs = require('fs')
const AlipaySdk = require('alipay-sdk').default;
const AlipayFormData = require('alipay-sdk/lib/form').default
const bodyParser = require('koa-bodyparser')

const app = new Koa()
const router = new Router()

const staticPath = './static'
app.use(static(
  path.join(__dirname, staticPath)
))

app.use(bodyParser())

router.get('/pay', async (ctx, next) => {
  const alipaySdk = new AlipaySdk({
    appId: '20161*******6710',
    privateKey: fs.readFileSync('./static/pem/private-key.pem', 'ascii'),
    gateway: "https://openapi.alipaydev.com/gateway.do"
  });


  const formData = new AlipayFormData()
  formData.setMethod("get")
  formData.addField("notifyUrl", "http://online_serve_url/paycallback") // 回调地址必须为当前服务的线上地址！
  formData.addField("returnUrl", "http://online_serve_url/success")
  formData.addField("bizContent", {
    body: "测试商品",
    subject: "女装",
    outTradeNo: new Date().valueOf(),
    totalAmount: "88.88",
    quitUrl: "http://www.taobao.com/product/113714.html",
    productCode: "QUICK_WAP_WAY"
  })
  const result = await alipaySdk.exec("alipay.trade.wap.pay", {}, {
    formData: formData,
    validateSign: true
  })
  ctx.body = result
})

router.post('/paycallback', async (ctx, next) => {
  let postData = ctx.request.body;
  console.log("触发付款");
  if (postData.trade_status === "TRADE_SUCCESS") {
    let data = ctx.request.body // 订单信息
  	// ========= 由请求体内的订单信息，在这里进行数据库中订单状态的更改 ============
    console.log("支付完成！");
  }
})

router.get('/success', async (ctx, next) => {
  ctx.body = "支付成功"
})


app.use(router.routes())

app.listen(9090)
```

index.html：

```html
<!DOCTYPE html>
<html lang="zh-CN">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  <title>Document</title>
  <script src="https://cdn.bootcss.com/axios/0.19.0-beta.1/axios.min.js"></script>
  <script src="https://gw.alipayobjects.com/as/g/h5-lib/alipayjsapi/3.1.1/alipayjsapi.min.js"></script>
  <script>
    window.onload = function () {
      let oPay = document.querySelector("#pay")
      oPay.addEventListener('click', function () {
        axios.get('http://47.106.226.190:9090/pay').then(res => {
          window.open(res.data);
        })
      })
    }
  </script>
</head>

<body>
  <button id="pay">创建付款</button>
  <div id="form"></div>
</body>

</html>
```

> PS：接收到支付宝的异步回调之后，还需要进行异步回调的验签，以保证回调是由支付宝发送的，这个目前还没有研究出来，等研究出来再更新吧。
