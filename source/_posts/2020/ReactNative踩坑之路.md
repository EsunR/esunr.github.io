---
title: ReactNative踩坑之路
tags: [ReactNative]
categories:
  - Front
  - React
date: 2020-10-14 11:29:56
---

## 1. ScrollView 中的 TextInput 阻止滑动操作

当 TextInput 出现在 ScrollView 中时，同时设置 `textAlign: right` 的样式后，会出现如果点按到 TextInput 元素后再下滑，就会导致无法下滑。这一问题是 React 本身的 Bug 造成的，参考 issus: https://github.com/facebook/react-native/issues/12167

一个临时的解决方案是，为 TextInput 设置如下的属性：

```
multiline={true}
keyboardType={"default"}
```

## 2. KeyboardAvoidingView 防止键盘遮挡

`KeyboardAvoidingView` 用于防止键盘遮挡住用户的输入组件：

```tsx
<KeyboardAvoidingView behavior="height">
  <Item />
  <Item />
  <Item />
</KeyboardAvoidingView>
```

当想要与 `ScrollView` 搭配使用，则可以直接嵌套入 `KeyboardAvoidingView` 中：

```tsx
<KeyboardAvoidingView behavior="height">
  <ScrollView>
    <Item />
    <Item />
    <Item />
  </ScrollView>
</KeyboardAvoidingView>
```

我们在表单中通常会有一个提交按钮，该按钮固定于屏幕下方，当键盘弹起时，该按钮也会出现，如果要想实现这样的布局：

```tsx
<KeyboardAvoidingView behavior="height">
  <ScrollView style={{marginBottom: 100}}>
    <Item />
    <Item />
    <Item />
  </ScrollView>

  <SubmitButton style={{position: "absolute", height: 100}}>提交</SubmitButton>
</KeyboardAvoidingView>
```

# 3. 键盘展开时操作组件

当在 ScrollView 中存在 TextInput 时，用户点击 TextInput 后会弹出键盘，此时当用户想要点击 ScrollView 中的其他**可点击元素**时，就会先缩回键盘，此时可点击元素身上所绑定的点击事件并未触发，当用户再次点击时才会触发。

然而在实际情况下，我们希望用户在键盘展开时点击其他可点击元素时，就直接触发该元素身上的点击事件。这时我们需要在 `<ScrollView />` 组件上添加 `keyboardShouldPersistTaps` 属性，由官方文档可知，其有如下几个值：

- 'never' （默认值），点击 TextInput 以外的子组件会使当前的软键盘收起。此时子元素不会收到点击事件。
- 'always'，键盘不会自动收起，ScrollView 也不会捕捉点击事件，但子组件可以捕获。
- 'handled'，当点击事件被子组件捕获时，键盘不会自动收起。这样切换 TextInput 时键盘可以保持状态。多数带有 TextInput 的情况下你应该选择此项。
- false，已过时，请使用'never'代替。
- true，已过时，请使用'always'代替。

`always` 与 `handled` 是比较难弄明白的，举个例子来说：

- 当我们想要触发可点击元素身上的事件，同时保持当前聚焦的 `TextInput` 组件不失去焦点，那就使用 `always`。当我们触发点击事件后，不会失去焦点，同时键盘也不会缩回。
- 当我们想要触发可点击元素身上的事件，同时失去当前聚焦的 `TextInput` 的焦点，那就使用 `handled`。

**需要特别注意的是**，如果在 ScrollView 中嵌套 ScrollView，如果父级的 ScrollView 没有设置 `keyboardShouldPersistTaps` 属性，那么子级的 ScrollView 设置的 `keyboardShouldPersistTaps` 属性是无效的。