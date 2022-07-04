---
title: Koa中的的错误处理方案
tags:
  - Koa
categories:
  - 后端
  - Node
date: 2019-11-16 18:02:17
---

# 1. 在 async 函数中错误捕获

我们通常处理 Promise 异步操作中的错误可以使用 `.catch(err=>{ ... })` 来处理，如：

```js
getAsyncData().then(() => {
  console.log("成功啦")
}).catch(() => {
  console.log("出错啦")
})
```

但是如果在 Koa 的路由处理函数中，使用这种方式去处理响应数据是无效的，比如：

```js
router.get('/getData', (ctx, next)=>{
  getAsyncData().then((data) => {
    ctx.body = {
      ok: ture,
      data: data,
      msg: ""
    }
  }).catch((err) => {
    ctx.body = {
      ok: false,
      data: "",
      msg: err.message
    }
  })
})
```

这样做前端调用该路由函数时，返回的结果为 404 。这其实是跟 JS 的事件轮询相关的，我们很容易就想明白，在异步函数中又创建了一个新的异步函数，新的异步函数的回调执行顺序肯定在当前异步函数的回调执行完毕之后。

也就是说，假如我们以这样的方式处理错误的话，当我们执行 `ctx.body` 赋值数据时，当前的请求已经发送完毕了，所以 `ctx.body` 是不能在内层的异步函数中调用的。如果我们需要通过异步获取数据，我们应该在当前的异步函数中使用 `await` 来阻塞数据获取的异步函数，如下：

```js
router.get('/getData', (ctx, next)=>{
  let data = await getAsycnData()
  ctx.body = {
    ok: ture,
    data: data,
    msg: ""
  }
}
```

但是，这样的话我们就无法捕捉错误了。如果想捕捉 `await` 的异步函数中的错误实际上也可以直接使用 `catch()` 来捕获，如像这样：

```js
router.get('/getData', (ctx, next)=>{
  let data = await getAsycnData().catch(err => {
    ctx.body = {
      ok: false,
      data: data,
      msg: ""
    }
  })
  ctx.body = {
    ok: true,
    data: data,
    msg: ""
  }
}
```

虽然这样的话，的确是可以捕获到错误，但是这样我们就会发现，由于执行顺序的问题，`ctx.body` 的操作会被后续的操作覆盖，我们无法在处理完错误后终止处理后续的逻辑。

但是 JS 中的 `try...catch...` 可以解决这个问题，我们只需要将其改为：

```js
router.get('/getData', (ctx, next)=>{
  try {
    let data = await getAsycnData()
      ctx.body = {
      ok: true,
      data: data,
      msg: ""
    }
  } catch (e){
    ctx.body = {
      ok: false,
      data: "",
      msg: e.message
    }
  }
}
```

这样处理的话，当在等待异步函数 `getAsycnData()` 时如果出现了错误，就会从中途跳出，被捕获到 `catch` 语句中，从而执行错误处理的函数。

# 2. 错误的聚合处理

我们可以在每个路由处理函数中都使用如上的方法处理错误，但是这样还是不够便捷，我们希望可以将出错信息进行聚合最后返回给请求者。我们可以利用 Koa 的中间件执行方式，将错误处理函数作为一个中间件函数，放在所用中间件的顶部：

```js
app.use(async (ctx, next) => {
  try {
    await next()
  } catch (err) {
    ctx.status = err.status || 500
    ctx.body = err.message
    ctx.app.emit("error", err, ctx)
  }
})
```

这样当 Koa 执行到该中间件时，会首先执行 `await next()` 然后执行后续的中间件，当其余中间件执行过程中出错，就会跳出到 `catch` 语句中，返回错误信息给数据请求者。