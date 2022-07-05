---
title: NodeJS爬虫基础原理及实战
tags:
  - 爬虫
categories:
  - 后端
  - Node
date: 2020-02-03 23:37:50
---

# 1. 原始数据的获取

## 1.1 原生 http 模块获取数据

http 是 node 内置的一个模块，可以使用该模块来发送一个简单的 http 请求：

```js
const http = require("http");

http.get("http://www.baidu.com", res => {
  res.setEncoding("utf8");
  res.on("data", res => {
    console.log(res);
  });
});
```

## 1.2 使用 request 模块获取数据

request 是一个第三方模块，可以更好的封装请求服务：

```js
const request = require("request");
request("http://www.baidu.com", (error, res, body) => {
  console.log("error: ", error);
  console.log("res: ", res);
  console.log("body: ", body);
});
```

## 1.3 使用 iconv-lite 解决编码问题

我们使用 [阳光电影网](https://www.ygdy8.net/index.html) 作为原始数据的抓取网站对象，但是由于该网站过于老旧，网站的编码格式为 `gb2312`，而原生 node 中支持的编码格式为：

*   ascii
*   base64
*   binary
*   hex
*   ucs2/ucs\-2/utf16le/utf\-16le
*   utf8/utf\-8
*   latin1 (ISO8859\-1, only in node 6.4.0+)

并不支持 `gb2312`，且默认回按照 `utf8` 的编码格式去解析文本，因此直接抓取网页数据会返回乱码结果，使用 `iconv-lite` 模块可以解决这一问题：

```js
const request = require("request");
const iconv = require("iconv-lite");

request(
  "https://www.ygdy8.net/html/gndy/oumei/list_7_2.html",
  { encoding: null }, // 默认为 utf8 错误编码
  (error, res, body) => {
    const bufs = iconv.decode(body, "gb2312");
    const html = bufs.toString("utf8");
    console.log(html);
  }
);
```

# 2. 数据的处理

## 2.1 cheerio

`cheerio` 是一个模拟 jQuery 的运行再 node 环境下的 HTML 解析器，可以将 HTML 字符串按照 jQuery 的方式进行快捷处理：

Demo:

```js
const cheerio = require("cheerio");
const $ = cheerio.load(`<h2 class="title">Hello world</h2>`);

$("h2.title").text("Hello there!");
$("h2").addClass("welcome");

console.log($.html());
```

```html
<html><head></head><body><h2 class="title welcome">Hello there!</h2></body></html>
```

## 2.2 并发抓取与处理数据

我们仍以 [阳光电影网](https://www.ygdy8.net/index.html) 作为数据的抓取对象，在其 [欧美专区](https://www.ygdy8.net/html/gndy/oumei/list_7_1.html) 中可以获取到电影的列表，如下图所示：

![](http://img.cdn.esunr.xyz/markdown/20200203224210.png)

利用 Chrome 的开发者工具可以获取到每个电影详情页面的链接，并获取其节点的选择器，如下：

![](http://img.cdn.esunr.xyz/markdown/20200203224426.png)

通过 `cheerio` 我们可以选择到该节点并获取其链接：

```js
// 对 request 模块进行封装
const requestPromise = url => {
  return new Promise((resolve, reject) => {
    request(
      url,
      { encoding: null }, // 默认为 utf8 错误编码
      (error, res, body) => {
        if (res.statusCode === 200) {
          const bufs = iconv.decode(body, "gb2312");
          const html = bufs.toString("utf8");
          resolve(html);
        } else {
          reject(error);
        }
      }
    );
  });
};

const host = "https://www.ygdy8.net";

const getList = async url => {
  const html = await requestPromise(url);
  const $ = cheerio.load(html);
  $(
    ".co_content8 ul table tbody tr:nth-child(2) td:nth-child(2) b a:nth-child(2)"
  ).each((i, item) => {
    const href = $(item).attr("href");
    console.log(href);
  });
};

getList("https://www.ygdy8.net/html/gndy/oumei/list_7_1.html")
```

结果：

```
/html/gndy/dyzz/20200127/59623.html
/html/gndy/jddy/20200127/59620.html
/html/gndy/jddy/20200127/59619.html
/html/gndy/dyzz/20200125/59616.html
/html/gndy/dyzz/20200123/59611.html
/html/gndy/jddy/20200123/59610.html
/html/gndy/dyzz/20200121/59608.html
/html/gndy/dyzz/20200121/59607.html
/html/gndy/dyzz/20200120/59605.html
/html/gndy/dyzz/20200119/59600.html
/html/gndy/dyzz/20200119/59598.html
/html/gndy/dyzz/20200117/59597.html
/html/gndy/dyzz/20200117/59596.html
/html/gndy/jddy/20200116/59592.html
/html/gndy/dyzz/20200116/59591.html
/html/gndy/dyzz/20200116/59590.html
/html/gndy/dyzz/20200115/59589.html
/html/gndy/dyzz/20200115/59588.html
/html/gndy/jddy/20200115/59587.html
/html/gndy/dyzz/20200114/59583.html
/html/gndy/dyzz/20200114/59582.html
/html/gndy/jddy/20200114/59581.html
/html/gndy/dyzz/20200113/59577.html
/html/gndy/dyzz/20200113/59576.html
/html/gndy/jddy/20200113/59575.html
```

当我们获取到一个电影的详情页面 url 后，就可以单独打开每个页面，然后利用 `cheerio` 去抓取数据详情。

我们通过分析电影详情页面，先输出单个电影的详情页：

```js
const getMovieDetail = async url => {
  const html = await requestPromise(url);
  const $ = cheerio.load(html);
  const movie = {
    name: $(".bd3l > div.co_area2 > div.title_all h1 font").text(),
    // desc 过长文章中省略输出
    // desc: $("#Zoom > span > p:nth-child(1)").text(), 
    picture: $("#Zoom > span > p:nth-child(1) > img:nth-child(1)").attr("src")
  };
  console.log(movie);
};

getMovieDetail(`https://www.ygdy8.net/html/gndy/dyzz/20200127/59623.html`);
```

结果：

```
{ 
  name: '2019年剧情《谎言大师》BD中英双字幕',
  picture: 'https://lookimg.com/images/2020/01/26/JMBaW.jpg' 
}
```

结合了上面的抓取方法之后，我们可以采用并发的方式，去抓取欧美电影第一页的所有电影的详情信息，完整代码如下：

```js
const request = require("request");
// 使用 iconv-lite 对老旧网站进行编码转换
const iconv = require("iconv-lite");
const cheerio = require("cheerio");

const requestPromise = url => {
  return new Promise((resolve, reject) => {
    request(
      url,
      { encoding: null }, // 默认为 utf8 错误编码
      (error, res, body) => {
        if (res.statusCode === 200) {
          const bufs = iconv.decode(body, "gb2312");
          const html = bufs.toString("utf8");
          resolve(html);
        } else {
          reject(error);
        }
      }
    );
  });
};

const host = "https://www.ygdy8.net";

const getMovieDetail = async url => {
  const html = await requestPromise(url);
  const $ = cheerio.load(html);
  const movie = {
    name: $(".bd3l > div.co_area2 > div.title_all h1 font").text(),
    // desc: $("#Zoom > span > p:nth-child(1)").text(),
    picture: $("#Zoom > span > p:nth-child(1) > img:nth-child(1)").attr("src")
  };
  console.log(movie);
};

const getList = async url => {
  const html = await requestPromise(url);
  const $ = cheerio.load(html);
  $(
    ".co_content8 ul table tbody tr:nth-child(2) td:nth-child(2) b a:nth-child(2)"
  ).each((i, item) => {
    const href = $(item).attr("href");
    getMovieDetail(host + href);
  });
};

getList("https://www.ygdy8.net/html/gndy/oumei/list_7_1.html")
```

结果：

```
{ name: '2018年高分获奖《他们已不再变老》BD英语中字', picture: undefined }
{ name: '2019年高分获奖剧情《痛苦与荣耀》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/14/9d77f7ad1383c453106e321ea6611606.jpg' }
{ name: '2019年惊悚剧情《劫匪/公路响马》BD中英双字幕',
  picture: 'https://lookimg.com/images/2020/01/21/JO1zh.jpg' }
{ name: '2019年奇幻冒险《沉睡魔咒2》BD国英双语双字',
  picture:
   'https://extraimage.net/images/2020/01/01/3ed5aaa5a2bff645bc258519b6338ba2.jpg' }
{ name: '2019年喜剧《白烂贱客2》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/13/753d9ea7958f8898fee58bca7418c815.jpg' }
{ name: '2019年科幻动作《终结者：黑暗命运》BD中英双字幕', picture: undefined }
{ name: '2019年科幻喜剧《杰克茜/神机有毛病》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/15/20bd24aca384f8b65c2d9ffc6fd48787.jpg' }
{ name: '2019年惊悚恐怖《落头氏之吻》BD泰语中字', picture: undefined }
{ name: '2019年获奖剧情《哈丽特/自由之火》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/18/5d5b14f0d53353a5caaebac0bca7eca9.jpg' }
{ name: '2015年高分悬疑剧情《误杀瞒天记》BD中字',
  picture:
   'https://extraimage.net/images/2020/01/16/109cb7e667131a9abec842384d109d5f.jpg' }
{ name: '2019年动作《敢死七镖客》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/25/8b4a82e47816c3e3bd4c2e56e5d222ef.jpg' }
{ name: '2019年剧情《谎言大师》BD中英双字幕',
  picture: 'https://lookimg.com/images/2020/01/26/JMBaW.jpg' }
{ name: '2019年悬疑惊悚《布鲁克林秘案》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/14/0b32b640a9f84260655004012fe2502f.jpg' }
{ name: '2014年奇幻冒险《沉睡魔咒》BD国英双语双字',
  picture:
   'https://extraimage.net/images/2020/01/17/6d181b7104d0f8b7a0929c3138efe494.jpg' }
{ name: '2019年惊悚动作《快递员》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/14/35ded36c5d4f54887244f88539722b8a.jpg' }
{ name: '2019年动画喜剧《动物特工局》HD国语中字',
  picture:
   'https://www.z4a.net/images/2020/01/26/5f6998b3eaa19ba6f.jpg' }
{ name: '2019年惊悚恐怖奇幻《睡梦医生加长版》BD中英双字幕',
  picture: 'https://lookimg.com/images/2020/01/24/JdkMq.jpg' }
{ name: '2019年喜剧《交友网战/爱程攻防战》BD泰语中字', picture: undefined }
{ name: '2019年奇幻动作《阿比盖尔/魔法禁界》BD英语中字',
  picture:
   'https://extraimage.net/images/2020/01/08/92aca31fe6be93f2896d130be25a420b.jpg' }
{ name: '2019年动画喜剧《雪人奇缘》BD英国粤三语双字',
  picture:
   'https://extraimage.net/images/2019/12/01/8275cc39f94fa9eefb8d1bd451567f67.jpg' }
{ name: '2019年惊悚恐怖《倒忌时/索命倒数》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/12/3d1c934d4ab10c65a3ceed81635170c6.jpg' }
{ name: '2017年惊悚动作《全面营救》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/12/50722770f13638a0e6ac21379912fe6f.jpg' }
{ name: '2019年动作《疾速杀机》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/13/4fb382ac730377ed36acf3306ca90273.jpg' }
{ name: '2019年动作《洛城夜巡》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/13/bdc7f21d21409f6d9aa44d7d9fb5de10.jpg' }
{ name: '2019年动画喜剧《亚当斯一家》BD中英双字幕',
  picture:
   'https://extraimage.net/images/2020/01/12/c78cf2a45898a8f2f19b5a8bda1d3726.jpg' }
```

## 2.3 大量数据抓取的优化

如果我们想要抓取整个欧美专区的所有电影信息，就需要获取每个页面的 url，我们先对其进行收集，这里以抓取200页数据为例：

```js
let urlArr = [];
for (let i = 0; i < 200; i++) {
  urlArr.push(`${host}/html/gndy/oumei/list_7_${i}.html`);
}

console.log(urlArr);
```

结果：

```
[ 
  'https://www.ygdy8.net/html/gndy/oumei/list_7_0.html',
  'https://www.ygdy8.net/html/gndy/oumei/list_7_1.html',
  'https://www.ygdy8.net/html/gndy/oumei/list_7_2.html',
  'https://www.ygdy8.net/html/gndy/oumei/list_7_3.html',
  'https://www.ygdy8.net/html/gndy/oumei/list_7_4.html',
  'https://www.ygdy8.net/html/gndy/oumei/list_7_5.html',
  'https://www.ygdy8.net/html/gndy/oumei/list_7_6.html',
  'https://www.ygdy8.net/html/gndy/oumei/list_7_7.html',
  'https://www.ygdy8.net/html/gndy/oumei/list_7_8.html',
  ... ...
]
```

如果我们再 for 循环中直接去执行文章 2.2 步骤中的 `getList()` 方法，如：

```js
for (let i = 0; i < 200; i++) {
  getList(`${host}/html/gndy/oumei/list_7_${i}.html`);
}
```

那么这就相当于同时异步访问 200*25 个 url，这对于资源有限的服务器来说压力是巨大的，因此我们要对其进行优化。

我们已知 `getList()` 方法会抓取电影列表的数据，然后再开启并发任务去抓取每个电影的详情，因此我们只要控制住 `getList()` 方法，不让其并发执行即可，因此我们会想到使用 `await`：

```js
for (let i = 0; i < 200; i++) {
  await getList(`${host}/html/gndy/oumei/list_7_${i}.html`);
}
```

但是再同步方法中是无法使用 `await` 的，那么有什么方法可以使用呢？如果创建一个异步方法，将 `for` 循环写入该异步方法中，然后再调用创建的异步方法可以解决，但是这样写并不优雅。我们采用另一种思路，使用 `Array.reduce()` 来创建异步方法：

```js
let urlArr = [];
for (let i = 0; i < 100; i++) {
  urlArr.push(`${host}/html/gndy/oumei/list_7_${i}.html`);
}

urlArr.reduce((rs, url) => {
  return rs.then(() => {
    return new Promise(async resolve => {
      await getList(url);
      resolve();
    });
  });
}, Promise.resolve());
```

或者：

```js
let urlArr = [];
for (let i = 0; i < 100; i++) {
  urlArr.push(`${host}/html/gndy/oumei/list_7_${i}.html`);
}

urlArr.reduce((rs, url) => {
  return rs.then(async () => {
    await getList(url);
  });
}, Promise.resolve());
```

其原理实际上都是利用 `reduce()` 方法创建了多个异步方法，并且使用 `await` 去等待异步方法的执行，这样我们就可以更好的限制同时发出的并发请求数量。

`Array.reduce(callback, initialValue)` 的参数详情如下：

`callback`

执行数组中每个值 (如果没有提供 `initialValue则第一个值除外`)的函数，包含四个参数：

- **`accumulator`**

  累计器累计回调的返回值; 它是上一次调用回调时返回的累积值，或`initialValue`（见于下方）。

- `currentValue`

  数组中正在处理的元素。

- `index` 可选

  数组中正在处理的当前元素的索引。 如果提供了`initialValue`，则起始索引号为0，否则从索引1起始。

- `array`可选

  调用`reduce()`的数组

`initialValue`可选

作为第一次调用 `callback`函数时的第一个参数的值。 如果没有提供初始值，则将使用数组中的第一个元素。 在没有初始值的空数组上调用 reduce 将报错。

> 参考公开课：https://www.bilibili.com/video/av75510075?t=5