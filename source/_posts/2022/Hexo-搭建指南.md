---
title: Hexo 搭建指南
tags: []
categories:
  - Front
date: 2022-06-05 12:06:47
---

# 1. 安装与使用 Hexo

hexo 官方网站：https://hexo.io/zh-cn/

## 1.1 安装

全局安装 hexo-cli ，用以创建 hexo 项目：

```sh
npm install hexo-cli -g
```

安装完成后，就可以在终端使用 `hexo` 指令了，可以使用以下指令创建一个 hexo 项目：

```sh
hexo init hexo-blog
cd hexo-blog
yarn install
```

完成后项目目录如下：

```
.
├── _config.yml # 网站的基础配置，文档：https://hexo.io/zh-cn/docs/configuration
├── package.json
├── scaffolds # 文章模板
├── source
|   ├── _drafts
|   └── _posts # 你的 markdown 文章就需要存放在此目录下
└── themes # 存放主题源码
```

## 1.2 安装第三方主题

### npm 安装

Hexo 5.0.0 版本以上，可以使用 npm 安装主题，简单易用、方便升级，但缺点是无法修改源码。

以 [hexo-theme-fluid](https://github.com/fluid-dev/hexo-theme-fluid) 主题为例，使用 npm 安装只需要执行：

```sh
yarn add hexo-theme-fluid
# 或者
npm install --save hexo-theme-fluid
```

然后在博客目录下创建 `_config.fluid.yml`，将主题的 [\_config.yml](https://github.com/fluid-dev/hexo-theme-fluid/blob/master/_config.yml) 内容复制进去。

### 源码安装

源码安装是老版本 Hexo 安装主题的方式，如果你项修改主题的源码也可以很方便的直接修改。

仍然以 [hexo-theme-fluid](https://github.com/fluid-dev/hexo-theme-fluid) 主题为例，在项目的 [Releases](https://github.com/fluid-dev/hexo-theme-fluid/releases) 页面中下载源码文件：

![](https://s2.loli.net/2022/06/05/ohY3uyv8btkKMjq.png)

下载解压后，在 `themes` 目录下创建一个 `fluid` 目录，将源码复制到该目录下，如下：

![](https://s2.loli.net/2022/06/05/KuQ3kmH1Y4FClUx.png)

### 应用主题

当你安装成功后，需要在 `_config.yml` 中将使用的主题设置为你下载好的主题，找到 `theme` 配置项，将其修改为：

```yml
# Extensions
## Plugins: https://hexo.io/plugins/
## Themes: https://hexo.io/themes/
theme: fluid
```

### 配置第三方主题

如果你是以 npm 方式安装主题，你需要修改你刚才在博客目录下创建 `_config.fluid.yml` 文件修改相关配置；

如果你是以源码方式安装的主题，就不需要创建 `_config.fluid.yml` 文件了，只需要修改 `/themes/fluid/_config.yml` 文件中的配置就可以了。

> 注意：每个主题的配置文件名称都不一样，主题的配置项也不一样，具体需要自行查看你安装主题的说明文档

# 2. 部署 Hexo 到服务器

如果你不想了解如何部署网站到服务器上，或者没有属于自己的服务器，你可以跳过这一章节，直接阅读第三节。

## 2.1 获取编译好的 hexo 静态文件

可以使用 hexo-cli 的 generate 指令来生成静态博客，hexo-cli 已经将这一指令写入到 `package.json`，因此你可以使用 `npm/yarn` 指令来调用构建指令：

```sh
yarn build
# 或者
npm run build
```

博客目录下会生成一个 `public` 目录，这就是 Hexo 编译好的静态博客，接下来我们只需要将生成的静态文件部署到服务器上即可。

## 2.2 Nginx

服务器选择使用 Nginx 进行部署（of course，你也可以使用 Caddy）。

### 安装 Nginx

首先在服务器上安装 nginx，以 Ubuntu 为例：

```
sudo apt install nginx
systemctl enable nginx # 将 nginx 设置为开机启动项
systemctl start nginx # 开启 nginx
systemctl status nginx # 查看 nginx 状态
```

官方完整安装文档：https://www.nginx.com/resources/wiki/start/topics/tutorials/install/#official-debian-ubuntu-packages

### 查看/修改 Nginx 配置

你可以使用 vim 指令查看 nginx 配置：

```sh
vim /etc/nginx/nginx.conf
```

## 2.3 部署博客

### 上传静态资源

使用任意的 sftp 工具，mac 推荐使用 FileZilla，连接到服务器后，进入服务器的 `/var/www/html` 目录下，清空目录下原有的文件，然后将刚才编译好的 hexo 博客的静态文件上传至该目录下即可。

之后我们可以直接访问服务 ip 的 80 端口（即默认 http 的默认端口），就可以看到我们的网站了。

但是一般正规的网站是不会直接用 ip 访问的，因此我们需要为自己的网站绑定一个域名。

### 为网站绑定域名

进入你的域名解析控制台，以腾讯云的 DNSPod 为示例，点击添加记录，记录类型选择为 `A` 类型：

![](https://s2.loli.net/2022/06/05/qFA7BurbpQXNsI5.png)

记录值填入你的服务器 ip，即完成了域名与服务器的绑定。

其中的『主机记录』意为二级域名的名称，假如你的域名为 `domain.xyz`：

- 当你写为 `@` 时，用户访问 `domain.xyz` 会解析为你的主机 ip
- 当你写为 `*` 时，用户访问 `hi.domain.xyz` 与 `oh.domain.xyz` 等任意二级域名都会解析为你的主机 ip（一般不会这么干）
- 当你写为 `www` 时，用户访问 `www.domain.xyz` 会解析到你的主机 ip

域名绑定成功后就可以直接使用域名访问你的博客啦！

# 3. 使用 github.io 展示网站

Github 提供了一个用以专门展示静态网站的服务，即为 [github.io](https://docs.github.com/cn/pages/getting-started-with-github-pages/creating-a-github-pages-site)。

如果不是特别对网速有要求（毕竟 github.io 的服务器在国外），推荐你使用 github.io 来部署你的网站，可以省去很多部署步骤，可以完美与 Github Action 进行配合，进行自动化部署博客。

## 3.1 项目上传到 Github

在 Hexo 博客项目初始化 git 仓库：

```sh
git init
```

然后在 Github 中创建一个新项目仓库，名称必须为 `<你的github用户名>.github.io`，创建完成后按照指引将你的博客代码上传到 github。

# 3.2 开启 Github Pages

在执行这一步之前，先创建一个没有任何代码的新分支，命名为 `release`：

```sh
git checkout -b release
rm -f * # 确定你的当前目录没问题，把握不住删除指令的话就手动删除当前文件加的内容
git push --set-upstream origin release # 上传 release 分支 
```

在项目的设置中找到 Github Pages，并将展示分支设置为刚才创建的 `release` 分支：

![](https://s2.loli.net/2022/06/05/fmLnCi2SyZDJuN6.png)

这就意为这你在 `release` 上传的任何 html 都可以使用 `<你的github用户名>.github.io` 这个域名来访问了。

我们切回 `master` 分支，之后执行 `yarn build` 将生成的 `public` 目录下的文件复制一份，然后重新切回 `release` 分支，将刚才复制的内容粘贴到 `release` 分支下，并上传代码。如果没有操作失误的话，访问 `<你的github用户名>.github.io` 即可看到你的博客了。

# 3.3 使用 hexo deploy 指令

在上一步，我们演示了如何手动去将代码部署到 Github Pages 上，实际上 Hexo 提供了一个自动化的指令来帮助我们完成这一繁杂的过程，那就是使用 [hexo deploy](https://hexo.io/zh-cn/docs/one-command-deployment) 指令。

但是使用之前要先安装 `hexo-deployer-heroku`：

```sh
yarn add hexo-deployer-heroku
# 或者
npm install hexo-deployer-heroku --save
```

然后在 `_config.yml` 中找到 `deploy` 配置项，将其修改为：

```yml
deploy:
  type: git
  repo: git@github.com:<你的github用户名>/<你的github用户名>.github.io.git
  branch: release
```

然后再执行 `yarn deploy` 就可以自动化完成编译博客、切换分支、替换静态文件、上传代码这一系列操作。

# 4. 使用 Github Action 自动化部署

回顾一下上面的步骤，我们即使使用了 `hexo deploy` 指令，其实也很麻烦，需要我们在本地等漫长的编译过程，编译完了还要更新代码到 github 仓库上。为了简化这一流程，就可以选择使用 Github Action 来帮我们做自动化部署。

Github Action 可以实现在一个行为触发之后再执行一些其他的行为，利用这个能力我们就可以实现当我们写完一篇文章后，将代码 Push 到 Github 仓库的这一刻，让 Github 来帮我们完成编译以及部署这个流程，也就是实现持续集成（CI）、持续交付（CD）的这个效果。

关于 Github Action，详细教程可以查看 [官方文档](https://docs.github.com/cn/actions)。按照文档中所描述的，只要我们在代码中添加一层 `.github/workflows` 目录，并且在目录下创建一个 `yml` 文件来描述具体的行为，就可以实现开启 Github Action。

如下是一个编写好的部署 hexo 博客的 yml 文件，你可以将其写入到 `.github/workflows/blog-deploy.yml` 文件中：

```yml
name: Deploy hexo blog
on:
  push:
    branches:
      - "master"
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          ref: "master"

      - name: Setup node
        uses: actions/setup-node@v3
        with:
          node-version: "14"

      - name: Setup yarn & Install node_modules
        uses: borales/actions-yarn@v2.3.0
        with:
          cmd: install

      - name: Check yarn & node version
        run: |
          echo "Node version is `node -v`"
          echo "Yarn version is `yarn -v`"

      - name: Build & Deploy
        run: |
          git config --global user.name "GitHub Action"
          git config --global user.email "action@github.com"
          sed -i'' "s~git@github.com:~https://${{ secrets.GH_TOKEN }}@github.com/~" _config.yml
          rm -rf .deploy_git
          yarn clean
          yarn build
          yarn deploy
```

保存后提交代码后，就可以在你的博客的 Github 项目仓库里的 Actions 标签页里找到创建好的 workflow 了，并且当你 push 代码时，这个工作流就会被触发：

![](https://s2.loli.net/2022/06/05/7a1uWv2npsr4lIj.png)

但其实它最终会失败的，因为我们还有一步没有完成。在上面的脚本中使用了一个 Github Action 的 [secrets 上下文](https://docs.github.com/cn/actions/learn-github-actions/contexts#secrets-context)，即 `${{ secrets.GH_TOKEN }}` 这里。

`${{}}` 是 Github Action 中的特定模板语法，可以获取到一些 Github 相关的内置的系统变量（姑且这么说吧），但又区区别与 Github Action 的环境变量。我们这里获取的 `secrets.GH_TOKEN` 是 Github Personal access token，获取这个 token 的目的是为了让当前的 Github Action 工作流有向我们的项目推送代码的权限。

首先我们要获取这个 Token，你可以在你的用户头像菜单里选择 `Setting`，进入设置后选择 `Developer settings`，再选择 `Persona access token` 就可以看到它了：

![](https://s2.loli.net/2022/06/05/UDtl18ExRyO24nK.png)

点击右上角的 `Generate new token` 按钮生成新的 Token，填写一个你比较容易区分的备注后，勾选 `repo` 和 `workflow` 权限，并将 `Expiration` 过期时间选为 `No expiration`：

![](https://s2.loli.net/2022/06/05/Ar3V247LEmTUofS.png)

> 这个 Token 相当重要，千万不能泄露，如过泄露立刻重置该 token ！！！

点击 `Generate token` 按钮后，就会生成一个 `ghp` 开头的 token，你需要在此复制该 token（后面不能再查看了，只能重新生成）:

![](https://s2.loli.net/2022/06/05/Uk4xcMfPdsDHmYg.png)

复制该 token 后，进入到博客仓库的设置中，选择 `Secrets - Actions`，点击 `New repository secret` 按钮生成一个密钥信息：

![](https://s2.loli.net/2022/06/05/dx3XuegCo7UGAPb.png)

我们将密钥名称写为 `GH_TOKEN`，值填入刚才复制的 Github token：

![](https://s2.loli.net/2022/06/05/RGYbpPB4CDLS5kc.png)

> 这里所新建的 secret 字段，就可以被 Github Action yml 配置中的 `secret` 上下文对象所获取到。

至此 Github Action 工作流就可以正常使用了，你可以愉快的开始写你的博客啦，你的每次提交 Github Action 都会帮你进行自动部署，enjoy yourself ~