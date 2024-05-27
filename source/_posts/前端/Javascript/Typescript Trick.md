---
title: Typescript Trick
tags:
  - '#Typescript'
categories:
  - 前端
  - Javascript
date: 2024-05-21 15:19:47
---
# 自定义类型保护函数

当一个类型是联合类型时，对其进行类型判断将变得困难，如：

```ts
interface Foo {
    foo: number;
    common: string;
}

interface Bar {
    bar: number;
    common: string;
}

type SomeType = Foo | Bar;

function doSomething(arg: SomeType) {
    if (arg.foo) { // 类型“Foo | Bar”上不存在属性“foo”。
        console.log(arg.foo); // 类型“Foo | Bar”上不存在属性“foo”。
    } else {
        console.log(arg.bar); // 类型“Foo | Bar”上不存在属性“bar”。
    }
}
```

因此我们可以使用自定义类型保护函数，利用一个函数进行运行时检查，并告知 TS 该类型是一个确定的类型：

```ts
function isFoo(arg: SomeType): arg is Foo {
    return (arg as Foo).foo !== undefined;
}

function doSomething(arg: SomeType) {
    if (isFoo(arg)) {
        console.log(arg.foo);
    } else {
        console.log(arg.bar);
    }
}
```