---
title: TypeScript 类型体操通关记录
tags:
  - Typescript
categories:
  - 前端
  - Javascript
date: 2024-02-19 15:42:06
---
# 1. 简单

## Pick

[Source](https://github.com/type-challenges/type-challenges/blob/main/questions/00004-easy-pick/README.zh-CN.md)

`Pick` 是 TypeScript 中的一个内置工具类型，可以从某个类型中提取出来几个特定的属性 Key 来创建一个新的类型：

```ts
interface Todo {
  title: string;
  description: string;
  completed: boolean;
}
 
type TodoPreview = Pick<Todo, "title" | "completed">;
 
const todo: TodoPreview = {
  title: "Clean room",
  completed: false,
};
```

答案：

```ts
type MyPick<T, K extends keyof T> = {
  [key in K]: T[key]
}
```

解析 ：

`keyof T` 可以将目标类型的 Key 全部提取出来，以上面的示例为例，`keyof T` 的结果就是 `"title" | "description" | "completed"`；

`extends` 是 TypeScript 中的一个 **操作类型**，可以用作条件[类型判断](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html)，意思表述为 `extends` 左侧的类型可以赋给右侧的类型，如 `number extends (number | string) ? number : string // number`。在上述示例中，`K extends keyof T` 就表示为 `K` 是 `"title" | "description" | "completed"` 其中的一个值；

`in` 关键词可以帮助我们在定义对象的 key 值时从联合类型中进行取值，如我们想创建一个 Object 的类型声明，该对象的值不限定类型，然而 key 值我们期望限定范围在 `'a' | 'b' | 'c'`，那么我们就可以声明该对象的类型为 `type Obj = { [key in 'a' | 'b' | 'c']: string }`（如果 key 值也不限定类型，可以直接声明为 `{ [key: string]: any }` 等同于 `Record<string, any>`）;

因此，使用 `K extends keyof T` 可以限定泛型的第二个参数位必须传入目标对象的 key，使用 `[key in K]: T[key]` 来定义一个新的类型声明对象的 Key 和 Value 的类型定义，从而实现 `Pick` 函数。

## Exclude

[Source](https://github.com/type-challenges/type-challenges/blob/main/questions/00043-easy-exclude/README.zh-CN.md)

`Exclude` 是   TypeScript 中的一个内置工具类型，可以排除掉某个联合类型中的某些联合成员，例如 `Exclude<"a" | "b" | "c", "c" | "d">` 将得到新的联合类型 `"a" | "b"`。

 答案：

```ts
type MyExclude<T, K> = T extends K ? never : T;
```

解析：

这里利用到了 TypeScript 的 `extends` 关键字，并且利用到了其[自动分配条件的特性](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html#distributive-conditional-types)。简单来说，对于 `T extends U ? X : Y` 来说，当 `T` 为一个 `A | B` 的联合类型，那实际情况就变成 `(A extends U ? X : Y) | (B extends U ? X : Y)`。

且这一特性仅在左侧为泛型时才会触发，当使用 `"a" | "b" | "c" extends "a" ? "e" : "f"`  时得到的结果为 `"f"` 并非 `"e" | "f"`，因为 `"a" | "b" | "c"` 并不能分配给 `"a"`。如果在使用泛型时候不想触发自动分配条件的特性，可以使用 `[]` 将关键词左侧和右侧包裹起来，如 `[T] extends [K]`。

## 实现对象属性只读

[Source](https://github.com/type-challenges/type-challenges/blob/main/questions/00007-easy-readonly/README.zh-CN.md)

Readonly 是 TypeScript 中的一个内置工具类型，可以将对象类型的所有属性都设置为只读，这意味着构造类型的属性不能重新分配，如：

```ts
interface Todo {
  title: string;
}
 
const todo: Readonly<Todo> = {
  title: "Delete inactive users",
};
 
todo.title = "Hello"; // Cannot assign to 'title' because it is a read-only property.
```

答案：

```ts
type MyReadonly<T> = {
  readonly [K in keyof T]: T[K]
}
```

解析：

TypeScript 在定义类型时，可以使用 [`readonly` 修饰符](https://www.typescriptlang.org/docs/handbook/typescript-in-5-minutes-func.html#readonly-and-const) 将对象属性定义为只读属性，这里就可以通过重新声明对象类型的 key 类型来将其所有 key 都定义为只读类型。

[相同类型题目：对象部分属性只读](https://github.com/type-challenges/type-challenges/blob/main/questions/00008-medium-readonly-2/README.zh-CN.md)

答案：

```ts
// 方案一：
type MyExclude<T, K> = T extends K ? never : T;

type MyReadonly<T, K extends keyof T = keyof T> = {
  readonly [k in K]: T[k];
} & { [k in MyExclude<keyof T, K>]: T[k] };

// 方案二：
type MyReadonly2<T, K extends keyof T = keyof T> = Omit<T, K> &
  Readonly<Pick<T, K>>;
```

[相同类型题目：对象属性只读（递归）](https://github.com/type-challenges/type-challenges/blob/main/questions/00009-medium-deep-readonly/README.zh-CN.md)

答案：

```ts
type DeepReadonly<T> = keyof T extends never
  ? T
  : { readonly [k in keyof T]: DeepReadonly<T[k]> };
```

## 元组转换为对象

将一个元组类型转换为对象类型，这个对象类型的键/值和元组中的元素对应。

例如：

```ts
const tuple = ['tesla', 'model 3', 'model X', 'model Y'] as const

type result = TupleToObject<typeof tuple> // expected { 'tesla': 'tesla', 'model 3': 'model 3', 'model X': 'model X', 'model Y': 'model Y'}
```

答案：

```ts
type TupleToObject<T extends readonly any[]> = {
  [K in T[number]]: K
}
```

解析：

我们要求传入的泛型 `T` 必须是数组，因此要求继承为 `any[]`，同时在题目示例中，我们使用 `typeof tuple` 来获取元组的类型，这样获取到的是一个 readonly 属性的元组，因此 T 必须继承 `readonly any[]`。

当 `T` 为元组时，可以使用 `T[number]` 将元组转化为一个联合类型，如 `["a", "b", "c"][number]` 即为 `"a" | "b" | "c"`。`[K in T[number]]: K` 可以将元组转化为 `Key: Value` 对应的形式。

## 第一个元素

实现一个`First<T>`泛型，它接受一个数组`T`并返回它的第一个元素的类型。

例如：

```ts
type arr1 = ['a', 'b', 'c']
type arr2 = [3, 2, 1]

type head1 = First<arr1> // 应推导出 'a'
type head2 = First<arr2> // 应推导出 3
```

答案：

```ts
//answer1
type First<T extends any[]> = T extends [] ? never : T[0]

//answer2
type First<T extends any[]> = T['length'] extends 0 ? never : T[0]

//answer3
type First<T extends any[]> = T extends [infer A, ...infer Rest] ? A : never
```

解析：

这道题看似很简单，只需要 `T[0]` 就可以获取到元组的第一个成员并返回，但是需要考虑用例为一个空元组的情况，比如 `First<[]>` 需要返回 `never`，而 `T[0]` 将返回 `undefined`。因此我们需要特殊处理该情况。

在第一种解法中，`T extends []` 相当于显式判断了 `T` 是否是一个空元组，如果是的话则直接返回 `never`。

第二种解法则是使用元组的 `length` 属性来判断元组是否为空，如果为空则返回 `never`。

第三种解法利用了关键词 `infer`，`infer` 可以用作类型推断，具体介绍可以查看[这里](https://jkchao.github.io/typescript-book-chinese/tips/infer.html#%E4%BB%8B%E7%BB%8D)。`T extends [infer A, ...infer Rest]` 表示如果 `T` 如果可以赋给 `[infer A, ...infer Rest]` 那么元组的第一个成员为泛型 `A`，其余成员使用展开符赋给泛型 `Reset`，如 `T` 为 `["a", "b", "c"]`，则 `A` 为 `"a"`，`Reset` 为 `["b", "c"]`。如果 `extends` 条件成立则返回 `A`，也就是元组中第一个元素的类型，如果不成立则说明 `infer` 无法推断，也就是说元组类型 `T` 的长度不足，因此返回 `never`。

## 获取元组长度

创建一个`Length`泛型，这个泛型接受一个只读的元组，返回这个元组的长度。

例如：

```ts
const tesla = ['tesla', 'model 3', 'model X', 'model Y'] as const
const spaceX = ['FALCON 9', 'FALCON HEAVY', 'DRAGON', 'STARSHIP', 'HUMAN SPACEFLIGHT'] as const

type teslaLength = Length<typeof tesla> // expected 4
type spaceXLength = Length<typeof spaceX> // expected 5
```

答案：

```ts
// answer 1
type Length<T extends readonly any[]> = T['length'];

// answer 2
type Length<T extends readonly any[]> = T extends { length: infer L }  ?  L : never;
```

解析：

用例中使用 `typeof` 来获取一个 const 常量的类型，因此泛型 `T` 要继承 `readonly` 只读类型的数组，否则用例会报错。

在元组类型中，与 JavaScript 数组一样的，都存在一个 `length` 属性，表示元组的长度。解法一直接取 `length` 属性，而解法二则是使用了 `infer` 推断的方式返回了推断值。

## Awaited

假如我们有一个 Promise 对象，这个 Promise 对象会返回一个类型。在 TS 中，我们用 Promise 中的 `T` 来描述这个 Promise 返回的类型。请你实现一个类型，可以获取这个类型。

例如：`Promise<ExampleType>`，请你返回 ExampleType 类型。

```ts
type ExampleType = Promise<string>

type Result = MyAwaited<ExampleType> // string
```

> 在 TypeScript 4.5 中已经内置了 `Awaited` 方法类型。

答案：

```ts
type MyAwaited<T extends PromiseLike<any>> = T extends PromiseLike<infer U>
  ? U extends PromiseLike<any>
    ? MyAwaited<U>
    : U
  : never;
```

解析：

已知的，泛型 `T` 必须继承 Promise 类，因此使用 `T extends Promise<any>` 限制泛型 `T` 的类型。然后使用 `infer` 推断 Promise 返回的具体类型，如果 `extends` 为真则返回推断值，否则表示无法推断则返回 `never`，因此我们可以将 `MyAwait` 编写为：

```ts
type MyAwait<T extends Promise<any>> = T extends Promise<infer U> ? U : never
```

但是这样只能推断一层 Promise，我们题目中要求的是可以推断多层 Promise 的最终返回值，例如用例 `type Z1 = Promise<Promise<Promise<string | boolean>>>`，`MyAwait<Z1>` 需要返回 `string | boolean`。因此我们需要使用递归判断推断值 `U` 是否仍是一个 Promise 对象，如果是的话则使用 `MyAwaited` 对其进行递归调用，因此我们继续完善答案：

```ts
type MyAwaited<T extends Promise<any>> = T extends Promise<infer U>
  ? U extends Promise<any>
    ? MyAwaited<U>
    : U
  : never;
```

但是对于用例 `type T = { then: (onfulfilled: (arg: number) => any) => any }`，套用上面的 `MyAwait` 会报错，因为它不是一个标准的 Promise 对象，这时候就需要使用 `PromiseLike`。

`PromiseLike` 是  TypeScript 内置的一个 Promise 的 DuckType（看起来像但不是）。这是因为在 ES6 的标准 Promise 对象出现前就已经有了 Promise 的相关概念，如 [Promise/A](https://wiki.commonjs.org/wiki/Promises/A)。因此 TypeScript 提供了一个 `PromiseLike` 类型方便开发者使用给遵循了 Promise 标准但并不是 ES6 中的标准 Promise 的对象使用，因此最终的答案为：

```ts
type MyAwaited<T extends Promise<any>> = T extends Promise<infer U>
  ? U extends Promise<any>
    ? MyAwaited<U>
    : U
  : never;
```

## If

实现一个 `IF` 类型，它接收一个条件类型 `C` ，一个判断为真时的返回类型 `T` ，以及一个判断为假时的返回类型 `F`。 `C` 只能是 `true` 或者 `false`， `T` 和 `F` 可以是任意类型。

例如：

```ts
type A = If<true, 'a', 'b'>  // expected to be 'a'
type B = If<false, 'a', 'b'> // expected to be 'b'
```

答案：

```ts
type If<C extends boolean, T, F> = C extends true ? T : F
```

## Concat

[Source](https://github.com/type-challenges/type-challenges/blob/main/questions/00533-easy-concat/README.zh-CN.md)

在类型系统里实现 JavaScript 内置的 `Array.concat` 方法，这个类型接受两个参数，返回的新数组类型应该按照输入参数从左到右的顺序合并为一个新的数组。

例如：

```ts
type Result = Concat<[1], [2]> // expected to be [1, 2]
```

答案：

```ts
type Concat<T extends readonly any[], U extends readonly any[]> = [...T, ...U];
```

解析：

TypeScript 的类型声明中，`...` 展开运算符是可用的，因此只需要展开数组类型的泛型即可。但是要注意存在用例 `Expect<Equal<Concat<typeof tuple, typeof tuple>, [1, 1]>>`，因此要使用 `readonly`。

## Includes

[Source](https://github.com/type-challenges/type-challenges/blob/main/questions/00898-easy-includes/README.zh-CN.md)

在类型系统里实现 JavaScript 的 `Array.includes` 方法，这个类型接受两个参数，返回的类型要么是 `true` 要么是 `false`。

例如：

```ts
type isPillarMen = Includes<['Kars', 'Esidisi', 'Wamuu', 'Santana'], 'Dio'> // expected to be `false`
```

答案：

```ts
export type IsEqual<X, Y> =
    (<T>() => T extends X ? 1 : 2) extends
    (<T>() => T extends Y ? 1 : 2) ? true : false;


type Includes<T extends readonly unknown[], U> =
  T extends [infer First, ...infer Rest]
    ? Equal<First, U> extends true ? true : Includes<Rest, U>
    : false;
```

解析 ：

看到这个题目我们可能首先会考虑将 `Includes` 的第一个参数位传入的元组转为联合类型，然后如果第二个参数的类型如果对于该联合类型的 `extends` 结果为真，则说明该类型包含于元组中，实现如下：

```ts
type Includes<T extends readonly any[], U> = U extends T[number] ? true : false;
```

但我们编写的这个方法只能通过 `Includes<['Kars', 'Esidisi', 'Wamuu', 'Santana'], 'Dio'>` 这样的简单用例，对于稍微复杂的情况，比如元组中存在 `boolean` 这样的类型，那么 `false` 和 `true` 对于其的 `extends` 结果都未真，那么判断将会失败。亦或者是元组中存在 interface 类型，如 `Includes<[{ readonly a: 'A' }], { a: 'A' }>` 则也无法正确判断（结果是 `true`，而预期值是 `false`）。

那么我们换一种思路，在不使用值对比的方式时，如果使用 JavaScript 编写数组的 includes 方法，我们可以构造一个 Map 的数据结构，将数组中所有的元素都作为 Map 的 key 值，然后查看目标值是否在 Map 上存在，如：

```js
function myIncludes(arr, target) {
  const map = {};
  for (let i = 0; i < arr.length; i++) {
    map[arr[i]] = i;
  }
  return map[target] !== undefined;
}
```

我们使用 TypeScript 的类型声明来实现这个方法，可以写为：

```ts
type Includes<T extends readonly any[], U> = {
  [P in T[number]]: true
}[U] extends true ? true : false;
```

当然，在 JavaScript 中以这种方式实现的 includes 方法不不能判断引用类型的值，我们在将引用类型的值作为对象的 Key 时，会被字符串化，如 `{a: 123}` 会被字符串化为 `{[object Object]: true}`。

相同的，在类型声明中，上面我们实现的 Includes 工具类型只能处理 `1`、`2` 、`'a'` 这种基本类型，遇到函数类型、interface、boolean 这样的类型则会直接跳过，不会作为 key 值写入到生成的 interface 中。面对 `Includes<[{ a: 'A' }], { a: 'A' }>`、`Includes<[false, 2, 3, 5, 6, 7], false>` 这样的用例时无法正常处理，获取到的都是 `false`，而对于 `Includes<[1 | 2], 1>` 这样包含了这种由基础类型构成的联合类型的用例，内部会转化为 `{1: true, 2: true}`，因此结果会变为 `true`。

上面两种方式都没法满足我们的目标，我们继续思考，如果可以解决**如何在 TypeScript 中准确判断两个类型是否相同**、**并且在类型声明中可以进行遍历操作**，这样只要遍历元组中的每个元素是否与目标元素相同，就可以得出目标元素是否包含在元组中的结果了。

关于解决判断类型是否相同，我们编写一个 `IsEqual` 工具类，其来源可以查看[这里](https://github.com/microsoft/TypeScript/issues/27024#issuecomment-421529650)，通过该工具类可以查看类型是否相同，实现如下：

```ts
export type IsEqual<X, Y> =
    (<T>() => T extends X ? 1 : 2) extends
    (<T>() => T extends Y ? 1 : 2) ? true : false;
```

对于遍历操作，TypeScript 中虽然不能使用 for 循环，但是可以使用 `extends` 进行条件判断，并且可以调用自身的类型声明，因此我们可以使用递归的方式实现遍历：

```ts
type Includes<Value extends any[], Item> =
	IsEqual<Value[0], Item> extends true
		? true
		: Value extends [Value[0], ...infer Rest]
			? Includes<Rest, Item>
			: false;
```

我们已经接近标准答案了，但是上面的实现无法处理 `Includes<[null], undefined>` 这个用例，解决这个也并不复杂，我们只需要在递归前进行一个非空检查，如下：

```ts
type Includes<Value extends any[], Item> =
  Value extends [Value[0], ...infer Rest]
    ? IsEqual<Value[0], Item> extends true ? true : Includes<Rest, Item>
    : false;
```

## Push

[Source](https://github.com/type-challenges/type-challenges/blob/main/questions/03057-easy-push/README.zh-CN.md)

在类型系统里实现通用的 `Array.push` 。

例如：

```ts
type Result = Push<[1, 2], '3'> // [1, 2, '3']
```

答案：

```ts
type Push<T extends any[], U> = [...T, U]
```

相同题目 [Shift](https://github.com/type-challenges/type-challenges/blob/main/questions/03060-easy-unshift/README.zh-CN.md#unshift--) 不再记录。

## Parameters

[Source](https://github.com/type-challenges/type-challenges/blob/main/questions/03312-easy-parameters/README.zh-CN.md)

TypeScript 内置工具类型 Parameters 可以提取函数的参数类型。

例如：

```ts
type T2 = Parameters<(arg: string) => any>; // [arg: string]
type Arg = T2[0] // string
```