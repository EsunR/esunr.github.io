---
title: 关于ES6中import、export语句的种种引入方式、导出方式的区别
tags: [ES6]
categories: [Front, ES6]
date: 2019-07-02 21:41:42
---
学习了这么长时间的Vue、React、还有nodeJs，对 `import` 语句可以说是既熟练又容易糊涂，我们经常见到以下几种 `import` 语句：

- import {xx1, xx2, xx2} from 'xx'
- improt * as xx from 'xx'
- import xx from 'xx'

那么接下来我们就好好分析一下他们的区别以及使用场景：

## 1. import {xx1, xx2, xx2} from 'xx'

该语句是引入外部模块中的某个接口，外部模块向外暴露出某个接口后，在主模块中可以引用该模块文件及其接口名称，即可调用该接口。需要注意的是，其接口名称是一一对应的关系。

### 导出

导出模块的方法基本上分为两种，一种是使用 `export` 语法分别导出对应的模块接口，如：

```javascript
// profile.js
export var firstName = 'Michael';
export var lastName = 'Jackson';
export var year = 1958;
```

还有一种就是将以接口的形式聚合导出，如：

```javascript
// profile.js
var firstName = 'Michael';
var lastName = 'Jackson';
var year = 1958;

export { firstName, lastName, year };
```

同时我们还可以使用 `as` 语法来对接口名称进行重命名，如：

```javascript
// profile.js
var firstName = 'Michael';
var lastName = 'Jackson';
var year = 1958;

export { 
	firstName as name1, 
	lastName as name2, 
	year,
	year as bornYaer
};
```

### 引入

引入模块接口需要按照接口名称一一对应引入：

```javascript
// main.js
import { firstName, lastName, year } from './profile.js';

function setName(element) {
  element.textContent = firstName + ' ' + lastName;
}
```

也可以使用 `as` 语法去对模块接口进行重命名：

```javascript
// main.js
import { firstName as name1, lastName as name2, year } from './profile.js';

function setName(element) {
  element.textContent = name1 + ' ' + name2;
}
```

## 2. improt * as xx from 'xx'

这种加载方式我们称之为模块的整体加载，是用这种方式加载模块，所有的接口都会被加载并且存放到以 `as` 命名的对象中。

### 导出

```javascript
// circle.js

export function area(radius) {
  return Math.PI * radius * radius;
}

export function circumference(radius) {
  return 2 * Math.PI * radius;
}
```

### 引入

```javascript
// main.js

import * as circle from './circle';

console.log('圆面积：' + circle.area(4));
console.log('圆周长：' + circle.circumference(14));
```

> 注意，模块整体加载所在的那个对象（上例是circle），应该是可以静态分析的，所以不允许运行时改变。下面的写法都是不允许的。

## 3. import xx from 'xx'

这种语法实际上是最常见的，从前面的例子可以看出，使用import命令的时候，用户需要知道所要加载的变量名或函数名，否则无法加载。但是，用户肯定希望快速上手，未必愿意阅读文档，去了解模块有哪些属性和方法。用这种方法可以加载模块文件默认导出的接口，并且按照用户自定义的变量名称去加载该默认接口。

> 本质上，`export default`就是输出一个叫做`default`的变量或方法，然后系统允许你为它取任意名字。所以，下面的写法是有效的。

### 导出

默认接口使用 `export default` 语句导出，其可以是一个命名函数方法也可以是一个匿名函数方法。同时使用了 `export default` 语句导出默认接口的情况下，仍旧可以使用 `export` 语句导出命名接口：

```javascript
// export-default.js
export default function () {
  console.log('foo');
}
```

### 引入

在主文件中引用该模块可以直接使用 `import` 语句定义用户自定义变量来引入使用该接口:

```javascript
// import-default.js
import customName from './export-default';
customName(); // 'foo'
```

## 4. 注意

我们在编写模块导出模块接口时，使用 `export` 语句导出的变量、方法必须定义在语句之后，不能直接导出匿名函数、数值、字符串，如下面定义的导出都是非法的：

```javascript
// 报错
export 1;

// 报错
var m = 1;
export m;
```

> 上面两种写法都会报错，因为没有提供对外的接口。第一种写法直接输出 1，第二种写法通过变量m，还是直接输出 1。1只是一个值，不是接口。正确的写法是下面这样。

正确的写法为：

```javascript
// 写法一
export var m = 1;

// 写法二
var m = 1;
export {m};

// 写法三
var n = 1;
export {n as m};
```

但是当我们使用 `export default` 语句时，如果在语句中声明变量，就会产生报错，这点与 `export` 语句截然相反，其原因是因为 `export default` 语句实质上相当于导出了一个 `defalut` 变量，如果我们再语句中再声明一个变量自然就会报错。

```javascript
// 正确
export var a = 1;

// 正确
var a = 1;
export default a;

// 错误
export default var a = 1;

// 正确
export default 42;

// 报错
export 42;
```
