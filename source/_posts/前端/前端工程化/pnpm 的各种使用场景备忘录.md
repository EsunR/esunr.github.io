---
title: pnpm 的 workspace 管理
tags:
  - pnpm
  - npm
categories:
  - 前端
  - 前端工程化
date: 2024-06-17 10:53:37
---
吐槽：pnpm 文档真的是一个大版本一个不一样，workspace 的管理指令都变了好几次了，每次都要重新查找，因此在这里写一个备忘，防止 pnpm 挖坑。

# 如何添加 workspace

在根目录创建 `pnpm-workspace.yaml`。

[官方文档](https://pnpm.io/workspaces)

# 如何指定在某个工作区执行 install、run 等指令

pnpm@9：使用 `--filter`，如：

```sh
pnpm --filter workspace_name run dev
pnpm --filter ./path/to/package run dev # 一定要带 `./` 使用相对路径
```

此外还可以使用 `-C` 来选中 workspace（这个方式是旧版本的 pnpm 使用的，目前已经不在官方文档中了）：

```sh
pnpm -C path/to/workspace # md，这里又可以不用 `./` 写相对路径
```

亦或者直接从 packages 目录下执行：

```sh
./path/to/package pnpm run dev
```