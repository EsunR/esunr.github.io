---
title: 使用 volta 与 corepack 规范团队在不同项目中使用的 node 版本与 npm 包管理器
tags:
  - npm
  - volta
  - node
  - corepack
categories:
  - 前端
  - 前端工程化
date: 2023-07-06 18:22:39
---

# 0. 前言

在前端开发团队中，经常存在多个新老项目同时开发的情况，这些项目他们的 node 版本可能不一样，项目中所使用的包管理器也不一样。比如一些老的项目可能使用低版本 node 并使用 npm 安装项目依赖，而一些新的项目则会使用高版本 node 与 pnpm/yarn 来安装项目依赖。

如果 node 版本不统一，带来的问题可能就是整个项目无法运行；而如果包管理器不统一，带来的则可能是 `package-lock.json`、`yarn.lock`、`pnpm-lock.yaml` 在每个成员电脑上都不一致的灾难。

> 之所以是灾难，因为很多项目本地明明运行的好好的，然而在其他人电脑上或者线上却无法正常运行，这都很有可能是因为 lock 文件没有对其导致安装了错误版本的依赖包！

为了解决这个问题，本文将向你展示如何同时使用 volta 和 corepack 来管理 node 版本与包管理器版本的问题，团队只需要准备相同的环境，并对当前的项目进行简单改造，就可以实现在每个项目中自动切换 node 版本与包管理器版本！

# 1. Volta

Volta 官网描述为一款无障碍的 JavaScript 工具管理器，与 nvm、n 类似的，可以用来管理 Node 版本，但同时又有以下优势：

- 可以根据项目 `package.json` 声明的 volta 配置来根据不同的项目自动切换 node 版本；
- volta 也可以直接管理 pnpm 与 yarn（不推荐，建议如果使用高版本的node，使用后面的 corepack 来管理包管理器）；
- 当使用 volta 安装的 node 来执行全局安装时，切换 node 版本后，全局安装的包仍然存在，并且其运行时所依赖的 node 版本会被固定为安装该包时使用的 node 版本；

## 1.1 安装

volta 安装只需要执行一行命令：

```sh
curl https://get.volta.sh | bash
```

之后便可以使用 volta 来安装不通版本的 node：

```sh
volta install node@18
```

> 若想要切换 node 版本，也只需使用 `volta install` 指令即可

你可以使用 `volta list all` 查看当前 volta 所已经安装的内容：

```
⚡️ User toolchain:

    Node runtimes:
        v14.21.3 (default)
        v16.20.1
        v18.16.1
        v20.3.1

    Package managers:


    Packages:
        serve@14.2.0 (default)
            binary tools: serve
            platform:
                runtime: node@14.21.3
                package manager: npm@built-in
```

这些内容分为三部分：

- Node runtimes：你已经安装的 node 版本，显示 default 即为你当前全局使用的 node 版本；
- Package managers：你已经安装的包管理器（这一部分的管理与 corepack 冲突，后面再具体讨论）；
- Packages：使用 `npm install --global` 安装的全局包，volta 会在此列出，并固定其运行时版本；

## 1.2 使用 volta 管理项目依赖的 node

