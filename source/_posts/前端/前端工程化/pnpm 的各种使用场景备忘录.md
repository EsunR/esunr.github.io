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

# pnpm link

`pnpm link --global` 会将当前的包软链接到全局的 pnpm 存储目录下（pnpm 的全局存储目录可以通过 `pnpm store path` 获取），用于在本地开发一个包时进行调试。

在目标项目中，使用 `pnpm link --global <package name>` 来安装刚才链接到全局的包，但是注意该包并不会在 package.json 中体现，只能在 node_modules 目录下看到该软链。

如果向在目标项目中移除通过 `link` 安装的包，则使用 `pnpm unlink`，pnpm 会删除当前项目使用 `link` 创建的软链。

如果想要移除本地包在 pnpm 全局存储目录下的链接，可以使用 `pnpm uninstall <package name> --global` 来删除。

> 注意，如果项目使用了 webpack 进行构建，[`resolve.syslinks`](https://webpack.js.org/configuration/resolve/#resolve-symlinks)  会导致软链按照真实路径进行包查找，导致依赖包无法被正常索引到，但是关了 syslinks 又会导致 pnpm 的软链逻辑时效，啥也不是。
