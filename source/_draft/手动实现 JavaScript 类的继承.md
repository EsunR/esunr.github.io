---
title: 手动实现 JavaScript 类的继承
date: 2024-01-14 20:21:41
tags:
  - 面试题
  - JavaScript
  - 面向对象
---
# 原型链继承

这个实现方式是将子类的 prototype 直接指向一个实例化好的父类，这样当实例化后的子类查找属性或方法时，就能通过这个实例化好的父类拿到父类构造函数（在 prototype 上的）的属性或方法。

实现：

```js
function Animal(name) {
  this.name = name || "unknown";
}
Animal.prototype.eat = function () {
  console.log("ku ku");
};

function Cat(age) {
  this.age = age || NaN;
}
// 原型链继承
Cat.prototype = new Animal();
Cat.prototype.bark = function () {
  console.log("mew~");
};

const cat = new Cat('2 month');
// 调用父级构造函数中的方法
cat.eat();
cat.bark();
// 输出属性
console.log({
  name: cat.name,
  age: cat.age,
}); // { name: 'unknown', age: '2 month' }

console.log("=================");

console.log(cat instanceof Animal); // true
console.log(cat.constructor); // [Function: Animal]
console.log(cat.__proto__.__proto__ === Animal.prototype); // true
console.log(Cat.__proto__ === Animal); // false
```

当生成的 cat 实例尝试调用 eat 方法时，会首先查找自身有没有该属性，如果没有，沿原型链进行查找到 Cat 构造函数上的 prototype 属性上。由于我们实例化了一个 Animal 的实例挂载到了 Cat 的 prototype 上，因此当 cat 查找 Cat 构造函数上的 prototype 时，可以拿到 Animal 实例上的所有属性和方法，也就是说可以获取到 Animal.prototype，这样也就完成了继承。

优点：

- 实现方便
- instanceof 方法可以判断继承
	- `cat.__proto__.__proto__ === Animal.prototype` 为 `true`
	- `Cat.__proto__ === Animal` 为 `false`（与 ES6 继承不统一）

缺点：

- 所有子类都共享同一个父类的实例
- 当父类构造函数有参数时，实例化之类时不能向父类传参，也就是 `super` 操作无法实现
- 无法实现多继承
- prototype 被覆写，很多属性的指向将会是错误的，如 `constructor`

# 构造函数继承

这种继承方式强行将父类构造函数中的所有属性都绑定给实例化后的子类实例，从而让子类继承了父类的属性。

实现：

```js
function Animal(name) {
  this.name = name || "unknown";
  this.eat = function () {
    console.log("ku ku");
  };
}

function Cat(name, age) {
  this.age = age || NaN;
  Animal.call(this, name);
}
Cat.prototype.bark = function () {
  console.log("mew~");
};

const cat = new Cat("YiDianDian","2 month");
// 调用父级构造函数中的方法
cat.eat();
cat.bark();
// 输出属性
console.log({
  name: cat.name,
  age: cat.age,
}); // { name: 'YiDianDian', age: '2 month' }

console.log("=================");

console.log(cat instanceof Animal); // false
console.log(cat.constructor); // [Function: Cat]
console.log(cat.__proto__.__proto__ === Animal.prototype); // false
console.log(Cat.__proto__ === Animal); // false
```

优点：

- 避免了所有子类上的属性被共享
- 实例化子类时可以向父类的构造函数传参

缺点：

- 没有考虑原型链，隐式原型的指向是错的，所以 instanceof 不生效
- 父类的方法如果想要被继承，都必须挂载在 `this` 上，通过 `prototype` 挂载的是无法被实例化后的子类访问的，且父类所有的方法都在构造函数中声明的话每次实例化都会被重新创建，无法复用

# 组合继承

```js
function Animal(name) {
  this.name = name || "unknown";
}
Animal.prototype.eat = function () {
  console.log("ku ku");
};

function Cat(name, age) {
  this.age = age || NaN;
  Animal.call(this, name);
}
Cat.prototype = new Animal();
Cat.prototype.bark = function () {
  console.log("mew~");
};

const cat = new Cat("YiDianDian", "2 month");
cat.eat();
cat.bark();
console.log({
  name: cat.name,
  age: cat.age,
}); // { name: 'YiDianDian', age: '2 month' }

console.log("=================");

console.log(cat instanceof Animal); // true
console.log(cat.constructor); // [Function: Animal]
console.log(cat.__proto__.__proto__ === Animal.prototype); // true
console.log(Cat.__proto__ === Animal); // false
```

优点：

- 可以继承实例属性、方法，也可以继承原型属性、方法
- 可传参、可复用
- 实例既是子类的实例，也是父类的实例


缺点：

- 调用了两次父类构造函数，耗内存
- 需要修复构造函数指向

# 原型式继承

直接将新的实例的隐式原型指向超类，就能通过原型链拿到超类的方法和属性。

实现：

```js
const animal = {
  name: "unknown",
  eat() {
    console.log("ku ku");
  },
};

const cat = {};
cat.__proto__ = animal;

cat.age = "2 month";
cat.bark = function () {
  console.log("mew~");
};

cat.eat();
cat.bark();
console.log({
  name: cat.name,
  age: cat.age,
}); // { name: 'unknown', age: '2 month' }

console.log("=================");

// console.log(cat instanceof Animal);
console.log(cat.constructor); // [Function: Object]
// console.log(cat.__proto__.__proto__ === Animal.prototype);
// console.log(Cat.__proto__ === Animal);
```

