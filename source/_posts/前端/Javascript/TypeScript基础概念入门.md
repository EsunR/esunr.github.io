---
title: TypeScript基础概念入门
tags:
  - 快速指南
  - Typescript
categories:
  - 前端
  - Javascript
date: 2020-05-25 19:15:10
---

# 1. Array 和 Tuple

定义数组：

```ts
let arrOfNumbers: number[] = [1, 2, 3, 4]
arrOfNumbers.push("1") // error
```

Tuple（元组）类似于数组，但是不同于普通 js 数组，元组可以定义每个位置的数据类型。

创建元组：

```ts
let user: [string, number] = ['viking', 12]

let user: [string, number] = ['viking'] // error
let user: [string, number] = [12, 'viking'] // error
```

# 2. Interface 接口

- 对对象的 shape 进行描述
- 对类进行抽象
- Duck Typing

接口的定义：

```ts
interface Person {
  readonly id: number; // 定义只读属性
  name: string;
  sex: string;
  age?: number; // 定义可选参数
}
```

接口的使用：

```ts
let xiaoming: Person = {
  id: 1,
  name: "EsunR",
  sex: "man",
};
xiaoming.age = 19;
xiaoming.id = 2 // error
```

接口不仅可以用来定义对象，还可以用来定义函数：

```ts
interface IAdd {
  (a: number, b: number): number;
}

function add(a: number, b: number): number {
  return a + b;
}

const a: IAdd = add;
```

# 3. Function 函数

创建函数：

```ts
function add(x: number, y: number, z?: number): number {
  if (typeof z === "number") {
    return x + y + z;
  } else {
    return x + y;
  }
}

add(2, 3);    // 5
add(2, 3, 4); // 9
```

我们还可以对变量定义函数类型，如定义变量 `add2` 为一个传入值为 3 个 number 类型的变量，且返回为 number 类型的函数，那么 `add` 函数就可以赋值给这个变量：

```ts
let add2: (x: number, y: number, z?: number) => number;
add2 = add; // success

let add2: (a: number, b: number, c: number) => number;
add2 = add; // success

let add2: (a: number, b: number) => number;
add2 = add; // success

let add2: (a: number, b: string) => number;
add2 = add; // error
```

# 3. Class 类

类的基本使用与 ES6 相似，在此不再复述，主要区别在于 TS 中支持了类的修饰符：

- public 
- private
- protected 

public 属性可以让外部实例直接获取到，默认的属性都为 public；而 private 属性只有在类的内部的方法中可以调用，而外部不可调用，也不可继承：

```ts
class Animal {
  public name: string;
  private age: number;
  constructor(name: string, age: number) {
    this.name = name;
    this.age = age;
  }
  walk() {
    console.log("walk");
  }
}

let huahua = new Animal("花花", 2);
console.log(huahua.name);
console.log(huahua.age); // error: 属性“age”为私有属性，只能在类“People”中访问。

class Dog extends Animal {
  constructor(name: string, age: number) {
    super(name, age);
    this.name = name;
    this.age = age; // error: 属性“age”为私有属性，只能在类“People”中访问。
  }
}
```

如果要想让该属性也可被子类继承，那么可以使用 protected 来对变量进行修饰：

```diff
  class A`nimal {
    public name: string;
-   private age: number;
+   protected age: number;
    constructor(name: string, age: number) {
      ... ...
    }
    ... ...
  }

  class Dog extends Animal {
    constructor(name: string, age: number) {
      super(name, age);
      this.name = name;
      this.age = age;
    }
  }`
```

静态方法与属性：

```ts
class Animal {
  static includes = ["dog", "cat", "bird"];
  constructor() {
    // ... ...
  }
  static isAnimal(a) {
    return a instanceof Animal;
  }
}
```

# 4. interface 接口

定义与实现接口：

```ts
// ==== 定义接口 ====
interface Radio {
  switchRadio(): void;
}

interface Battery {
  checkBVatteryStatus(): void;
}

interface RadioWithBattery extends Radio { // 接口的继承
  checkBVatteryStatus(): void;
}

// ==== 在类中实现接口 ====
class Car implements Radio {
  switchRadio() {}
}

class Phone implements Radio, Battery { // 实现多个接口
  switchRadio() {}
  checkBVatteryStatus() {}
}

class CellPhone implements RadioWithBattery {
  switchRadio() {}
  checkBVatteryStatus() {}
}
```

# 5. enum 枚举

定义与使用枚举类：

```ts
enum Direction {
  Up,
  Down,
  Left,
  Right,
}
console.log(Direction.Up); // 0
console.log(Direction[0]); // "Up"
```

之所以枚举类可以被双向引用，是因为上面的代码被编译为：

```js
var Direction;
(function (Direction) {
    Direction[Direction["Up"] = 0] = "Up";
    Direction[Direction["Down"] = 1] = "Down";
    Direction[Direction["Left"] = 2] = "Left";
    Direction[Direction["Right"] = 3] = "Right";
})(Direction || (Direction = {}));
```

默认结构为：

```js
{
  '0': 'Up',
  '1': 'Down',
  '2': 'Left',
  '3': 'Right',
  Up: 0,
  Down: 1,
  Left: 2,
  Right: 3
}
```

除此之外，枚举类还可以设置默认值：

```ts
enum Direction {
  Up = "UP",
  Down = "DOWN",
  Left = "LEFT",
  Right = "RIGHT",
}
console.log(Direction.Up); // "UP"
console.log(Direction["Up"]); // "UP"
console.log(Direction[0]); // undefined

// 应用于数据校验上
let result = "UP";
if (result !== Direction.Up) {
  console.log("result error");
}
```

# 6. 泛型

泛型可以看作是一个占位符，在使用的时候动态填入确定的类型值。

