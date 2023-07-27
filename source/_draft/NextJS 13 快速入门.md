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

### 服务端组件与客户端组件

2020 年末，React 发布了第一个 React Server Component（简称 RSC）[演示](https://www.youtube.com/watch?time_continue=23&v=TQQPAU21ZUw&embeds_referring_euri=https%3A%2F%2Flegacy.reactjs.org%2F&source_ve_path=Mjg2NjY&feature=emb_logo)，展示了服务端组件的应用场景以及能力。在不断迭代后，NextJS 13 在 2023 年 5月份正式将 RSC 构建的 App Router 模式作为默认推荐的开发模式，替代了原有的 Page Router，拥有更好的表现型以灵活性，标志着官方已正式推荐使用 RSC 来搭建应用。

RSC 对比与传统的客户端组件来说，其是在服务端进行渲染
