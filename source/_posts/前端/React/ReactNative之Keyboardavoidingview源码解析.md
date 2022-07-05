---
title: ReactNative 之 Keyboardavoidingview 源码解析
tags:
  - ReactNative
  - 源码解析
categories:
  - 前端
  - React
date: 2020-10-15 12:03:08
---

> 源码地址：https://github.com/facebook/react-native/blob/master/Libraries/Components/Keyboard/KeyboardAvoidingView.js

# 1. 组件原理

Keyboardavoidingview 组件通常用于防止键盘遮挡住界面可视区域。其原理也很简单，Keyboardavoidingview 组件本身是一个容器，当键盘弹出后，Keyboardavoidingview 会自动缩减自身容器的高度，从而达到防止键盘遮挡的目的。

![](https://i.loli.net/2020/10/15/2NyJSbsrP73EuDM.png)

# 2. 源码解析

该组件在 Render 函数中进行了条件渲染用来处理不同的渲染方式：

```jsx
render(): React.Node {
  const {
    behavior,
    children,
    contentContainerStyle,
    enabled,
    keyboardVerticalOffset,
    style,
    ...props
  } = this.props;
  const bottomHeight = enabled ? this.state.bottom : 0;
  switch (behavior) {
    // height 模式下，键盘展开后改变 Keyboardavoidingview 容器的高度
    case 'height':
      let heightStyle;
      if (this._frame != null && this.state.bottom > 0) {
        heightStyle = {
          height: this._initialFrameHeight - bottomHeight,
          flex: 0,
        };
      }
      return (
        <View
          ref={this.viewRef}
          style={StyleSheet.compose(style, heightStyle)}
          onLayout={this._onLayout} // 记录初始的
          {...props}>
          {children}
        </View>
      );
    // position 模式下 Keyboardavoidingview 会被渲染为两层容器
    // 当键盘展开时，外部容器不发生改变，内部容器定位发生变化
    case 'position':
      return (
        <View
          ref={this.viewRef}
          style={style}
          onLayout={this._onLayout}
          {...props}>
          <View
            style={StyleSheet.compose(contentContainerStyle, {
              bottom: bottomHeight,
            })}>
            {children}
          </View>
        </View>
      );
    // padding 模式下，键盘展开后改变 Keyboardavoidingview 容器的下方 padding
    case 'padding':
      return (
        <View
          ref={this.viewRef}
          style={StyleSheet.compose(style, {paddingBottom: bottomHeight})}
          onLayout={this._onLayout}
          {...props}>
          {children}
        </View>
      );
    // 如果没有传入 behavior 参数，那么就将其作为一个普通的 View 进行处理
    default:
      return (
        <View
          ref={this.viewRef}
          onLayout={this._onLayout}
          style={style}
          {...props}>
          {children}
        </View>
      );
  }
}
```

在进行不同组件的渲染时，其重点就是去根据键盘的高度，实时的去计算容器的高度（或者是边距，又或者时位置偏移量）。

以 `height` 模式为例，其容器的高度为 `this._initialFrameHeight - bottomHeight`。其中 `this._initialFrameHeight` 指的是初始状态下的容器高度，该值会在容器初次触发 `onLayout` 事件时被记录：

```ts
_onLayout = (event: ViewLayoutEvent) => {
  this._frame = event.nativeEvent.layout;
  if (!this._initialFrameHeight) {
    // 记录键盘展开前，容器的初始高度
    this._initialFrameHeight = this._frame.height;
  }

  this._updateBottomIfNecesarry(); // 重新计算 bottom 高度
};
```

而 `bottomHeight` 就是键盘高度，该值对应组件 state 中的 `bottom`，在组件每次**触发容器 `onLayout` 事件以及触发键盘事件**时都会重新计算 `bottom` 的值：

```ts
_updateBottomIfNecesarry = () => {
  // 如果键盘收起，那么 bottom 的值就为 0（键盘高度为 0）
  if (this._keyboardEvent == null) {
    this.setState({bottom: 0});
    return;
  }

  const {duration, easing, endCoordinates} = this._keyboardEvent;
  const height = this._relativeKeyboardHeight(endCoordinates); // 计算键盘的高度，将键盘当前的位置信息传入 ===> 重点

  if (this.state.bottom === height) {
    return;
  }

  if (duration && easing) {
    LayoutAnimation.configureNext({
      // We have to pass the duration equal to minimal accepted duration defined here: RCTLayoutAnimation.m
      duration: duration > 10 ? duration : 10,
      update: {
        duration: duration > 10 ? duration : 10,
        type: LayoutAnimation.Types[easing] || 'keyboard',
      },
    });
  }
  this.setState({bottom: height});
};
```

计算键盘的高度时需要去通过判断各个组件的位置才能准确得出。首先，我们在 `_updateBottomIfNecesarry` 中可以获取到键盘事件，从而得到键盘展开后距离屏幕顶端的距离（keyboardFrame.screenY）。然后我们可以通过获取当前容器距离屏幕顶部的距离（this._frame.y）以及当前容器的高度（this._frame.height），将其相加并于键盘距离屏幕顶部的高度相减，即可得出键盘的高度：

![](https://i.loli.net/2020/10/15/MhSuEqmFc83yZLI.png)

这一操作在 `this._relativeKeyboardHeight` 实现：

```jsx
_relativeKeyboardHeight(keyboardFrame): number {
  const frame = this._frame; // 在当状态下，容器的位置信息（此时容器的底部必定低于当前帧下键盘顶部之下）
  if (!frame || !keyboardFrame) {
    return 0;
  }

  const keyboardY = keyboardFrame.screenY - this.props.keyboardVerticalOffset;

  // Calculate the displacement needed for the view such that it
  // no longer overlaps with the keyboard
  return Math.max(frame.y + frame.height - keyboardY, 0);
}
```

需要注意的是，我们在计算 `keyboardY` 时减去了一个 `keyboardVerticalOffset`，该数值可以作为参数传入到 `<Keyboardavoidingview />` 组件中，那么该数值究竟以为这什么？

在官方文档中解释到：这是用户屏幕顶部和react native视图之间的距离，在某些用例中可能不为零，默认为0。这句话很抽象，让我们具体到一个实例中来讲，我们想象这样一个布局结构：

```html
<AppView>
  <!-- 导航栏 -->
  <Header />

  <!-- 内容区域 -->
  <ContentView>
    <Keyboardavoidingview>
      <TextInput>
      <TextInput>
      <TextInput>
      <TextInput>
    </Keyboardavoidingview>
  </ContentView>
</AppView>
```

在上面的布局中，ContentView 为了保证内部元素的定位相时对于其本身的，因此其定位属性是 **相对定位**。此时，Keyboardavoidingview 组件内部计算自己的定位高度时（layout.y），计算的高度是从 ContentView 算起的，那么减去了键盘位置偏移量（keyboardFrame.screenY）后，就会发现减多了。为了避免这种情况，就加入了 `keyboardVerticalOffset` 属性来手动矫正偏移量：

![](https://i.loli.net/2020/10/15/gM6ourBRFksbZp4.png)