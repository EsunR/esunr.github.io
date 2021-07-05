---
title: 整理JavaScript数组去重的种种方法
tags: [面试题]
categories:
  - Front
  - JS
date: 2020-03-12 23:10:28
---

# 1. 前言

数组去重是个相对于简单的需求，但是其比较考验编程人员对 Javascript 对数组 API 以及数据类型的熟悉程度。

去重的目标数组：

```js
let obj1 = { name: "花花" };
let obj2 = { name: "小明" };
var arr = [ 1, "1", 1, "NaN", undefined, obj2, null, undefined, NaN, NaN, 1, obj1, null, obj1, obj2 ];
```

# 2. 使用 Javascript 中某些数据类型的值不会重复的特性进行去重

## 2.1 使用 Set 结构

使用 Set 结构进行数组去重是 ES6 环境下最为推荐的方式，其特性就是不允许数组中出现重复的元素：

```js
function uniqueBySet(arr) {
  return Array.from(new Set(arr));
}
```

```
[ 1, '1', 'NaN', undefined, { name: '小明' }, null, NaN, { name: '花花' } ]
```

甚至还可以更加精简：

```js
[...new Set(arr)]
```

## 2.2 使用 Object keys 特性

一个 Object 不允许有相同的键值，因此我们可以用其特性进行去重：

```js
function uniqueByObject(arr) {
  let result = [];
  let obj = {};
  for (let item of arr) {
    if (!obj[item]) {
      result.push(item);
      obj[item] = 1;
    }
  }
  return result;
}
```

> 但是由于 Object Key 只能为字符串，所以无法分辨 Number 与 String 的区别，并且无法分别引用类型的数据（因为会被转为 "[object Object]" 类似的字符串）。

```
[ 1, 'NaN', undefined, { name: '小明' }, null ]
```

如果我们将其键值存储为 `typeof item + item` 那么，`"1"` 被存入为键值的时候就会成为 `"string1"`，`1` 被存为键值的时候就会成为 `"number1"`，这样就能区分 Number 与 String 了。同时我们还可以使用 `Object.prototype.hasOwnProperty()` 来判断创建的对象是否有某一属性，这样更为严谨：

```js
function uniqueByHasOwnProperty(arr) {
  var obj = {};
  return arr.filter(function(item) {
    return obj.hasOwnProperty(typeof item + item)
      ? false
      : (obj[typeof item + item] = 1);
  });
}
```

> 但是此时我们仍无法区分引用类型

```
[ 1, '1', 'NaN', undefined, { name: '小明' }, null, NaN ]
```

## 2.3 使用 Map keys 特性

Map 结构优于 Object 结构的是其键值可以存放对象，这样就可以完美应用于数组去重：

```js
function uniqueByMap(arr) {
  let map = new Map();
  for (let item of arr) {
    map.set(item, 1);
  }
  // map.keys() 返回的是一个新的 Map iterator 对象，需要转换为数组再返回
  return Array.from(map.keys());
}
```

```
[ 1, '1', 'NaN', undefined, { name: '小明' }, null, NaN, { name: '花花' } ]
```

# 3. for 循环嵌套去重

这是最简单明了的一种去重方式，也是 ES5 环境下可以使用的去重方式，其利用 `splice()` 方法，会直接修改目标数组：

```js
function uniqueByFor(arr) {
  for (let i = 0; i < arr.length; i++) {
    for (let j = i + 1; j < arr.length; j++) {
      if (arr[i] === arr[j]) {
        arr.splice(j, 1);
        j--;
      }
    }
  }
  return arr;
}
```

> 由于 NaN === NaN 结果为 false，所以其无法对 NaN 进行去重

```
[ 1, '1', 'NaN', undefined, { name: '小明' }, null, NaN, NaN, { name: '花花' } ]
```

# 4. 使用 indexOf 去重

## 3.1 单纯使用 indexOf

使用 `Array.prototype.indexOf()` 方法可以检索元素的出现位置，更重要的是判断元素是否存在于某个数组中。

因此我们可以额外准备一个新数组，依次遍历目标数组，遍历时看当前遍历的元素是否在创建的新数组中，如果不存在就放入新数组，否则就不需要放入新数组，最终将这个新数组返回即可，且该方法可以用于 ES5 环境：

```js
function uniqueByIndexOf(arr) {
  let result = [];
  for(let i = 0; i < arr.length; i++){
    if (result.indexOf(current) === -1) {
      result.push(current);
    }
  }
  return result;
}
```

> 由于 [NaN].indexOf(NaN) 结果为 -1，所以无法对 NaN 进行去重

