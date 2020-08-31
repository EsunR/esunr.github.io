---
title: ReactNative下实现文本折叠的效果
tags: [ReactNative]
categories:
  - Front
  - React
date: 2020-07-22 19:39:26
---

## 1. 场景

在默认情况下，文本显示两行，同时未显示全的文字要有省略号的效果：

![](http://img.cdn.esunr.xyz/markdown/20200722194115.png)

当用户点击展开按钮后，可以展开全部文本：

![](http://img.cdn.esunr.xyz/markdown/20200722194228.png)

## 2. 分析

在 RN 中 `<Text>` 组件拥有一个 props 为 `numberOfLines` 可以用来显示文本的行数，如果超出文本行数，文本就会用 `...` 来表示，我们可以利用这个特性来控制文本是否展开显示。

但是又有一个新的需求：**如果文本没有超过两行，那就不应该显示展开按钮**。

要想实现这个需求，就必须动态的判断文本的高度，但是在 RN 中我们无法直接获取组件的 layout，好在 `<Text>` 组件还提供了一个事件函数 `onLayout`，这个方法会在布局产生变化后被触发，函数的参数传递了一个事件对象，事件对象中包含了一个 `layout` 对象，这样我们就可以获取到文本块的高度了。

其次我们可以利用 `行高*允许显示的行数` 来获取到允许显示的文本块的最大高度，也就是文本溢出的最大高度。那么我们只需要将前面获取到的 **文本块实际高度** 与 **溢出的最大高度** 进行对比，就能判断出该文本是否是溢出文本，入下伪代码可以表示我们目前的思路：

```tsx
const [isOverflow, setIsOverflow] = useState<boolean>(false);
const lineHeight = 25;
const numberOfLines = 2;

return <View>
  <Text 
    numberOfLines={numberOfLines} 
    onLayout={(e)=>{
      const {height} = e.layout
      if(height > lineHeight * numberOfLines) {
        setIsOverflow(true)
      }else{
        setIsOverflow(false)
      }
    }}>
    文本内容文本内容文本内容文本内容文本内容文本内容文本内容文本内容文本内容文本内容
  </Text>
</View>
```

按照如上代码 `setIsOverflow` 可以很准确的来判断出文本是否溢出。但是再往后面进行，如果我们把文本折叠起来，`onLayout` 方法就会重新再被执行，此时已经被折叠的文本的高度理论上是完全等于 `lineHeight * numberOfLines` 的，那么再经过上面的判断，`isOverflow` 会被设置为 `false`，文本被标识为非溢出文本，展开按钮相应的也就消失掉了，我们的文本无法再次展开。

看来上面这条路是走不通的，要想实现准确的判断我们就必须获取到文本初始时的高度，那么我们可能又会想是否可以在 `onLayout` 第一次触发时去记录并对比文本块的高度，当文本再折叠后就不去计算文本的高度了。这是一个好方法，但是它违背了我们 React 组件的设计逻辑。因为如果传入的 Text 文本是动态改变的，那么如果文本再前一秒是个 10 行的文字，在下一秒是个 1 行的文字，要想实现高度的重新计算我们就必须将组建移除再重新渲染（重新清空 state）的状态，这样不管是用户使用还是性能上来说都是很差的。

因此还有一个方案，我们去设计两块文本，这两块的文本内容一模一样，但是其作用不一样：

- 一块文本用于展示以及交互，他的高度是可被操作且动态改变的；
- 另一块文本是被隐藏的，但是它的结构还是存在的，同时它的高度是固定的。

这样我们只需要从被隐藏的文本身上来获取真正的文本高度，但是只操作显示文本的高度，那么我们就可以准确的获取到真正的文本原始高度了。

隐藏的文本要注意以下几点：

1. 文本脱离文档流，不能有任何占位
2. 行高以及宽度要与普通文本一致
3. `z-index` 必须为负值，不能影响可见文本的交互
4. 使用 `opacity` 进行隐藏

## 3. 代码实现

```tsx
import React, {useState} from 'react';
import {View, Text, StyleProp, TextStyle} from 'react-native';
import AntDesign from 'react-native-vector-icons/AntDesign';

interface IOverflowText {
  numberOfLines: number; // 超出该行数文字被隐藏
  linHeight: number; // 文字行高
  style?: StyleProp<TextStyle>; // 文字样式
  children?: string; // 文字内容
  onChange?: (hide: boolean) => void; // 当展开、隐藏状态切换时触发的函数
}

const OverflowText: React.FC<IOverflowText> = ({
  style,
  numberOfLines,
  linHeight,
  children = '',
  onChange,
}) => {
  const [hide, setHide] = useState<boolean>(true);
  const [isOverflow, setIsOverflow] = useState<boolean>(false);

  return (
    <View>
      <View>
        <Text
          numberOfLines={hide ? numberOfLines : undefined}
          style={[style, {lineHeight: linHeight}]}>
          {children}
        </Text>

        {/* 隐藏节点，用于判断文字真实高度 */}
        <Text
          onLayout={e => {
            const {height} = e.nativeEvent.layout;
            if (height - 1 < linHeight * numberOfLines) {
              setIsOverflow(false);
            } else {
              setIsOverflow(true);
            }
          }}
          style={{
            position: 'absolute',
            zIndex: -100,
            lineHeight: linHeight,
            opacity: 0,
          }}>
          {children}
        </Text>
        {/* 隐藏节点，用于判断文字真实高度 */}
      </View>
      {isOverflow ? (
        <AntDesign
          name={hide ? 'down' : 'up'}
          size={15}
          color={'#9F9F9F'}
          style={{textAlign: 'center', lineHeight: 30}}
          onPress={() => {
            const newValue = !hide;
            setHide(newValue);
            if (typeof onChange === 'function') {
              onChange(newValue);
            }
          }}
        />
      ) : null}
    </View>
  );
};

export default OverflowText;
```