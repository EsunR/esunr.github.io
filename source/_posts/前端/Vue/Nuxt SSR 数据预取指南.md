---
title: Nuxt SSR 数据预取指南
tags:
  - Nuxt
  - SSR
  - Vue
categories:
  - 前端
  - Vue
date: 2025-12-03 16:17:20
---
# 1. 使用 useAsync 调用请求函数进行预取

`useAsyncData` 的作用是在 SSR 阶段将异步函数（通常是一个数据预取接口）的返回结果挂载到 Window 上的一个变量中，从而在 CSR 阶段可以读取到 SSR 阶段获取的数据（此外他也可以阻塞 Vue 组件的 setup 阶段）。

在 Nuxt 的官方文档演示中，对于数据预取使用了 [`useFetch`](https://nuxt.com/docs/4.x/api/composables/use-fetch) 进行演示：

```ts
const param1 = ref('value1')
const { data, status, error, refresh } = await useFetch('/api/modules', {
  query: { param1, param2: 'value2' },
})
```

这个函数其实是 [`useAsyncData`](https://nuxt.com/docs/4.x/api/composables/use-async-data) 和 [`$fetch`](https://nuxt.com/docs/4.x/api/utils/dollarfetch) 的顶层封装版本。但是在大型项目中，我并不推荐用这个方法，理由如下：
- 我们对请求函数可能有更多的定制化需求，比如不用 nuxt 默认提供的 `$fetch`，想改用 Axios 或者自定义的请求方法，这时候你就必须再写一个插件覆盖掉 `$fetch`；
- `useFetch` 提供的参数不足以满足我们的业务场景；
- 我们想自己封装一个接口级别的请求函数，比如获取列表 `fetchList`，SSR 侧的请求和 CSR 侧的请求都想通过调用这个函数来请求列表，如果我们使用 `useFetch` 就无法将 SSR 请求和 CSR 请求的共用部分进行抽离；

因此我更推荐使用 `useAsyncData` 来直接请求数据，这样可以让我们更多的复用 Ajax 请求函数，示例如下：

```ts
// 随意实现的请求函数，摆脱 $fetch 和 oFetch
import { request } from "request";

const page = ref<number>(1);

function getList(params: ListReq) {
	return request<ListRes>('/api/list', {params});
}

// prefetchListData 就是服务端预取到的数据
const {data: listData} = useAsyncData("list-data", () => {
	return getList({page: 1});
})

// 请求翻页时候就可以直接调用这个函数
function onReuqstNextPage() {
	page.value += 1;
	const nextPageList = getList({page: page.value});
	listData.value.concat(nextPageList);
}
```

如果使用 useFetch 就会成为下面这片光景：

```ts
// 随意实现的请求函数，摆脱 $fetch 和 oFetch
import { request } from "request";

const page = ref<number>(1);

// prefetchListData 就是服务端预取到的数据
const {data: listData} = useFetch<ListRes>(
	"/api/list",
	{page: 1} as ListReq
)

// 请求翻页时候就可以直接调用这个函数
function onReuqstNextPage() {
	page.value += 1;
	const nextPageList = await request<ListRes>(
		'/api/list',
		{page: page.value} as ListReq
	);
	listData.value.concat(nextPageList);
}
```

这种方式对接口的请求路径函数参数类型的复用非常不友好，如果接口请求路径发生改变，就需要零散的修改多个地方，因此所以**完全不推荐**。

# 服务端异常的处理

# 客户端重试