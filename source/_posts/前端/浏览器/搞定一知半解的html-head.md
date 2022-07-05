---
title: 搞定一知半解的 <Head>
tags: []
categories:
  - 前端
  - 浏览器
date: 2020-03-20 20:18:39
---

# 1. Head 的作用

HTML 头部是包含在 `<head>` 元素里面的内容。不像 `<body>` 元素的内容会显示在浏览器中，head 里面的内容**不会在浏览器中显示**，它的作用是包含一些页面的元数据。

> 名词解释：元数据(Metadata)是用来概括描述数据的一些基本数据，比如一个人身高为 180cm 体重为 78kg，那么其身高与体重就是这个人的元数据。 

# 2. title

HTML `<title>` 元素 定义文档的标题，显示在浏览器的标题栏或标签页上。它只应该包含文本，若是包含有标签，则它包含的任何标签都将被忽略。

> 这个元素值拥有[全局属性。](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes)

一个好的 title 的作用通常需要考虑如下几点
- title 是一个 SEO 的重要鉴别对象，不要使用过于普遍的词汇作为完整的 title
- 动态改变 title 来形容当前页面的内容，可以更好的解决无障碍问题

# 3. meta

[MDN 文档](https://developer.mozilla.org/zh-CN/docs/Web/HTML/Element/meta)

`<meta>` 元素表示那些不能由其它HTML元相关元素 ([`<base>`](https://developer.mozilla.org/zh-CN/docs/Web/HTML/Element/base "HTML <base> 元素 指定用于一个文档中包含的所有相对 URL 的根 URL。一份中只能有一个 <base> 元素。"), [`<link>`](https://developer.mozilla.org/zh-CN/docs/Web/HTML/Element/link "HTML外部资源链接元素 (<link>) 规定了当前文档与外部资源的关系。该元素最常用于链接样式表，此外也可以被用来创建站点图标(比如PC端的“favicon”图标和移动设备上用以显示在主屏幕的图标) 。"), [`<script>`](https://developer.mozilla.org/zh-CN/docs/Web/HTML/Element/script "HTML <script> 元素用于嵌入或引用可执行脚本。"), [`<style>`](https://developer.mozilla.org/zh-CN/docs/Web/HTML/Element/style "HTML的<style>元素包含文档的样式信息或者文档的部分内容。默认情况下，该标签的样式信息通常是CSS的格式。") 或 [`<title>`](https://developer.mozilla.org/zh-CN/docs/Web/HTML/Element/title "HTML <title> 元素 定义文档的标题，显示在浏览器的标题栏或标签页上。它只应该包含文本，若是包含有标签，则它包含的任何标签都将被忽略。")) 之一表示的任何元数据信息。

## 3.1 charset

此特性声明当前文档所使用的字符编码，但该声明可以被任何一个元素的 lang 特性的值覆盖。最常见的就是再每个页面开头声明格式为 `utf-8`：

```html
<meta charset="utf-8">
```

此外，不应该使用不兼容ASCII的编码规范， 以避免不必要的安全风险：浏览器不支持他们(这些不规范的编码)可能会导致浏览器渲染html出错. 比如JIS_C6226-1983, JIS_X0212-1990, HZ-GB-2312, JOHAB,ISO-2022 系列,EBCDIC系列 等文字。

## 3.2 http-equiv

这个枚举属性定义了能改变服务器和用户引擎行为的编译，其可以设置如下的几个属性值（但是具体的编译值使用 `content` 属性来定义）：

### 3.2.1 content-language（废弃）

这个指令定义页面使用的默认语言。

> 不要使用这个指令，因为它已经过时了。使用 `<html>` 元素上全局的 lang 属性来替代它！

`"content-security-policy"内容安全策略`：

它允许页面作者定义当前页的内容策略，相当于设置了一个白名单机制。内容策略主要指定允许的服务器源和脚本端点，这有助于防止跨站点脚本攻击。

示例：

```html
<meta http-equiv="Content-Security-Policy" content="script-src 'self'; object-src 'none'; style-src cdn.example.org third-party.org; child-src https:">
```

上面代码中，CSP 做了如下配置。

*   脚本：只信任当前域名
*   `<object>`标签：不信任任何URL，即不加载任何资源
*   样式表：只信任`cdn.example.org`和`third-party.org`
*   框架（frame）：必须使用HTTPS协议加载
*   其他资源：没有限制

更多：[Content Security Policy 入门教程](http://www.ruanyifeng.com/blog/2016/09/csp.html)

### 3.2.2 content-type（废弃）

这个属性定义了文档的 MIME type , 实际上由它的字符编码决定。它遵循与HTTP content-type 头部字段相同的语法， 但由于它位于HTML页面内，因此除了text / html之外的大多数值都不能使用。 因此，其content的有效语法是字符串'text / html'，后跟一个具有以下语法的字符集：';charset=IANAcharset，其中IANAcharset是IANA定义的字符集的首选MIME名称。

由于 `<meta>` 不能在 XHTML 或 HTML5 的 XHTML 序列化中更改文档的类型，因此切勿使用`<meta>` 将MIME类型设置为 XHTML MIME 类型。

> 不要使用该指令因为它已过时。使用 `<meta>` 元素的charset 属性代替。

### 3.2.3 refresh

这个属性指定:

*   如果`content` 只包含一个正整数,则是重新载入页面的时间间隔(秒);
*   如果`content` 包含一个正整数并且跟着一个字符串,则是重定向到指定链接的时间间隔(秒)

```html
<!-- 5秒之后刷新本页面 -->
<meta http-equiv="refresh" content="5" />
```

```html
<!-- 5秒之后转到某一页面-->
<meta  http-equiv="refresh" content="5;url=https://esunr.xyz"/>
```

更多：[小tip: 使用meta实现页面的定时刷新或跳转](https://www.zhangxinxu.com/wordpress/2015/03/meta-http-equiv-refresh-content/)

### 3.2.4 set-cookie（废弃）

为页面定义cookie。其内容必须遵循 IETF HTTP Cookie 规范中定义的语法。

> 请勿使用此说明，因为它已过时。请改用 HTTP 的 Set-Cookie 头部。

## 3.3 name

name 属性是一个比较杂糅的属性，其可以控制 SEO 的检索信息以及浏览器某些行为的相关设置。严格点来讲：**该属性定义文档级元数据的名称**。

同时，如果一个 meta 标签中包含了 itemprop、http-equiv、charset 任意一个属性的话就不能再定义 name，如下面的这个 meta 就是不合法的：

```html
<meta charset="utf-8" name="viewport" content="width=device-width, initial-scale=1.0">
```

name 属性可以定义元数据的类型，content 属性可以定义这些元数据类型的具体值，由于 name 可配置的属性过多，因此就分开来讲：

### 3.3.1 SEO 相关

* `application-name`，定义正运行在该网页上的网络应用名称;
  
  说明：
  * 浏览器可能会通过使用该属性去区分应用。它与 `<title>` 元素不同，后者通常由应用程序名称组成，但也可能包含特定信息，如文档名称或状态;
  * 简单的网页不应该去定义application\-name meta标签。
  
* `author`，就是这个文档的作者名称，可以用自由的格式去定义；

  举例：
  ```html
  <meta name="author" content"root,root@21cn.com">
  ```

* `description`，其中包含页面内容的简短和精确的描述。 一些浏览器，如Firefox和Opera，将其用作书签页面的默认描述。

  举例：
  ```html
  <meta name ="keywords" content="science, education,culture,politics,ecnomics，relationships, entertaiment, human">
  ```

* `generator`，包含生成页面的软件的标识符。

* `keywords`，包含与逗号分隔的页面内容相关的单词。

* `robots`，robots用来告诉爬虫哪些页面需要索引，哪些页面不需要索引。content的参数有all,none,index,noindex,follow,nofollow。默认是all。

  举例：
  ```html
  <meta name="robots" content="none">
  ```

* `revisit-after`，如果页面不是经常更新，为了减轻搜索引擎爬虫对服务器带来的压力，可以设置一个爬虫的重访时间。如果重访时间过短，爬虫将按它们定义的默认时间来访问。

  举例：
  ```html
  <meta name="revisit-after" content="7 days" >
  ```

### 3.3.2 浏览器行为相关

* `viewport`，设置浏览器视口

  详情查看：[从移动端适配探讨响应式布局与 view-port](https://blog.esunr.xyz/2019/11/%E4%BB%8E%E7%A7%BB%E5%8A%A8%E7%AB%AF%E9%80%82%E9%85%8D%E8%B0%88%E8%B0%88%E5%93%8D%E5%BA%94%E5%BC%8F%E5%B8%83%E5%B1%80%E4%B8%8Eview-port/)

* uc强制竖屏
  
  ```html
  <meta name="screen-orientation" content="portrait">
  ```

* QQ强制竖屏
  
  ```html
  <meta name="x5-orientation" content="portrait">
  ```

* UC应用模式 

  ```html
  <meta name="browsermode" content="application">
  ```

* QQ应用模式 

  ```html
  <meta name="x5-page-mode" content="app">
  ```

* IOS启用 WebApp 全屏模式

  ```html
  <meta name="apple-mobile-web-app-capable" content="yes" />
  ```

* IOS全屏模式下隐藏状态栏/设置状态栏颜色 content的值为default | black | black-translucent

  ```html
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
  ```

* IOS添加到主屏后的标题 

  ```html
  <meta name="apple-mobile-web-app-title" content="标题">
  ```

* IOS添加智能 App 广告条 Smart App Banner

  ```html
  <meta name="apple-itunes-app" content="app-id=myAppStoreID, affiliate-data=myAffiliateData, app-argument=myURL">
  ```

* 去除 iPhone 识别数字为号码

  ```html
  <meta name="format-detection" content="telephone=no">
  ```

* 不识别邮箱

  ```html
  <meta name="format-detection" content="email=no">
  ```

* 禁止跳转至地图

  ```html
  <meta name="format-detection" content="adress=no">
  ```

* 可以连写

  ```html
  <meta name="format-detection" content="telephone=no,email=no,adress=no">
  ```