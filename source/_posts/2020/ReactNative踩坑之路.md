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

# 4. 奇葩的 Navigation Listener

在 Navigation 5 中使用 `addListener()` 方法添加导航监听，如果初次看官方文档可能会一脸懵比，因为没有提到如何移除时间监听。但是在官方示例中，我们可以看到一个细节，示例中使用了一个箭头函数，直接返回了 `addListener()` 方法的返回值，由此我们可以看出 `addListener()` 方法的返回值是一个函数，而且这个函数就是用来移除监听函数的。我们如果写的明白点就可以写为：

```js
useEffect(() => {
  const removeListener = navigation.addListener("beforeRemove", ()=>{
    // do something
  });
  return () => { 
    removeListener()
  }
}, [])
```

还有一个坑，假设一个场景，通过事件监听拦截返回动作，让返回上层的默认动作改为返回到路由界面顶层，那么我们可能会这么写：

```js
useEffect(() => {
  const removeListener = navigation.addListener("beforeRemove", (e)=>{
    e.preventDefault();
    navigation.popToTop(); // 退回到顶层路由
  });
  return removeListener;
}, [])
```

然后当我们返回后，就会 Boom ！出现堆栈溢出的警告。

这是因为在执行 `popToTop()` 时，必定会再次触发组件的 `beforeRemove` 事件，然后再触发监听，导致再次执行 `popToTop()`，然后触发监听事件 ... ... 这样就陷入了一个死循环，堆栈自然会溢出。于此相类似的，只要我们想返回之前的任一页面，就都会触发 `beforeRemove` 事件，然后陷入到如此的死循环。但是如果我们前往一个新的页面，就不会触发 `beforeRemove` 事件，也就能正常跳转了。

那解决方案也很简单，在执行 `popToTop()` 方法前，移除掉路由的监听：

```diff
  useEffect(() => {
    const removeListener = navigation.addListener("beforeRemove", (e)=>{
+     removeListener();
      e.preventDefault();
      navigation.popToTop(); // 退回到顶层路由
    });
    return removeListener;
  }, [])
```

> PS: 官方使用了 `navigation.dispatch(e.data.action)` 来正常使页面进行了 goBack 操作并没有触发 `beforeRemove`，这一点让我很迷。因为 `e.data.action` 实际上就是 `{type: "GO_BACK"}` 而使用 `dispatch` 派发这个动作必定会触发 `beforeRemove`，不知道为什 `navigation.dispatch(e.data.action)` 可行，而 `navigation.dispatch({type: "GO_BACK"})` 不行

# 5. 阻止事件冒泡


React Native 的事件系统与 Web 是有些不一样的。

以触摸事件举例，当父元素绑定了触摸事件，会出现以下的情况：

- 当子元素上没有任何 Touchable 组件，会触发父元素的事件
- 当子元素有 Touchable 组件，那么只会触发当前子元素的点击事件，不会触发父元素的事件

因此可得 React Native 默认是阻止事件冒泡的，但是总感觉阻止冒泡的方式很奇怪，而且如果阻止了点击事件，子元素的滑动事件也无效了（比如在子元素中加入一个 ScrollView，那么 ScrollView 是无法滑动的）。

那么有没有一个方法可以显示指定不触发父元素的事件呢，经过对 react-native-elements `Overlay` 组件的学习，发现 View 上有一个 [pointerEvents](https://reactnative.cn/docs/view#pointerevents) 属性。

如果子元素想阻止父元素的点击事件，只需要在子元素上添加 `pointerEvents="box-none"` 即可
