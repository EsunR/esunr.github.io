---
title: ts-node 在某些 Nodejs 版本中报错 Unknown file extension
tags:
  - Typescript
  - NodeJS
  - ts-node
categories:
  - 前端
  - 前端工程化
date: 2024-07-17 16:19:07
---
表现：使用 ts-node 执行 esm 规范的模块时报错：

```sh
TypeError [ERR_UNKNOWN_FILE_EXTENSION]: Unknown file extension ".ts" for /../../xxx.ts
```

修改 `tsconfig.json` 后仍然无法正常运行。

解决方案：

- 切换 Node 版本；
- tsconfig 配置 targte 目标为 commonjs，并删除 `package.json`  中的 `type: module`；

关联 Github issue https://github.com/TypeStrong/ts-node/issues/2100