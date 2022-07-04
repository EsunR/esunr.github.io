---
title: 一段代码两张图，帮你理解JS中的原型链继承
tags:
  - JS
  - 面试题
categories:
  - 前端
  - Javascript
date: 2019-10-29 22:25:57
---
创建一个 Animal 类，Dog 类继承与 Animal 类，同时实例化一个 Dog 类为 dog，查看其显式原型与隐式原型之间的关系：

```js
class Animal {
  constructor(name) {
    this.name = name
  }
  eat() {
    console.log("吃东西");
  }
}

class Dog extends Animal {
  constructor(name) {
    super(name)
  }
  brak() {
    console.log("wang!");
  }
}

var dog = new Dog("huahua")
dog.eat() // 吃东西
dog.brak() // wang!


console.log(dog.__proto__); // Dog {}
console.log(Dog); // [Function: Dog]
console.log(Dog.prototype); // Dog {}
console.log(Dog.prototype.__proto__); // Animal {}
console.log(Dog.__proto__); // [Function: Animal]
console.log(Dog.__proto__.prototype); // Animal {}
console.log(Dog.__proto__.__proto__); // [Function]
console.log(Animal.prototype.__proto__); // {}
```

将以上的显式原型（prototype）与隐式原型（\_\_proto\_\_）转换为如下的可视关系：

![](http://img.cdn.esunr.xyz/markdown/20191224133325.png)

网上流行的一张图：

![](http://markdown.img.esunr.xyz/20191109222853.png)