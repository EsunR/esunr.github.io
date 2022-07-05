---
title: ECharts —— Pie 图自定义方案
tags:
  - Echarts
categories:
  - 前端
  - 可视化
date: 2020-07-23 10:05:35
---


# 1. Legend

在 Echarts 中，我们经常会出现设计师设计的 Legend 与实际 Echarts 自带的 Legend 不符的情况，这时候我们往往要重新自定义 Legend。

![](http://img.cdn.esunr.xyz/markdown/20200723101015.png)

## 1.1 自定义 icon

#### 修改 icon 类型

对于 icon 的修改，可以在 [legend.icon](https://echarts.apache.org/zh/option.html#legend.icon) 配置项下进行修改，其提供了一下几种基本样式：'circle', 'rect', 'roundRect', 'triangle', 'diamond', 'pin', 'arrow', 'none'，此外还允许用户使用 'image://url' 设置为图片，其中 URL 为图片的链接，或者 dataURI。

#### 为不同的数据设置不同的 icon 

如果我们想为不同类型的数据设置不同的 icon，那我们必须手动指定。首先我们要在 [legend.data](https://echarts.apache.org/zh/option.html#legend.data) 中使用 `legend.data.name` 明确指定每个 legend item 对应指定的数据，其次就可以使用 `legend.data.icon` 来指定每条数据的 icon 长什么样了。

## 1.2 自定义文本

#### 使用 formatter 格式化文本

对于文本格式，可以使用 [legend.formatter](https://echarts.apache.org/zh/option.html#legend.formatter) 来进行设置，其可以是字符串也可以是一个函数。

当我们使用字符串来进行设置时，可以使用 `{name}` 来获取到当前 legend item 指示的数据 name，如： `Legend {name}`。

当我们使用函数来进行设置时，就为我们提供了更丰富的操作空间。函数的参数即为当前 legend item 所指示的数据 name，凭借这个数据 name，我们可以在数据堆中找到对应数据，实现数据值的显示，甚至计算当前数据所占的百分比。

#### 文本样式

此时我们可使用 [legend.textStyle](https://echarts.apache.org/zh/option.html#legend.textStyle) 对文字的样式进行配置整体样式进行简单的配置。

但是仅仅配置整体样式有可能无法满足我们想要的操作，比如我们想要让 legend 文本的 name 部分显示为浅色，其数据部分显示为深色加粗，如下图所示：

![](http://img.cdn.esunr.xyz/markdown/20200723113439.png)

那么简单的使用 `textStyle` 只能指定全段文本的样式，无法将其分开定制样式。因此当需求更加复杂，我们想要操作更多的样式，那么就可以考虑使用 [legend.textStyle.rich](https://echarts.apache.org/zh/option.html#legend.textStyle.rich) 来使用富文本对文字进行格式配置，具体示例如下：

```js
legend: {
  formatter: [
      '{a|这段文本采用样式a}',
      '{b|这段文本采用样式b}这段用默认样式{x|这段用样式x}'
  ].join('\n'),
  textStyle: {
    rich: {
      a: {
          color: 'red',
          lineHeight: 10
      },
      b: {
          backgroundColor: {
              image: 'xxx/xxx.jpg'
          },
          height: 40
      },
      x: {
          fontSize: 18,
          fontFamily: 'Microsoft YaHei',
          borderColor: '#449933',
          borderRadius: 4
      },
    }
  }
}
```

#### 自定义 legend 的选中效果

默认情况下，legend item 选中后，`series（系列）` 中对应的数据就会在图例中消使，同时被选中的 legend 会呈现灰色的状态。我们可以使用 [legend.inactiveColor](https://echarts.apache.org/zh/option.html#legend.inactiveColor) 配置项来改变图例被关闭时的颜色。

但是需要注意，如果我们使用富文本样式，同时在富文本样式中对文字的颜色进行了设置，那么如果我们选中了对应的 legend item，其颜色就不会变灰，因此并不推荐使用富文本设置文字颜色。如果要设置颜色，请在 `legend.textStyle.color` 中进行设置。

## 1.3 使用 DOM 结构实现自定义 Legend

随着 Legend 的定制效果越来越复杂，我们其实可以放弃 echarts 内置的 legend，自己通过 DOM 结构来实现一个 legend。DOM 结构实现很简单，重点是怎么去与图表进行交互。

在原始的交互过程中，legend 无非两种状态，一种选中状态，一种取消状态，其控制了图表中的数据是否展示。我们可以通过外部创建一个 DOM 结构，获取其点击事件，通过在点击事件中改变  [legend.selected](https://echarts.apache.org/zh/option.html#legend.selected) 配置项来动态配置被选中的数据，这样就能模拟数据交互。

或者如果我们可以获取到 echarts 实例，我们就可以通过派发事件来模拟点击 legend。

再或者我们可以动直接态改 series 的数据本分来将图表中的数据直接移除或添加。

# 2. 显示效果

## 2.1 自定义鼠标移动到 Pie 图上时的高亮样式

当鼠标移动到 Pie 图上时，其会进入一个 `emphasis` 状态：

![](http://img.cdn.esunr.xyz/markdown/20200723134742.png)

我们可以通过 [series-pie.emphasis](https://echarts.apache.org/zh/option.html#series-pie.emphasis) 来配置这个高亮效果，其中支持了 `label`、`line`、`itemStyle` 这些配置项。

此外，对于 Pie 图来说，每条 data 中都可以使用 [series-pie.data.emphasis](https://echarts.apache.org/zh/option.html#series-pie.data.emphasis) 配置对应的 `emphasis` 效果。

## 2.2 选中状态

我们可以在 [series-pie.selectedMode](https://echarts.apache.org/zh/option.html#series-pie.selectedMode) 中选择开启饼图选中的显示效果，这个效果默认是关闭的，开启后用户鼠标单击饼图时饼图就会与原来的位置产生一个位移，如下：

![](http://img.cdn.esunr.xyz/markdown/20200723123449.png)

如果不开启 selectedMode 的话，可以通过 [series-pie.data.selected](https://echarts.apache.org/zh/option.html#series-pie.data.selected) 配置项来手动指定当前数据是否被选中。

如果想要自定义选中时显示的位移距离的话，可以使用 (series-pie.selectedOffset)[https://echarts.apache.org/zh/option.html#series-pie.selectedOffset] 配置项来指定位移量。