## 6.1 泛型的简单示例

如果我们定义一个方法，这个方法传入任意类型且返回同样的类型，这样我们可能会将方法定义为：

```ts
function echo(arg: any): any {
  return arg;
}
let str = echo("wulalala");
let num: number = echo("123");
console.log(typeof num); // string  Bug:不符合预期的变量类型
```

但是这样的话就缺少了类型校验，str 会被标为 any 类型，甚至还会出现 BUG。

为了避免这一情况，我们可以定义一个**类型相同，但不对类型进行约束**的变量类型 T ，我们将 T 称之为**泛型**：

```ts
function echo<T>(arg: T): T {
  return arg
}
let str = echo("wulalala");
let num: number = echo("123"); // error: 不能将类型 "123" 分配给类型 "number" (Bug fixed)
```

此外，泛型还可以用于元组中：

```ts
function swap<T, U>(tuple: [T, U]): [U, T] {
  return [tuple[1], tuple[0]];
}
const result = swap(["string", 123]);
console.log(result); // 123, "string"
```

## 6.2 泛型约束

假设现在我们有一个需求：传入一个具有 length 属性的对象，要求输出该对象的 length，同时返回与该对象同一类型的对象。

但是如果我们使用泛型的话，输出 length 时就会显示没有该属性：

```ts
function printLength<T>(input: T): T {
  console.log(input.length); // error: 类型“T”上不存在属性“length”。
  return input;
}
```

因此，我们可以使用泛型约束，来约束泛型 T 为一个数组类型：

```diff
- function printLength<T>(input: T): T {
+ function printLength<T>(input: T[]): T[] {
    console.log(input.length);
    return input;
  }
```

但是这样的话就失去了泛型原有的作用，用户只能在该方法中传入数组。string 类型同样有 length 属性，但是将 string 传入该方法中的话就会报错。因此更好的做法是去定义一个接口类型，接口类型中拥有 length 属性，string 和 array 都符合接口的规范，我们可以让定义的泛型继承自该接口，那么我们的需求就达到了：

```ts
interface IinputWithLength {
  length: number;
}

function printLength<T extends IinputWithLength>(input: T): T {
  console.log(input.length);
  return input;
}

printLength([1, 2, 3]);
printLength("123");
printLength({ length: 10 });
printLength(123); // error: 类型“123”的参数不能赋给类型“IinputWithLength”的参数
```

## 6.3 类和接口的泛型

在前面我们再方法中使用了泛型，那么同样的我们可以在类中也使用泛型：

```ts
class Queue<T> {
  private data = [];
  push(item: T) {
    return this.data.push(item);
  }
  pop(): T {
    return this.data.pop();
  }
}

let queue = new Queue<number>(); // 在创建实例的时候要声明泛型的类型
queue.push(1.23);
console.log(queue.pop().toFixed(1));

queue.push("1.23"); // error: 类型“"1.23"”的参数不能赋给类型“number”的参数。
console.log(queue.pop().toFixed(1));
```

同样的接口也可以使用泛型：

```ts
// 用泛型定义接口对象
interface KeyPair<T, U> {
  key: T;
  value: U;
}
let kp1: KeyPair<number, string> = {
  key: 1,
  value: "123",
};

// 用泛型定义接口函数
interface IAdd<T> {
  (a: T, b: T): T;
}
function add(a: number, b: number): number {
  return a + b;
}
const a: IAdd<number> = add;
```

数组也可以使用泛型来定义：

```ts
let arr1: number[] = [1, 2, 3];
let arr2: Array<number | string> = [1, 2, 3, "2"];
```

# 7. 类型别名与断言

## 7.1 类型别名 Type Aliases

类型别名就是将联合类型或者是比较复杂的函数类型设置一个别名，可以提供给其他变量进行使用，对类型进行约束:

```ts
type PluseType = (x: number, y: number) => number;
function sum(a: number, b: number): number {
  return a + b;
}
const fn: PluseType = sum;
```

联合类型比较常用类型别名：

```ts
type NameResolver = () => string;
type NameOrResolver = string | NameResolver;
function getName(arg: NameOrResolver): string {
  if (typeof arg === "string") {
    return arg;
  } else {
    return arg();
  }
}

console.log(getName("huahua")); // huahua
console.log(
  getName(function () {
    return "huahua2";
  })
); // huahua2
```

## 7.2 类型断言 Type Assertion

可以使用 `as` 关键字对变量类型进行断言，我们可以将断言后的结果赋值到任意变量上，那么通过这个变量就可以使用我们断言的类型上所拥有的方法：

```ts
function getLength(input: string | number): number {
  const str = input as string;
  if (str.length) {
    return str.length;
  } else {
    const number = input as number;
    return number.toString().length;
  }
}
```

此外，我们可以使用 `<>` 来更简洁的对变量进行断言并直接使用：

```ts
if ((<string>input).length) {
  return (<string>input).length;
} else {
  return (<number>input).toString().length;
}
```

> 两种方式都可以使用 `()` 包裹住后直接调用类型上的方法，或者将其赋值到一个变量上，通过变量调用类型上的方法。

#　8. 声明文件

假如我们要在项目中使用 jQuery 文件，那么可能会出现如下报错信息：

```ts
jQuery("#id"); // error: 找不到名称“jQuery”。
```

此时我们需要 jQuery 的声明文件来帮助我们声明这个方法。我们可以使用关键字 `declear` 来声明一种方法，让项目可以借助 ts 的能力来对原来使用 js 构建的库文件使用类型断言：

```ts
declare var jQuery: (selector: string) => any;
jQuery("#id");
```

通常我们可以使用 `d.ts` 文件作为专用的声明文件，这一文件将会被 ts 构建的时候被编译。