假如你之前使用的是 nvm，如果你想要为不通的项目来规范 node 版本，那么需要在项目目录通过创建 `.nvmrc` 写入 node 版本，并要求开发者在进入项目时使用 `nvm use` 来对其当前使用的 node 版本。这个操作如果想要自动化，就需要编写一个自动化脚本来实现（[参考](https://stackoverflow.com/questions/57110542/how-to-write-a-nvmrc-file-which-automatically-change-node-version)）。

但是对于 volta 来说，这个步骤是及其简单并且完全自动化的。当要求全团队使用 volta 后，可以直接在项目目录（package.json 的目录下）使用如下指令，将当前项目所使用的 node 版本固定为 node v18 的 LTS 版本：

```sh
volta pin node@18
```

之后，你就会发现项目的 package.json 中被添加上一段：

```json
"volta": {
	"node": "18.16.1"
}
```

之后当用户进入到当前项目中时，volta 就会检测到 package.json 中声明的 node 版本，并且切换至该 node 版本。

## 1.3 volta 卸载不使用的 node 和包管理器

当你尝试使用 `volta uninstall yarn` 或者 `volta uninstall node` 时，会出现暂无法支持卸载的提示：

```sh
error: Uninstalling node is not supported yet.
```

因此需要到 `~/.volta/tools/image` 手动删除已经下载的 npm 或者 yarn 等，[参考](https://github.com/volta-cli/volta/issues/1431#issuecomment-1409424063)。

## 1.4 volta 的原理

volta 的原理并不复杂，本质上就是通过覆写二进制文件的执行指令到 volta 的处理程序中，然后 volta 就可以调用正确的 node 版本，或者调用全局安装的二进制文件并为其指定 node 版本。

我们可以使用 `which node` 来查看以下 node 的执行位置，会发现其执行位置为用户目录下的 `.volta/bin/node` 中。

我们在来查看一下全局安装的包，比如我们使用 `npm install serve -g` 安装的 `serve` 指令，调用 `which serve` 可以发现其执行位置同样为 `~/.volta/bin` 目录。

我们切换到该目录后，就可以查看到这些可执行文件：

```
node npm npx serve volta volta-migrate volta-shim
```

可以发现，我们通过全局安装指令安装的二进制文件会被放到这个位置，node 和 npm 的执行文件也在这个位置。但实际上另有玄机，我们可以使用 `ls -l` 查看一下文件的详细信息：

```
total 37008
lrwxr-xr-x  1 username  staff    39B Jul  4 14:49 node -> /Users/username/.volta/bin/volta-shim
lrwxr-xr-x  1 username  staff    39B Jul  4 14:49 npm -> /Users/username/.volta/bin/volta-shim
lrwxr-xr-x  1 username  staff    39B Jul  4 14:49 npx -> /Users/username/.volta/bin/volta-shim
lrwxr-xr-x  1 username  staff    39B Jul  5 19:12 serve -> /Users/username/.volta/bin/volta-shim
-rwxr-xr-x  1 username  staff   7.3M Jan 25 05:38 volta
-rwxr-xr-x  1 username  staff   4.4M Jan 25 05:37 volta-migrate
-rwxr-xr-x  1 username  staff   6.4M Jan 25 05:37 volta-shim
```

这些可执行的二进制文件都被使用连接符软连接到了 `volta-shim` 这个可执行文件上去。

因此 volta 背后自动切换 node 版本以及管理全局包的魔法实际上就是：当使用 Volta 时，npm、node以及其他全局包的这些二进制文件被重定向到 `.volta/bin` 目录下的对应可执行文件，而这些可执行文件实际上都是 `.volta/bin/volta-shim` 所创建的软连接。 volta-shim 本身是一个特殊的脚本，他主要做了如下这些事情：

- 如果是 node、npm、yarn 等指令，监测当前工作控件是否被 `volta pin` 指定了 node 版本和包管理器的版本，如果是，则将指令定向到目标版本；
- 如果是 serve 这种由 npm 安装的可执行文件，则定向到该可执行文件，并且**使用安装该可执行文件时的 node 版本** 来执行该指令。

# 2. Corepack

> 注意：corepack 只适用于 node@16.9.0 以上的版本，如果你的团队 node 版本低于此版本，同时项目又使用了 yarn/pnpm 来进行包管理，那么使用 corepack 可能存在问题，可以考虑使用 volta 的包管理器的管理功能。如果非要使用，可以参考 3.3 节中的方案。

corepack 是 node 官方出的一个管理 node 包管理器的管理器，其已经内置于 node@20 版本中，与 npm 一样作为被默认安装的指令工具，但默认没有被启用。

其诞生背景是因为 npm 本身的不思进取，导致社区出现了 yarn、pnpm 这些更优秀的包管理器工具，然而这些包管理器工具在不同的项目中又有可能使用不同的版本，因此规范项目中使用的包管理器也和规范项目所使用的 node 版本一样重要。

> 毕竟在团队中，谁都不想 lock 文件在每个人的电脑上都有各自的版本！

## 2.1 安装

如果你的团队使用的是 node@20，那么 corepack 指令则已经被默认安装。如果你是用的是其他版本的 node（最低 node@16.9.0），则需要手动执行 `npm install corepack -g` 来安装。

安装后的 corepack 默认是被禁用的，如果你想要启用 corepack 则需要先卸载全局安装的包管理器：

```sh
npm uninstall yarn -g
npm uninstall pnpm -g
```

然后执行：

```sh
corepack enable
corepack prepare --all
```

首先，corepack 会被启用，在你的 `/usr/local/bin/` 目录下创建 pnpm、pnpx、yarn、yarnpkg 这几个可执行文件，让你可以使用 pnpm 和 yarn 的指令。实际上，这些指令也是一个软连接，会连接到 corepack 的处理程序（其实与 volta 的原理类似），以让 corepack 可以使用正确的包管理器版本；

之后使用 `corepack prepare --all` 指令会下载最新的 pnpm 和 yarn 的稳定版，此时你就可以正常在全局使用 yarn 和 pnpm 了。

如果你想切换全局安装的 pnpm 和 yarn，可以使用下面的指令：

```sh
# 将全局使用 pnpm 版本切换到 pnpm@6.35.1
corepack prepare pnpm@6.35.1 --activate
```

> 注意：corepack 指定包管理器版本的时候必须使用 @x.y.x 来明确三位版本号

## 2.2 使用 corepack 管理项目使用的包管理器

与 volta 类似的，corepack 也是通过识别项目 package.json 中声明的配置来自动切换包管理器的，但需要手动添加：

```json
{
  "packageManager": "pnpm@8.6.6"
}
```

这样，就成功指定了项目使用的 pnpm 版本为 `8.6.6`，当我们使用 `pnpm` 指令的时候，corepack 会自动安装对应版本，并调用改版本。

此外，如果读取到有效的 packageManger 配置，corepack 还会阻止用户使用错误的包管理器来安装，比如如果用户在上面配置的项目中使用 `yarn install`，那么就会出现报错：

```
Usage Error: This project is configured to use pnpm

$ yarn ...
```

> corepack 默认不会托管 npm，也不建议这么做（因为 node 版本与 npm 版本已经强绑定了），因此不会拦截 `npm install` 的指令

# 3. Volta 与 Corepack 结合使用

## 3.1 为什么非要使用 Corepack ？

当你看到这里可能会有疑问，volta 本身是支持同时管理 node 与包管理器，但为什么还要使用 corepack？那么我只能说 **volta 本身的包管理是有缺陷的，而 corepack 是未来**。

使用 corepack 已经被 node 官方视为一个 [**规范**](https://nodejs.org/api/corepack.html)，已经集成在 Node 的最新发行版本中，目前完整的支持 yarn 和 pnpm 的切换，yarn 和 pnpm 在初始化项目的时候也会将 `packageManager` 写入到 package.json 中，corepack 必定是一个趋势。所以对于包管理器的管理来说，应当尽量使用 Corepack 而非 Volta。

综上，一个比较推荐的做法是：

- 使用 volta 管理 node，以及全局安装的 npm 包
- 使用 corepack 管理包管理器

## 3.2 Volta 与 Corepack 之间的冲突问题

由于 volta 和 corepack 对于包管理器的管理都是基于 shim 的，也就是说他们都会拦截 yarn 以及 pnpm 指令，因此两个管理器之间存在冲突，你可以能会遇到以下问题：

- volta 安装了高版本 node，但是 corepack 指令无法使用；
- 使用 volta 管理的 node 进行全局安装 corepack，在使用 corepack 管理的 yarn/pnpm 执行 package.json 中的脚本时，node 版本也会被限制为 volta 锁定 corepack 时的版本；
- 通过其他途径安装了 corepack，但就是无法使用 corepack 管理的 yarn/pnpm，当使用 yarn 指令时，会出现 volta 的警告；

要想解决这个问题，一定要遵循如下的原则：

1. 不要使用 volta 管理的 node 来全局安装 corepack
2. 让 corepack 的 shim 覆盖掉 volta 的 shim

以下以 MacOS 和 Ubuntu 来演示一下如何同时安装 volta 与 corepack 并解决其冲突：

### MacOS 的安装流程

> 前置条件：最好先卸载设备上所有的包管理器以及 node

首先，如果安装了 volta，按照以下步骤 [卸载 volta](https://docs.volta.sh/advanced/uninstall)：

```sh
rm -rf ~/.volta
```

然后使用 homebrew 安装 corepack：

```sh
brew install corepack
```

> 由于 corepack 依赖 node，brew 会在你的电脑上安装 node@20，不过没关系，后续我们使用 volta 管理 node，安装的这个 node 不会被使用，也不会影响我们使用 volta 切换 node 版本

测试一下 corepack 指令，并将其启用：

```sh
corepack enable
corepack prepare --all
```

安装 volta：

```sh
curl https://get.volta.sh | bash
```

使用 volta 安装 node：

```sh
volta install node
```

安装完 node 后可以检查一下 pnpm/yarn 指令是否被 volta 拦截：

```sh
which yarn
# 如果输出以下路径，说明正在使用 corepack 管理 yarn
/usr/local/bin/yarn
```

后续就不要使用 volta 安装任何包管理器，也不要执行 `npm install yarn -g` 或者 `npm install pnpm -g`，否则 corepack 可能失效。

> 如果 corepack 失效，同时使用 `which yarn` 显示的 yarn 的执行文件在 `~/.volta/bin/yarn` 的位置，可以使用 `corepack enable --install-directory ~/.volta/bin`  来强行将 coreapck 的 shim 覆盖到 volta 的 shim 上。

### Linux 的安装流程

同样的，在安装 corepack 前需要卸载 volta：

```sh
rm -rf ~/.volta
```

由于 Ubuntu 等 Linux 系统没有 homebrew，同时系统的安装源中也没有 corepack，所以我们要通过安装 node@20 的方式来安装 corepack，输入以下指令来添加 node@20 的安装源，并安装 node（其他 Linux 系统可以查看 [这里](https://github.com/nodesource/distributions#installation-instructions)）：

```sh
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - &&\
sudo apt-get install -y nodejs
```

测试一下 corepack 指令，并将其启用：

```sh
corepack enable
corepack prepare --all
```

安装 volta：

```sh
curl https://get.volta.sh | bash
```

使用 volta 安装 node：

```sh
volta install node
```

与 MacOS 不同的是，当你重启终端后会发现 corepack 失效了，具体的表现为，当你使用 `yarn -v` 时会出现如下提示：

```
Volta error: Yarn is not available.

Use `volta install yarn` to select a default version (see `volta help install` for more info).
```

可以使用 `which yarn` 来查看 yarn 的执行路径变为了：

```
/root/.volta/bin/yarn
```

> 在安装了 corepack 但未安装 volta 时，执行路径为 `/usr/bin/yarn`

**我们可以使用如下指令强行让 corepack 的 shim 覆盖掉 volta 的 shim：**

```sh
corepack enable --install-directory ~/.volta/bin
```

进入到 `~/.volta/bin` 目录下，使用 `ls -l` 指令，我们就会发现 volta 的 pnpm、yarn 相关的指令都被指向到了 corepack 的 shim：

```
lrwxrwxrwx 1 root root   51  7月  6 17:08 pnpm -> ../../../usr/lib/node_modules/corepack/dist/pnpm.js
lrwxrwxrwx 1 root root   51  7月  6 17:08 pnpx -> ../../../usr/lib/node_modules/corepack/dist/pnpx.js
lrwxrwxrwx 1 root root   51  7月  6 17:08 yarn -> ../../../usr/lib/node_modules/corepack/dist/yarn.js
lrwxrwxrwx 1 root root   54  7月  6 17:08 yarnpkg -> ../../../usr/lib/node_modules/corepack/dist/yarnpkg.js
```

这样，yarn/pnpm 的管理权就又重新回到了 corepack 手上，可以愉快的使用 corepack 了。

## 3.3 低版本 node 项目中无法使用 corepack

如果你的某个项目低于 node@16.9.0，并且这个项目使用了 pnpm 或者 yarn 来作为包管理器管理项目依赖，那么当你安装并启用了 corepack 后你会发现无法使用 pnpm 和 yarn 指令了，会出现如下报错：

```
/usr/local/Cellar/corepack/0.19.0/libexec/lib/node_modules/corepack/dist/lib/corepack.cjs:39787
      process.exitCode ??= code;
                       ^^^

SyntaxError: Unexpected token '??='
    at wrapSafe (internal/modules/cjs/loader.js:1029:16)
    at Module._compile (internal/modules/cjs/loader.js:1078:27)
    at Object.Module._extensions..js (internal/modules/cjs/loader.js:1143:10)
    at Module.load (internal/modules/cjs/loader.js:979:32)
    at Function.Module._load (internal/modules/cjs/loader.js:819:12)
    at Module.require (internal/modules/cjs/loader.js:1003:19)
    at require (internal/modules/cjs/helpers.js:107:18)
    at Object.<anonymous> (/usr/local/Cellar/corepack/0.19.0/libexec/lib/node_modules/corepack/dist/pnpm.js:2:1)
    at Module._compile (internal/modules/cjs/loader.js:1114:14)
    at Object.Module._extensions..js (internal/modules/cjs/loader.js:1143:10)
```

这是因为 corepack 本身是依赖高版本 node 运行的，当当前系统环境的 node 低于 16.9.0 时，当用户使用 pnpm/yarn 指令会调用 corepack 的 shim，然后执行 corepack 的代码，但是由于当前系统环境的 node 版本低于 corepack 的要求，因此就会出现运行错误。

解决这个问题最好的方案是将 node 升级，如果是在无法升级，则可以尝试以下方案：

- 【最笨的方案，不推荐使用】切回高版本 node，并禁用 corepack，然后回到低版本 node，全局安装 yarn/pnpm（回到高版本 node 前卸载掉全局安装的 yarn/pnpm，然后重新启用 corepack）；
- 【推荐网速快的使用】使用 `npx yarn` 或 `npx pnpm` 指令（还可以指定版本，比如 `npx pnpm@6`）来绕过 corepack，这种方案最便捷，但是由于是使用 npx，每次都需要重新下载 pnpm 和 yarn，网速快的话可以无视；
- 【配置复杂，但使用比较方便】使用 `volta install` 安装一个你需要版本的包管理器，比如 `volta install pnpm@6`，然后你可以在 `~/.volta/tools/image/packages/pnpm/bin` 目录下找到一个 `pnpm` 的可执行文件，你可以在你的 `.bashrc` 或者 `.zshrc` 使用 alias 创建一个指令别名，如 `alias pnpm@volta='~/.volta/tools/image/packages/pnpm/bin/pnpm'`，然后就可以在需要的时候使用 pnpm@volta 来代替执行 pnpm 指令，如果需要切换版本，则重新使用 `volta install` 安装你需要的版本即可；