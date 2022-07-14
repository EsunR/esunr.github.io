---
title: npm 标准化发包方案调研
tags:
  - npm
  - cicd
categories:
  - 前端
  - 前端工程化
date: 2022-07-14 12:49:47
---

# 1. 传统的发包模式

## 1.1 版本发布

传统的发包模式指用户在本地进行发包、版本升级的操作，因此所有的 cli 都是在本地执行。当我们写好一个 npm package 之后，并且登录好 npm 后，就可以执行以下指令直接发布第一版：

```sh
npm publish --access public
```

## 1.2 版本迭代

当进行了一些变更之后，可以手动去变更 `package.json` 的版本号，当然这是一种非常低效且不优雅的做法，手动变更版本号存在太多不确定的因素，比如改错版本号或跳过某个版本号，因此我们需要一个更加『靠谱』的迭代版本号的方案。

### 1.2.1 npm 版本规范

在谈论如何优雅的进行迭代版本号之前，我们先来了解一下 npm 采用的[语义化版本号](https://docs.npmjs.com/about-semantic-versioning)：

npm 的语义化版本，共三位，以’.’隔开，从左至右依次代表：

- 主版本（major）
- 次要版本（minor）
- 补丁版本（patch）

举例来说：1(major).0(minor).0(patch)

当然有时某些包还存在预览版本，预览版本的版本号要与前三位版本号使用 `-` 进行间隔，如：

- 1.0.0-1
- 1.0.0-alpha.1
- 1.0.0-beta.1
- 1.0.0-rc.1

> `alhpa` / `beta` / `rc` 这些并不是 npm 官方定义的 prerelease 前缀，你可以使用任何前缀，甚至 `niconiconi`，如何添加这些前缀，我们后面会讨论到。

对于版本变更的规范，推荐采用以下策略：

| 代码状态             | 等级         | 规则                                           | 版本样例 |
| -------------------- | ------------ | ---------------------------------------------- | -------- |
| 首次发布             | 新品发布     | 以1.0.0开始                                    | 1.0.0    |
| bug 修复，向后兼容   | 补丁版本发布 | 变更第三位数字                                 | 1.0.1    |
| 新功能，向后兼容     | 次版本发布   | 变更第二位数字，并且第三位数字重置为 0         | 1.1.0    |
| 重大变更，不向后兼容 | 主版本发布   | 变更第一位数字，并且第二位和第三位数字重置为 0 | 2.0.0    |

### 1.2.2 使用 npm version 变更版本号

npm 提供了 [`npm version`](https://docs.npmjs.com/cli/v6/commands/npm-version) 指令可以辅助我们来进行版本迭代，假设我们现在的版本是 `1.0.0`，使用 `npm version` 的各个参数进行版本升级，得到的结果如下：

对于一般的迭代，使用 `major` / `minor` / `patch` 即可：

- npm version major => 2.0.0
- npm version minor => 1.1.0
- npm version patch => 1.0.1

如果你要发布预览版本（prerelease）的 package，你可以使用 `premajor` / `preminor` / `prepatch` 并结合 `prerelease` 来升级预览版本号：

- npm version premajor => 2.0.0-0 `发型一版重大变更预览版本的 package`
	- npm version prerelease => 2.0.0-1 `增加当前预览版本的版本号`
		- npm version major => 2.0.0 `正式发布`
- npm version preminor => 1.1.0-0
	- npm version prerelease => 1.1.0-1
		- npm version minor => 1.1.0
- npm version prepatch => 1.0.1-0
	- npm version prerelease => 1.0.1-1
		- npm version patch => 1.0.1

如果你想为预览版的版本号添加 `alpha` / `beta` 这样的前缀的话，可以使用 `--preid` 参数，我们依旧以 `1.0.0`  为初始版本，使用 `npm version` 进行预览版的版本变更示例如下：

- npm version prepatch --preid alpha => 1.0.1-alpha.0
	- npm version prerelease  => 1.0.1-alpha.1
		- npm version patch --preid alpha => 1.0.1 `⚠️ 如果要发布当前 preid 的正式版，执行正式版并发布指令时需要后缀 --preid 参数`
		- npm version patch => 1.0.2 `如果不后缀就会直接迭代到下一版本`
		- npm version prepatch --preid beta => 1.0.2-beta.1 `如果切换了 preid 就会重新生成一个新版本，而不是在当前版本迭代版本号`

需要注意的是，当你执行 `npm version` 指令时，当前的工作区必须是干净的，否则会执行失败；且当执行成功后，会自动生成一个 commit（commit message 默认为版本号），同时在这次自动生成的 commit 上打一个 tag，tag 名称即为以 `v` 开头的版本号名称，如果你想修改默认的 commit message，你可以使用如下指令：

```sh
npm version patch -m "Release version %s" # 『%s』代表当前版本号
```

此外，对于你发布的 prerelease 版本的 package 需要注意以下两点：

1. 当用户进行首次安装你的包时，且此时你的包最新的版本为一个 prerelease 版本，那么用户就会安装这个 prerelease 版本；如果用户只想安装稳定版，那么可以通过 `npm install xxx@version`，比如 `npm install xxx@1` 或 `npm install xxx@">1.0.0"` 这样的指令安装的包不会安装到 prerelease 版本。
2. 但是，当用户当前安装的是一个正式版本的包时，使用 `npm update` 去更新你的包，是不会主动更新到 prerelease 版本的；但如果正式版用户想要升级为 prerelease 版，可以通过执行 `npm install package@latest` 来安装最新的版本（包含预览版）。

# 2. 使用 standard-release