优化：

```js
function object(proto) {
  const Fn = function () {};
  Fn.prototype = proto;
  return new Fn();
}

const animal = {
  name: "unknown",
  eat() {
    console.log("ku ku");
  },
};

const cat = object(animal);
cat.age = "2 month";
cat.bark = function () {
  console.log("mew~");
};
```

优化：

```js
const animal = {
  name: "unknown",
  eat() {
    console.log("ku ku");
  },
};

const cat = Object.create(animal);

cat.age = "2 month";
cat.bark = function () {
  console.log("mew~");
};
```

# 寄生式继承

只是将原型式继承创建了一个工厂函数。

```js
const animal = {
  name: "unknown",
  eat() {
    console.log("ku ku");
  },
};

function createCat(age) {
  const newInstance = Object.create(animal);
  newInstance.age = age;
  newInstance.bark = function () {
    console.log("mew");
  };
  return newInstance;
}

const cat = createCat("2 month");

cat.eat();
cat.bark();
console.log({
  name: cat.name,
  age: cat.age,
}); // { name: 'unknown', age: '2 month' }
```

# 寄生组合式继承

组合式继承其实已经是一个比较完善的类继承方案了，但是缺点是会实例化两次 super 类。为了解决这个问题，我们可以使用寄生式组合的方法去连接子类与 Super 类之间的原型链，从而优化掉组合式继承中为了连接原型链而进行的第二次实例化。

实现：

```js
/**
 * subInstance.__proto__ -> SubClass.prototype
 * SubClass.prototype.__proto__ -> SuperClass.prototype
 */
function inherit(SubClass, SuperClass) {
  const parent = Object.create(SuperClass.prototype);
  SubClass.prototype = parent;
  // 修正 constructor
  SubClass.prototype.constructor = SubClass;
}

function Animal(name) {
  this.name = name || "unknown";
}
Animal.prototype.eat = function () {
  console.log("ku ku");
};

function Cat(name, age) {
  Animal.call(this, name);
  this.age = age || NaN;
}
inherit(Cat, Animal);
Cat.prototype.bark = function () {
  console.log("mew~");
};

const cat = new Cat("YiDianDian", "2 month");
cat.eat();
cat.bark();
console.log({
  name: cat.name,
  age: cat.age,
}); // { name: 'YiDianDian', age: '2 month' }

console.log("=================");

console.log(cat instanceof Animal); // true
console.log(cat.constructor); // [Function: Cat]
console.log(cat.__proto__.__proto__ === Animal.prototype); // true
console.log(Cat.__proto__ === Animal); // false
```

# 增强寄生组合式继承

组合式继承已经快到头了，但是我们发现调用 `inherit` 方法必须在向子类挂载 `prototype` 属性或方法之前，否则，子类的原型上挂载的属性或方法就会被覆盖：

```js
function Cat(name, age) {
  Animal.call(this, name);
  this.age = age || NaN;
}
Cat.prototype.bark = function () {
  console.log("mew~");
};
inherit(Cat, Animal);

const cat = new Cat("YiDianDian", "2 month");
cat.eat(); // throw error: eat is not a function
```

为了解决这个问题，我们可以使用 `Object.defineProperty` 在 `inherit` 方法中覆盖子类的 `prototype` 前将子类已有的原型链上的属性挂载给创建的空对象上：

```diff
function inherit(SubClass, SuperClass) {
  const parent = Object.create(SuperClass.prototype);
+ for (let key in SubClass.prototype) {
+   Object.defineProperty(parent, key, {
+     value: SubClass.prototype[key],
+   });
+ }
  SubClass.prototype = parent;
  // 修正 constructor
  SubClass.prototype.constructor = SubClass;
}
```

完整的实现如下：

```js
/**
 * subInstance.__proto__ -> SubClass.prototype
 * SubClass.prototype.__proto__ -> SuperClass.prototype
 */
function inherit(SubClass, SuperClass) {
  const parent = Object.create(SuperClass.prototype);
  for (let key in SubClass.prototype) {
    Object.defineProperty(parent, key, {
      value: SubClass.prototype[key],
    });
  }
  SubClass.prototype = parent;
  // 修正 constructor
  SubClass.prototype.constructor = SubClass;
}

function Animal(name) {
  this.name = name || "unknown";
}
Animal.prototype.eat = function () {
  console.log("ku ku");
};

function Cat(name, age) {
  Animal.call(this, name);
  this.age = age || NaN;
}
Cat.prototype.bark = function () {
  console.log("mew~");
};

inherit(Cat, Animal);

const cat = new Cat("YiDianDian", "2 month");
cat.eat();
cat.bark();
console.log({
  name: cat.name,
  age: cat.age,
}); // { name: 'YiDianDian', age: '2 month' }

console.log("=================");

console.log(cat instanceof Animal); // true
console.log(cat.constructor); // [Function: Cat]
console.log(cat.__proto__.__proto__ === Animal.prototype); // true
console.log(Cat.__proto__ === Animal); // false
```