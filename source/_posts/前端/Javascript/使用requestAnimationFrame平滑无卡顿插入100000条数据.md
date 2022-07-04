---
title: 使用requestAnimationFrame平滑无卡顿插入100000条数据
tags: []
categories:
  - 前端
  - Javascript
date: 2019-12-02 22:17:09
---

# 1. 前言

网页回流与重绘有时可能会比 JS 的执行消耗更长的时间，比如插入十万条数据，这可能是一个伪需求，但是也是一个值得思考的命题。接下来我们的例子中的 html 都用如下的结构，点击页面按钮后，将 100000 个 `li` 插入到 `ul` 中去：

```html
<body>
  <button onclick="pushLi()">添加数据</button>
  <ul></ul>
</body>
```

我们先来看一下直接暴力插入 100000 条数据的写法：

```js
function pushLi() {
  const startTime = new Date().valueOf()
  const count = 100000
  const ul = document.querySelector("ul")
  for (let i = 0; i < count; i++) {
    const li = document.createElement('li')
    li.innerText = Math.random() * count
    ul.appendChild(li)
  }
  console.log(new Date().valueOf() - startTime);
}
```

点击按钮，页面大概消耗了 5s 的时间才把内容渲染出来，但是我们看控制台打印出的时间差只有 1s 左右。

