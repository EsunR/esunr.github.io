---
title: 使用 Element UI Select 组件的 value-key 属性，让绑定值可以为一个对象
tags:
  - ElementUI
categories:
  - 前端
  - Vue
date: 2019-11-07 22:29:53
---
当我们使用 Elemet UI 的选择组件进行多选时，Select 组件的绑定值是一个数组，但是数组的值只能传入 Number 类型或者 String 类型的数据，如果我们想向其中传入一个对象就会出错，如：

```html
<template>
	<el-select v-model="permissionList" multiple placeholder="请选择">
		<el-option v-for="item in groups" :key="item.groupID" :label="item.name" :value="item" />
	</el-select>
</template>

<script>
export default{
	data() {
		return {
			permissionList: [],
			groups: [{
				id: 1,
				name: 'A组',
				permission: 'Write'
			},{
				id: 2,
				name: 'B组',
				permission: 'Write'
			},{
				id: 3,
				name: 'C组',
				permission: 'Write'
			}]
		}
	}
}
</script>
```

但是这样组件在选择的时候就会出错：

![在这里插入图片描述](https://img-blog.csdnimg.cn/2019110712074016.png)

同时，控制台报错：

```
vue.runtime.esm.js:619 [Vue warn]: <transition-group> children must be keyed: <ElTag>
```

我们可以发现其为缺少一个索引，翻查 elemnet-ui 的文档，可以查阅到 Select 组件有一个属性：

![在这里插入图片描述](https://img-blog.csdnimg.cn/20191107121013628.png)
那么，我们可以为其添加一个索引的属性，这个 value-key 即为我们绑定对象的唯一标识符，如在上述的例子中，这个标识符为 `groupID`

所以可以将上面的代码改动为：

```diff
<template>
	<el-select 
		v-model="permissionList" 
		multiple 
		placeholder="请选择"
+		value-key="groupID"
	>
		<el-option v-for="item in groups" :key="item.groupID" :label="item.name" :value="item" />
	</el-select>
</template>
```