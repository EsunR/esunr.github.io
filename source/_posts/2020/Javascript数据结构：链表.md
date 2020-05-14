---
title: Javascript数据结构：链表
tags: [数据结构]
categories:
  - Base
  - 数据结构
date: 2020-05-14 17:12:15
---

# 1. 概论

## 1.1 链表与数组的区别

存储多个元素来说，链表与数组都是很好的选择。Javascript 也内置的数组对象（小知识：Javascript 第一个版本中没有数组对象），并且定义了很多的操作方法。**但是数组也有很多的不足，对于数组来说，从数组的起点或中间插入或移除项目的成本很高，因为要移动元素**。然而对于链表而言，插入元素或者删除元素只需要移动链的指向即可，成本相对较低。然而但对于单纯的访问元素来说，数组可以直接通过索引坐标来访问，而链表要想访问一个数组则需要从头结点（Head）开始访问到最后。

## 1.2 链表的结构

链表通常由一个 Head 节点开始，链中的每个节点都有一个 value 存放节点的值，以及一个 next 指针来指向下一个节点，直到最后一个节点的 next 指向 null。

![](http://img.cdn.esunr.xyz/markdown/20200514172551.png)

# 2. 实现

链表在 Javascript 中并没有一个内置的实现，因此需要我们手动实现。

## 2.1 节点的构建

节点是链表中的基本单位，一个节点包含当前节点的值，以及一个 next 指针指向下一个节点对象，我们可以构建为：

```js
class Node {
  constructor(value) {
    this.value = value;
    this.next = null;
  }
}

let node = new Node(1)
```

我们就构建好了一个基本节点：

![](http://img.cdn.esunr.xyz/markdown/20200514173244.png)

## 2.2 链表结构的构建

虽然我们已经构建出了链表节点的结构，但是我们还未对整个链表的整体结构进行一个定义。一个链表的整体结构是由一个 Head 节点出发的，因此 Head 节点是链表实例上的一个属性，同时节点数也是一个链表的属性，此外链表上还拥有各种各样的方法，以便于我们去打印链表、添加节点、删除节点、查找节点。

因此我们可以构建出一下一个链表的基本结构，随后再对链表的内置方法进行定义：

```js
class LinkedList {
  constructor() {
    this.count = 0;
    this.head = null;
  }

  print() { /** 具体实现 */ }
  
  push(value) { /** 具体实现 */ }
}
```

## 2.3 打印链表

打印链表需要从链表头部开始打印，依次向后重复取值，指导取值为 null 时停止取值

![](http://img.cdn.esunr.xyz/markdown/20200514174717.png)

```js
print() {
  let res = "";
  let cur = this.head;
  while (cur !== null) {
    cur.next === null
      ? (res += cur.value)
      : (res += cur.value + "=>");
    cur = cur.next;
  }
  console.log(res);
}
```

## 2.4 向链表尾部添加元素

为链表添加节点分两种情况：

- 如果链表中没有节点（`this.head === null`），则新增节点作为 head
- 如果链表中有节点，则在链表最后一位添加节点

![](http://img.cdn.esunr.xyz/markdown/20200514175453.png)

```js
push(value) {
  // 新结点
  let newNode = new Node(value);
  // 如果是头节点为空就将新节点放到头结点上
  if (this.head === null) {
    this.head = newNode;
  }
  // 否则将新节点放到链表的末尾
  else {
    let cur = this.head;
    while (cur.next !== null) {
      cur = cur.next;
    }
    cur.next = newNode;
  }
  this.count++;
}
```

## 2.5 删除节点

删除节点也分两种情况：

- 如果是移除第一项，就将链表的 head 转移给第二个节点
- 如果移除的不是第一项，就找到目标索引对应的节点，将节点的上一个节点的 next 指向，改为下一个节点上

```js
removeAt(index) {
  if (index < 0 || index > this.count) {
    throw new Error("索引值不存在");
  }
  // 如果是移除第一项，就将链表的 head 转移给第二个节点
  if (index === 0) {
    this.head = this.head.next;
  }
  // 如果移除的不是第一项，就找到目标索引对应的节点，
  // 将节点的上一个节点的 next 指向，改为下一个节点上
  else {
    let cur = this.head;
    let prev;
    for (let i = 0; i < index; i++) {
      prev = cur;
      cur = cur.next;
    }
    // 更改目标节点上一个节点的指向
    prev.next = cur.next;
  }
}
```