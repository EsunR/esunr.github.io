> 参考视频：https://www.youtube.com/watch?v=wm5gMKuwSYk

# 前言

NextJS 优势：

- 服务端渲染
- 基于文件系统的路由（无需 ReactRouter）
- API Routes
- 自动代码分割
- 搜索引擎优化

安装 NextJS：https://nextjs.org/docs/getting-started/installation

服务端组件与客户端组件的使用场景：https://nextjs.org/docs/getting-started/react-essentials#when-to-use-server-and-client-components

# 服务端组件与客户端组件

## 什么是服务端组件？

React 18 一个很重要的路线目标就是 **服务端组件**（React Server Component，简称 RSC），其设想为 **让不需要交互的组件可以直接在服务端进行渲染**，从而让应用拥有更好的用户体验、性能、可维护性。

传统的客户端组件我们都应该很熟悉，当用户访问页面时，加载服务端返回的 JavaScript 脚本，从而生成页面，所有 DOM 节点的生成、计算以及数据的获取都是在客户端完成的。而 RSC 的思路则是让组件在服务端进行渲染（RSC 在服务端的渲染不是生成 HTML 而是生成一个序列化结构），把 DOM 计算、数据获取这些耗时的行为在服务端就生成好，然后在客户端需要的时候（比如加载到某个页面、异步组件）就返回给客户端。

因为 RSC 是运行在服务端渲染的，因此拥有服务端的能力，比如直接使用文件 IO 读取文件、连接数据库进行 SQL 查询等，这些都能让 RSC 比客户端组件更快的获取数据从而更快的生成页面结构。

如果你想要了解更多 RSC 的内容，可以了解一下 RSC 的研发时间线：

- 2020 年末，React 发布了第一个 RSC 演示，展示了服务端组件的应用场景以及能力。[链接](https://legacy.reactjs.org/blog/2020/12/21/data-fetching-with-react-server-components.html)
- 2022 年 6 月 15 日，React 提出了更多的设计细节。[链接](https://react.dev/blog/2022/06/15/react-labs-what-we-have-been-working-on-june-2022)
- 2023 年 3 月 22 日，React 更新了 RSC 的声明规范 ，并报告了当前的进度。[链接](https://react.dev/blog/2023/03/22/react-labs-what-we-have-been-working-on-march-2023)
- 2023 年 5 月 4 日，Next.js 宣布 App Router 模式发布稳定版本，并鼓励开发者默认使用 App Router。[链接](https://nextjs.org/blog/next-13-4)

## RSC vs SSR

在没有深入了解 RSC 时，可能会与 SSR 混淆，因为他们都是在服务端进行渲染，同样都有服务端的能力以及优势，但实际上他们是完全不同的两种技术，主要有以下的区别：

- RSC 与 SSR 是两种互补的技术，并不存在谁更好，他们都有各自的应用场景，并且可以混合使用。Next.js 13 在 App Router 模式下，会同时对 RSC 以及客户端组件进行服务端渲染（[参考](https://nextjs.org/docs/getting-started/react-essentials#composing-client-and-server-components)）。
- RSC 在服务端返回的是一个序列化的数据，需要在客户端进行解析；而 SSR 返回的则是组件渲染好后的 HTML。
- RSC 仅在服务端渲染，当 RSC 需要重新渲染时，就需要从服务端重新获取并合并到现有的客户端 React 组件树中；而 SSR 渲染的组件返回到客户端时会进行客户端激活（也成为水合 hydration），激活后的组件后续的渲染与更新都是在客户端进行的。
- RSC 强调组件必须是没有任何交互，意味着组件不能使用 `useState`、`useEffect` 这些 Hook；而 SSR 没有这些限制，hook 是可以在服务端运行的。
- RSC 能够有效的减小包的大小， RSC 的依赖包尽在服务端执行，因此不会将代码打包到客户端中；而 SSR 则是服务端与客户端都需要组件所引用到的依赖包，因此必须将依赖打包在客户端 bundle 中。

> Next.js 默认会将服务端组件与客户端组件都在服务端进行渲染，在客户端激活

## 服务端组件与客户端组价的使用场景

在 Next.js 中，默认所有的组件都是服务端组件，可以在文件顶部使用 `"use client";` 强行将组件转为客户端组件。下面的表格为官方总结的使用客户端组件和服务端组件的场景：

| 你需要做什么？                                                                  | 服务端组件 | 客户端组件 |
| ------------------------------------------------------------------------------- | ---------- | ---------- |
| 获取数据                                                                        | ✓          | ×          |
| 直接访问后端资源                                                                | ✓          | ×          |
| 使用需要在服务端保密的资源（access token、API Keys 等）                         | ✓          | ×          |
| 想要减少客户端的组件打包体积                                                    | ✓          | ×          |
| 使用交互式的事件监听器（onClick, onChange 等）                                  | ×          | ✓          |
| 组件逻辑依赖状态或者生命周期函数（useState、useEffect 等），或使用了自定义 Hook | ×          | ✓          |
| 使用浏览器 API                                                                  | ×          | ✓          |
| 使用 Class 组件                                                                 | ×          | ✓           |

## Next.js 对服务端组件的优化

Next.js 会始终尝试对页面进行[『静态化』](https://nextjs.org/docs/app/building-your-application/rendering/static-and-dynamic-rendering#static-rendering-default)，当我们在服务端组件获取数据时，Next.js 的默认处理方式类似于 Pages Router 中的 `getStaticProps`，举例来说，假如我们编写了下面这样一个组件：

```jsx
export default async function HomePage() {
  const homeSoundList = await getHomeSounds();

  return (
    <div>
      { homeSoundList.map(sound => <HomeSound sound={sound} />) }
    </div>
  );
}
```

那么当我们编译应用时，Next.js 会在编译阶段就会尝试调用 `getHomeSounds()` 方法并将返回的数据进行缓存，从而避免在服务端重复调用该接口。同时，Next.js 还会尝试静态生成该页面，如果组件没有使用动态函数与动态路由，那么 Next.js 会将页面生成为静态的 HTML，并在每次客户端请求时返回该 HTML。

https://nextjs.org/docs/app/api-reference/file-conventions/route-segment-config#dynamic