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

当进行了一些变更之后，可以手动去变更 `package.json` 的版本号，当然这是一种非常低效且不优雅的做法，手动变更版本号存在太多不确定的因素，比如改错版本号或跳过某个版本号；同时，一般我们在生成一个新的版本后要打一个 tag 对当前版本进行留档，纯手动操作的话会有很多的工作量。因此我们需要一个更加『靠谱』的迭代版本号的方案。

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

需要注意的是，当你执行 `npm version` 指令时，**当前的工作区必须是干净的**，否则会执行失败；且当执行成功后，会自动生成一个 commit（commit message 默认为版本号），**同时在这次自动生成的 commit 上打一个 tag**，tag 名称即为以 `v` 开头的版本号名称，如果你想修改默认的 commit message，你可以使用如下指令：

```sh
npm version patch -m "Release version %s" # 『%s』代表当前版本号
```

此外，对于你发布的 prerelease 版本的 package 需要注意以下两点：

1. 当用户进行首次安装你的包时，且此时你的包最新的版本为一个 prerelease 版本，那么用户就会安装这个 prerelease 版本；如果用户只想安装稳定版，那么可以通过 `npm install xxx@version`，比如 `npm install xxx@1` 或 `npm install xxx@">1.0.0"` 这样的指令安装的包不会安装到 prerelease 版本。
2. 但是，当用户当前安装的是一个正式版本的包时，使用 `npm update` 去更新你的包，是不会主动更新到 prerelease 版本的；但如果正式版用户想要升级为 prerelease 版，可以通过执行 `npm install package@latest` 来安装最新的版本（包含预览版）。

## 1.3 CHANGELOG 的生成

在一些项目中，会用 `CHANGELOG.md` 来标注每个版本的变更内容，这个文件通常是使用专门的工具生成的，比如 [conventional-changelog](https://github.com/conventional-changelog/conventional-changelog)，但是自动生成的条件必须满足：

1. 使用标准的 commit 规范，通常在默认情况下使用 [Angular 的提交规范](https://github.com/angular/angular.js/blob/master/DEVELOPERS.md#-git-commit-guidelines)，这样 `conventional-changelog` 就会知道你每次提交做了什么，是新增了一个 fetature，还是修复了一些 bug，亦或是其他。你可以使用 `@commitlint/cli` + `husky` 对你的代码进行提交检查，同时也可以使用 `commitizen` 来生成标准化的 commit，关于这些，你可以参考[这篇文章](https://blog.esunr.xyz/2022/07/72bea7fe8c23.html#3-CommitLint)。
2. 在每次生成一个新的版本后，在当前的提交上要创建一个 tag，tag 的名称为版本号，比如 `v1.0.0`，这点如果你使用 `npm version` 来生成版本号的话就无需担心这一点。

一个标准的 commit 历史如下：

```
commit xxxxxxx (tag: v1.1.0)
Author xxx
Date   xxx
1.1.0

commit xxxxxxx
Author xxx
Date   xxx
fix: fix a bug

commit xxxxxxx
Author xxx
Date   xxx
feat: add new fetaure 2

commit xxxxxxx
Author xxx
Date   xxx
feat: add new fetaure 1

commit xxxxxxx (tag: v1.0.1)
Author xxx
Date   xxx
1.0.1

commit xxxxxxx
Author xxx
Date   xxx
fix: fix a bug

commit xxxxxxx (tag: v1.0.0)
Author xxx
Date   xxx
1.0.0

commit xxxxxxx
Author xxx
Date   xxx
feat: base function

commit xxxxxxx
Author xxx
Date   xxx
chore: first commit
```

`conventional-changelog` 读取到这样的 commit 历史后，就可以生成如下的 CHANGELOG：

```markdown
## 1.0.1 (2022-xx-xx)


### Bug Fixes

* fix a bug

### Features

* add new fetaure 1
* add new fetaure 2

## 1.0.1 (2022-xx-xx)


### Bug Fixes

* fix a bug

## 1.0.0 (2022-xx-xx)


### Features

* base function
```

如果你的 commit 符合以上两点要求，你可以安装 `conventional-changelog-cli`：

```sh
npm install conventional-changelog-cli -D
```

运行 cli 指令生成 CHANGELOG：

```sh
npx conventional-changelog -p angular -i CHANGELOG.md -s -r 0
```

之后版本变更后想生成新的 CHANGELOG 就只需要再执行一遍上面的指令即可。但是还有一种更简便的方式，就是使用 npm 的 `version` 钩子来在更新版本号时候自动触发 CHANGELOG 生成，只需要在 `package.json` 中添加以下 script：

```json
"scripts": {
  "version": "conventional-changelog -p angular -i CHANGELOG.md -s && git add CHANGELOG.md"
}
```

添加之后，在我们执行 `npm version` 时，一旦版本号变更成功就会触发 `version` script 生成 CHANGELOG，并将生成的 `CHANGELOG.md` 添加到暂存区，然后 `npm version` 继续执行，暂存区的代码进行提交，并创建一个 tag。

**总之，将所有的流程配置好之后，完整的工作流如下：**

1. 编辑代码，添加新功能或者修复 bug；
2. 完成某个功能后进行 commit，commit 要符合[Angular 的提交规范](https://github.com/angular/angular.js/blob/master/DEVELOPERS.md#-git-commit-guidelines)；
3. 继续完成其他的功能，并每完成一个功能后及时提交标准化的 commit，直到你想要发版为止；
4. 执行 `npm version xxx` 生成新的版本号，这时 CHANGELOG 和版本号都会自动进行迭代；
5. 执行 `npm publish --access public` 进行版本发布。

# 2. 使用 standard-version

[standard-version](https://github.com/conventional-changelog/standard-version) 是 conventional-changelog 推荐使用的标准化 npm 版本生成工具，它可以取代 `npm version` 指令，并提供更简便、语义化的调用方式；

同时，它也集成了 conventional-chagelog，在生成版本号时会自动创建 CHANGELOG，可以省去我们自己配置 conventional-chagelog-cli 的过程；

此外它还提供了配置文件，你可以很方便的自定义 CHANGELOG 的输出。

## 2.1 安装

standard-version 可以安装到全局来替代 `npm version` 指令，但最好还是安装到本地项目中，使用 `npx` 指令来执行它：

```sh
npm install standard-version -D
```

## 2.2 使用

使用 standard-version 的前提还是要有标准化的 commit 链，就像上面我们在 CHANGELOG 生成中所描述的那样。当你完成了一系列的代码变更后，就可以执行 `npx standard-version` 来生成一个版本（如果是首次发布则需要执行 `npx standard-version --first-release`），执行之后 standard-version 会做如下的事情：

1. 读取 `package.json` 查询当前包的版本号，如果没有查询到，就将最后一个 tag 的版本号视作当前的版本号；
2. 依据你的 commit 信息，来决定下一个版本号（这一过程被称为 `bump version`），然后修改 `package.json`、`package-lock.json` 等需要迭代版本号的文件中的版本号字段；
3. 依据你的 commit 信息生成或更新 `CHANGELOG.md` 文件；
4. 使用新的版本号为名称，创建一个 tag 进行留档。

在使用 `npx standard-version` 来迭代版本时，你无需关心是迭代 major、minor、patch 位的版本号，`standard-version` 会自动根据你的版本号