![](https://i.loli.net/2019/12/02/a6gsRlMCG5jmk9p.png)

这是因为浏览器本身存在优化机制，如果没进行一次 `appendChild` 操作就渲染一次页面，那么就要渲染十万次页面，这样是非常消耗性能的。所以浏览器就会将渲染任务缓存到队列中，在一定的范围内将页面的所有操作合并为一个渲染操作。但是十万条数据仍是一个庞大的数据，因此就会出现 js 已经计算完成，但是渲染仍为完成的情况，此时页面会卡住不动。

# 2. 初级优化

`document.createDocumentFragment()` 可以创建一个片段，这个片段并没有插入的 DOM 结构中，因此就省去了 DOM 查询的步骤，我们将创建的 `li` 没次都插入到 `fragment` 中，而不是每次都插入页面的 DOM 中，最后再将 fragment 插入到页面的 `ul` 中，这样的话就能一定程度提升 js 运算的性能，从而优化整体效果：

```js
function pushLi() {
  const startTime = new Date().valueOf()
  const count = 100000
  const ul = document.querySelector("ul")
  const fragment = document.createDocumentFragment()
  for (let i = 0; i < count; i++) {
    const li = document.createElement('li')
    li.innerText = Math.random() * count
    fragment.appendChild(li)
  }
  ul.appendChild(fragment)
  console.log(new Date().valueOf() - startTime);
}
```

我们在控制台中查看打印的时间差，可以发现 JS 的执行速度提升了一倍：

![](https://i.loli.net/2019/12/02/m9awpHG2cKPbBdf.png)

那么渲染速度是否会因此提升呢？很遗憾并不，渲染仍在消耗相同的时间，因为我们最终插入页面的数据仍然是十万条，对于浏览器页面来说，仍是一次渲染十万条数据。

# 3. 节流插入

我们换一种思路，既然一次插入 100000 条数据会给浏览器造成巨大的压力，那么每次只要少渲染一点不久可以了吗。比如说我们在 100ms 渲染 100 条数据，十万条数据分 1000 次插入，也就是耗时 1000 * 100s，虽然耗时相比之下长了，但是页面不卡顿了，用户点击之后马上就可以看到数据，同时数据也在不断增长，直到十万条数据都出来，浏览器便可以停止渲染，这比让用户盯着屏幕卡顿 10 秒的效果好的多。

于是我们来优化一下写法：

```js
function pushLi() {
  const ul = document.querySelector("ul")
  const total = 100000
  const once = 100
  const loopCount = total / once
  let countOfRender = 0
  function add() {
    // 每 100 毫秒添加 100 条 li
    setTimeout(() => {
      const fragment = document.createDocumentFragment()
      for (let i = 0; i < once; i++) {
        const li = document.createElement("li")
        li.innerText = Math.random() * total
        fragment.appendChild(li)
      }
      ul.appendChild(fragment)
      // 当前渲染到第几次
      countOfRender += 1
      // 如果没有渲染完成就递归再渲染一次
      if (countOfRender < loopCount) {
        add()
      }
    }, 100);
  }
  add()
}
```

![](https://i.loli.net/2019/12/02/1tZNFeqbydKLRV2.gif)

这样页面就不会卡顿了，但是这样的渲染并没有用到浏览器的性能极限。想想假如我们要想提高渲染效率，要从哪里下手呢？就是去将每次渲染的间隔时间尽量最小化，我们上面的例子使用了 100ms 这其实是不够极限的，只要时间段够短并且浏览器能渲染得过来，那就是合理的。那么最小到哪个阈值呢，我们都知道大部分屏幕的刷新率是 60hz 也就是每秒刷新 60 次，对于我们页面来说极限就是每秒渲染 60 次。我们用 100/60 得出每间隔 16ms 刷新一次是浏览器显示的极限，我们可以将 `setTimeout` 的时间间隔设置为 16 即可。

但是当我得意的将 `setTimeout` 的延时设置为 16ms 时突然发现事情并不对... ...

![](https://i.loli.net/2019/12/02/2P7WbHKjuGx4MUd.png)

发现改为了 16ms 之后，按理说，数据增长应该是平滑的，然而改了之后还是跟之前一样数据是一卡一卡的。emmmm，我知道 setTimeout 有最小值，查了一下最小值为 4ms，这也不对啊。上 MDN 查阅了一下发现了一篇文章 [实际延时比设定值更久的原因：最小延迟时间](https://developer.mozilla.org/zh-CN/docs/Web/API/Window/setTimeout#%E5%AE%9E%E9%99%85%E5%BB%B6%E6%97%B6%E6%AF%94%E8%AE%BE%E5%AE%9A%E5%80%BC%E6%9B%B4%E4%B9%85%E7%9A%84%E5%8E%9F%E5%9B%A0%EF%BC%9A%E6%9C%80%E5%B0%8F%E5%BB%B6%E8%BF%9F%E6%97%B6%E9%97%B4)。

MDN 告诉我们，多次嵌套 `setTimeout` 可能会导致计时器的时间推迟。我们添加一个记录值，来记录上次渲染结束到本次渲染结束的时间间隔，也就是实际 setTimeout 延迟的时间，发现果然随着嵌套的深度，延迟执行的时间越来越长：

![刚开始的耗时](https://i.loli.net/2019/12/03/uOM1wCa4cFpsg9b.png)

![当嵌套越来越深时](https://i.loli.net/2019/12/03/iRrIjK9nA6Sadyv.png)

所以为了避免嵌套，那么我们就只能利用异步编程，来逐个循环执行定时器了，改写一下我们之前写好的方法：

```js
function pushLi() {
  const ul = document.querySelector("ul")
  const total = 100000
  const once = 20
  const loopCount = total / once
  let countOfRender = 0
  // 执行定时器的方法改写为一个 promise 
  function add() {
    return new Promise(resolve => {
      setTimeout(() => {
        const fragment = document.createDocumentFragment()
        for (let i = 0; i < once; i++) {
          const li = document.createElement("li")
          li.innerText = Math.random() * total
          fragment.appendChild(li)
        }
        ul.appendChild(fragment)
        countOfRender += 1
        resolve()
      }, 16);
    })
  }
  // 专门用来执行循环的函数
  // 当执行完一个定时器后再开启一个新的定时器，所以定时器之间不存在嵌套
  async function loop() {
    await add()
    if (countOfRender < loopCount) {
      console.log(countOfRender);
      await loop()
    }
  }
  loop()
}
```

这下就好多了，当渲染到第 287 次的时候，仍能保持时间间隔为 34ms。可以看出就算定时器没有嵌套，也会出现数据越多定时器的耗时间隔越长的情况。我分析可能会是这两个原因：要么是由于时间间隔过短，渲染没有跟上速度，导致了执行被阻塞，越来越往后推；要么是页面中还有定时器影响着新定时器的执行速度。

![](https://i.loli.net/2019/12/03/aiKUjVTt5uGYDJ7.png)


# 4. requestAnimationFrame

终于到了我们的主客 `requestAnimationFrame`，其实原理跟我们上面讲的几乎是一摸一样，但是 `requestAnimationFrame` 提供了一种更优雅的方式，以及更好的优化性能，我们将上面的定时器改为 `requestAnimationFrame`，方法就变成了：

```js
function pushLi() {
  const total = 100000
  const once = 20
  const loopCount = total / once
  let countOfRender = 0
  let ul = document.querySelector("ul")
  function add() {
    const fragment = document.createDocumentFragment()
    for (let i = 0; i < once; i++) {
      const li = document.createElement("li")
      li.innerText = Math.random() * total
      fragment.appendChild(li)
    }
    ul.appendChild(fragment)
    countOfRender += 1
    loop()
  }
  function loop() {
    if (countOfRender < loopCount) {
      window.requestAnimationFrame(add)
    }
  }
  loop()
}
```

这感觉，丝滑般流畅：

![](https://i.loli.net/2019/12/03/K8YNJ9ZkdtsObSG.gif)

但是，使用 `requestAnimationFrame` 也会出现后期时间间隔边长，也就是帧率变低的情况，也许就是因为页面数据过多造成性能的上不足导致的，但是相比与纯定时器，效果会更好一丢丢：

![requestAnimationFrame 在 1100 次渲染时的耗时间隔](https://i.loli.net/2019/12/03/puX2Uh6t8nHbIP7.png)

![setTimeout 在 1100 次渲染时的耗时间隔](https://i.loli.net/2019/12/03/iq3aeGwyQpcE6lf.png)