```
[ 1, '1', 'NaN', undefined, { name: '小明' }, null, NaN, NaN, { name: '花花' } ]
```

## 3.2 使用 includes 代替 indexOf 去重

在 ES6 中引入了 `Array.prototype.includes()` 专门检测某元素是否存在于目标数组中，同时可以判断 `NaN` 类型，正好可以弥补单纯使用 `indexOf()` 进行去重的劣势：

```js
function uniqueByIncludes(arr) {
  // 利用 reducer 进一步简化代码
  return arr.reduce(function(prev, current) {
    return prev.includes(current) ? prev : [...prev, current];
  }, []);
}
```

```
[ 1, '1', 'NaN', undefined, { name: '小明' }, null, NaN, { name: '花花' } ]
```


## 3.3 使用 filter 与 indexOf 去重

使用 `indexOf()` 还需要创建一个空数组，利用 ES6 的 `filter()` 方法可以免除创建一个新数组。同时其思想由原来的放入新数组，改为了判断当前遍历元素是否是数组中第一个出现的：

```js
function uniqueByFilter(arr) {
  return arr.filter(function(item, index) {
    // 看当前元素是否是数组中第一个出现的
    return arr.indexOf(item) === index;
  });
}
```

> 由于 [NaN].indexOf(NaN) 结果为 -1，所以无法对 NaN 不再结果中

```
[ 1, '1', 'NaN', undefined, { name: '小明' }, null, { name: '花花' } ]
```

# 5. 数组排序后去重（不稳定）

## 5.1 使用 sort 去重

`Array.prototypr.sort()` 可以对数组进行排序，我们将数组排序后，重复的元素就会并列出现，因此可以直接遍历每个元素，如果当前元素与上一个元素并非重复，那就将其放入新数组，否则就略过，直至遍历完所有数组：

```js
function uniqueBySort(arr) {
  arr.sort();
  let result = [];
  for (let i = 0; i < arr.length; i++) {
    // 当前元素与前一个元素相比看是否相等
    // 注意这里不能与后一个元素比是否相等，因为如果数组中存在 undefined 的话，arr[length + 1] 会与 undefined 相等，导致 undefined 不会被添加到数组中
    if (arr[i] !== arr[i - 1]) {
      result.push(arr[i]);
    }
  }
  return result;
}
```

> 由于 sort 会将数字与字符串统一转换为数字，所以当数组中存在例如 [1, "1", 1] 这样的元素时，会原封不动的将其排列为原有的顺序，导致后面去重失败，并且 sort 也无法对引用类型进行排序。同时由于去重前的对比操作基于 `===` 操作符的判断，因此对 NaN 类型也无法判断。

```
[
  1,              '1',
  1,              'NaN',
  NaN,            NaN,
  { name: '小明' }, { name: '花花' },
  { name: '小明' }, null,
  undefined
]
```

## 5.2 排序后用递归思想去重

上一种方法还是要创建一个新数组，如果我们想要直接操作需要去重的数组，那么还需要一点递归思想：

```js
function uniqueByRecursive(arr) {
  arr.sort();
  function unique(index) {
    if (index >= 1) {
      if (arr[index] === arr[index - 1]) {
        arr.splice(index, 1);
      }
      unique(index - 1);
    }
  }
  unique(arr.length - 1);
  return arr;
}
```

> 劣势与上面一致

```
[
  1,              '1',
  1,              'NaN',
  NaN,            NaN,
  { name: '小明' }, { name: '花花' },
  { name: '小明' }, null,
  undefined
]
```

## 5.2 排序后用原地算法去重（仅适用于数字）

```js
function uniqBySort(nums) {
  const sortedNums = nums.sort();
  // 当前索引位置的元素期望是不重复的元素，同时改变量表示不重复元素的个数
  let noRepeatIndex = nums.length ? 1 : 0;
  for (let i = 0; i < sortedNums.length; i++) {
    const current = sortedNums[i];
    // 如果当前元素比 noRepeatIndex-1 位置的元素要大，就将其放置到 noRepeatIndex 的位置上，并将 noRepeatIndex 向后指
    if (current > sortedNums[noRepeatIndex - 1]) {
      sortedNums[noRepeatIndex] = current;
      noRepeatIndex++;
    }
  }
  return sortedNums.slice(0, noRepeatIndex);
}
```

# 6. 总结

数组去重并非是难题，但是里面坑比较多，需要注意以下几点：

- 利用 object keys 去重的话，注意 keys 会被转换为字符串
- `indexOf()` 方法与 `===` 运算符都不能判断 NaN 类型
- `sort()` 方法对字符串与对象的排序会对后续去重产生影响

