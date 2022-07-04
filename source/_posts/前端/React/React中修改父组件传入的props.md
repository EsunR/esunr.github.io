---
title: React中修改父组件传入的props
tags:
  - React
categories:
  - 前端
  - React
date: 2019-07-29 20:51:52
---
# 需求场景

当我们在父组件中调用子组件时，通常会将**父组件的 state 数据**，传递给**子组件的 props 属性**中，但是我们通常无法在子组件内改变外部传入的 props 属性，进而改变父组件的 state 属性。

这时 `react-link-state` 组件可以帮助我们。

# 使用方法

引入：

```javascript
import linkState from 'react-link-state';

```

在父组件中设置子组件时，指定要关联的 state

```javascript
class Fater extends React.Component {
    constructor(props){
        super(props);
        this.state = {
            data: 'value'
        }
    }
    render(){
        return (
            <div>
             ...
             <Son
                sonData={linkState(this, 'data')}
             />
             ...
             </div>
        )
    }
}

```


在子组件中改变父组件传入的props:

```javascript
class Fater extends React.Component {
    constructor(props){
        super(props);
    }

    handelChange(){
        this.props.sondata.requestChange('newData')
    }

    render(){
        return (
            <div onClikc={handelChange}>
             {this.props.sonData.value}
            </div>
        )
    }
}

```


# 原理

`linkState()` 方法可以将父组件的 state 中的数据转化为一个 object，其含内部包含两个结构

*   `value` 用来存放源数据
*   `requestChange()` 方法则是用于请求改变父组件的 state 数据

这样我们就可以访问这个 object 来进行对应的数据获取和数据更改操作。