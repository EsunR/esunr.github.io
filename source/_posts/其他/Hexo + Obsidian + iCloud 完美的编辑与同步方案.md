---
title: Hexo + Obsidian + Git 完美的博客部署与编辑方案
tags:
  - Hexo
  - Obsidian
  - 自动化
categories:
  - 其他
date: 2022-07-06 15:10:52
---

# 1. 前言

在之前的文章[《Hexo 快速搭建指南》](https://blog.esunr.xyz/2022/06/64163235c30f.html)中，重点讲解了如何搭建以及部署博客。但是在后期写博客的过程中，有可能遇到很多麻烦，比如：

- 我不想手动维护文章的 Categorys，我想以文件目录的形式管理文章分类
- VSCode 编写 Markdown 文件不爽，我想用其他的编辑器来写 Markdown
- `hexo new` 指令生成的模板太拉了，我不想用
- 我想把我的 markdown 文档同步到云平台上，方便我的其他设备即时查看

那么这篇文章就会教你使用最舒服的姿势来后期维护你的博客，减少心智负担与解决各种不爽的地方。

# 2. 更好的文章管理方案

## 2.1 文章以目录分类

当我们写好一篇文章后，按照 hexo 的默认配置，我们需要将其放在 `source/_post` 目录下，等时间长了之后，`_post` 目录下的文章就会变得杂乱无章，无法让我们快速的 review 到一篇文章。

那么最好的解决方案就是我们在创建文章的时候以 `文章分类` 作为文件夹创建我们的文章，比如：

```
.
└── source
    └── _post
        ├── 前端
        │   ├── Javascript
        │   │   └── Javascript原型链机制.md
        │   └── 浏览器
        │       └── 浏览器性能优化.md
        └── 后台
            ├── GoLang
            │   └── go语言简介.md
            └── Java
                └── Spring MVC 快速入门.md
```

## 2.2 根据文件目录自动生成 categories 信息

虽然我们把文章放的井井有条了，但是每个文章里的 `categorys` 字段还是要我们手动自己维护的，比如在 `source/_post/前端/Javascript/Javascript原型链机制.md` 文件中，我们要通过手写 `categories` 来让 hexo 知道这篇文章被放在 `前端-Javascript` 分类下：

```markdown
---
title: Javascript原型链机制
categories:
  - 前端
  - Javascript
date: 2022-06-05 12:06:47
---

这里是正文
```

为了省去手动维护 `categorys` 字段的这个问题，我们可以使用 [hexo-auto-category](hexo-auto-category) 这个插件。这个插件在 Hexo 进行 build 的时候会去自动根据文章目录情况来自动修改文章的 `categories` 信息，更详细的部分可以看[作者的文章](https://blog.eson.org/pub/e2f6e239/)。

除此之外最好修改一下 `_config.yml` 中的两处默认配置：

```yml
# 修改 permalink 让你的文章链接更加友好，并且有益于 SEO
permalink: :year/:month/:hash.html

# 规定你的新文章在 _post 目录下是以 cateory 
new_post_name: :category/:title
```

## 2.3 提交代码时自动生成新文章的 categories

但是这里有一个问题，就是只有 hexo 在执行 `hexo generate` 或者 `hexo server` 时候才会去触发 `categories` 的生成，那么每次我们创建文章都要经历这样的工作流：

1. 创建分类目录，写文章，文件名推荐与文章标题一致（不用关心 `categories` 写什么）；
2. 填写 `title`、`date`、`tag` 等元信息（这个文章后续再讨论如何省去这一步）;
3. 执行 `npx hexo generate` 在构建博客的时候触发 `hexo-auto-category` 插件的自动矫正 `categories` 功能；
4. 检查文章中的 `categories` 是否正确；
5. 添加 git 工作区变更，并提交并推送代码到 github。

为了简化这些工作，我们可以使用 git hook，在我们每次执行 `commit` 前都自动运行 `npx hexo generate` 触发自动生成 `categories` 的行为，并将生成后的变更自动添加到本次提交中，然后一同 push 到 github 上去。这里可以使用 husky 来很方便的设置这样一个 git hook。

> GitHook 可以在执行代码的 commit、push、rebase 等阶段前触发，做一些前置行为，比如在每次提交代码时候执行一段 shell 脚本，来做一些代码检查或者通知 ci 等操作。
> 
> Husky 采用了更简单的一种方式，让管理 GitHook 更加现代化
> 
> 关于 Husky 的使用可以参考我之前的文章[《使用 husky 每次提交时进行代码检查》](https://blog.esunr.xyz/2022/05/d36522b1089c.html)

你可以按照如下步骤快速完成设置：

1. 安装 huksy：`npm install husky --save-dev`
2. 执行 huksy 初始化指令：`npx husky install`
3. 在 `package.json` 中的 `scripts` 中写入：`"prepare": "husky install"`
4. 在生成的 `.husky` 目录创建 `pre-commit` 文件（有的话就不用创建），并写入以下内容：

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx hexo generate && git add .
```

> 如果手动创建记得为 pre-commit 文件添加执行权限 `chmod +x pre-commit`

如果提交代码的时候，终端出现类似的构建过程，就说明由 husky 创建的  git hook 生效了：

![](https://s2.loli.net/2022/07/06/vcMfioCqpDtsFQd.png)

这样你新建一篇博客的工作流就简化为：

1. 创建分类目录，写文章；
2. 填写 `title`、`date`、`tag` 等元信息;
3. 添加 git 工作区变更，并提交并推送代码到 github。

这样就解决了令人头疼的文章分类问题~

# 3. 使用 Obsidian 来编写和管理文章

> Obsidian 是目前个人感觉使用起来最舒服的基于 Markdown 的笔记管理工具，好处不多言，用了就知道。

## 3.1 将 Hexo 项目导入 Obsidian

这一步很简单，打开 Obsidian 后，它会默认打开上次的存储库，这个时候你需要点击左下角的 `打开其他库` icon 来调出欢迎面板：

![](https://s2.loli.net/2022/07/06/QekZfSFhYlPwRim.png)

然后在欢迎面板打开你的 Hexo 项目即可：

![](https://s2.loli.net/2022/07/06/YuTzAZeRvICmrEw.png)

由于 hexo 的文章只存在于 `source` 目录下，我们需要让 Obsidian 忽略其他文件的内容以优化性能以及减少不必要的搜索结果。具体的操作是在 `设置-文件与链接-Exclude Files`，将需要忽略的文件添加进去（尤其是 node_modules）：

![](https://s2.loli.net/2022/07/06/8kN4a7H6XSAJzMo.png)

同时，在你的 hexo 项目的 .gitignore 文件中加入如下内容：

```
.obsidian/workspace
```

> .obsidian 文件本身是可以同步的，当前存储库的插件以及相关的配置都会下载在这个文件夹中，因此将其同步到 git 记录中也是非常有用的，假如你切换设备就不需要重新为当前的存储库重新配置 Obsidian 了。

## 3.2 使用 Obsidian 模板快速创建文章

Obsidian 是支持创建新文件时插入模板的，这就意味着我们可以不用重复写 Hexo 博客文的 [Front-matter](https://hexo.io/zh-cn/docs/front-matter.html) 部分。

> Front-matter 是文件最上方以 `---` 分隔的区域，用于指定个别文件的变量，举例来说：
> 
> \---
> title: Hello World
> date: 2013/7/13 20:46:25
> \---

首先我们要创建模板，我们可以在 `source` 目录下创建 `_obsidian` 文件夹，并创建一篇 `Post Template` 的文章（md文件），内容为：

```
---
title: {{title}}
date: {{date}}
tags: []
---
```

然后进入到 Obsidian 的设置面板，选择『核心插件』，并启用『模板』功能。同时点击旁边的配置按钮，进入到模板配置的设置中，将配置信息设置为：

![](https://s2.loli.net/2022/07/06/GcWpeZHJIumFEs1.png)

之后，我们再创建新文章的时候，只需要点击侧边栏的『插入模板』按钮就可以快速生成 Front-matter 信息：

![](https://s2.loli.net/2022/07/06/aV4GeoxKZLMWg2j.png)

## 3.3 使用 Obsidian Git 插件

我们将 Hexo 项目导入到 Obsidian 之后就可以写作了，但是当写作完成之后还面临着提交代码、推送代码到 Github 上这一操作。如果我们在用额外的终端来进行这些操作的话就太割裂了，因此我们可以使用 Obsidian Git 插件来在 Obsidian 内就可以实现 git commit 以及 push 的操作。

Obsidian Git 属于第三方插件，要想使用它必须在设置中关闭安全模式：

![](https://s2.loli.net/2022/07/06/YmbFpJyDTazhCfd.png)

然后浏览插件库，搜索 Obsidian Git 并点击安装，安装完成之后根据自己需要的设置进行配置即可。

如果想要查看当前的工作区、暂存区，可以使用快捷键 `command + p` 打开命令面板，输入 `open source control view` 就可以打开 Git 面板了，这里的面板跟 VSCode 的面板操作类似，并且我它会自动帮你生成 commit 信息（你可以自行在 Obsidian Git 设置面板里配置默认的 commit 信息）：

![](https://s2.loli.net/2022/07/06/jDtmglLPznXrsx8.png)

当然你也可以懒得看 source control view，自己直接用 `command+p` 打开命令面板，分别执行 `git commit` 命令与 `git push` 即可。

## 3.4 使用 File Tree 插件

Obsidian 很不好的一点就是会把所有的文件都列在左侧的文件列表中，但是对于我们的 Hexo 项目写文章来说，我们只会修改 `_post` 目录下的文件，因此我们希望左侧的文件列表中只显示 `_post` 文件夹，但是目前为止 Obsidian 并没有推出类似『聚焦』到某一文件夹内的功能。

好在 Obsidian 强大的插件库中有一个 `File Tree Alternative Plugin` 第三方插件可以满足这一需求。按照 Obsidian Git 相同的方法去下载这个第三方插件，下载完成之后我们会发现左侧菜单出现了一个 `File Tree` 的 Tab 页，点击后就可以看到文件以树形的结构呈现：

![](https://s2.loli.net/2022/07/06/83QJC6ohSzFpqVK.png)

我们展开 `source` 文件夹，并右键 `_post` 文件夹，选择 `Focuse on Folder` 后，左侧的文件列表中就只会显示 `_post` 文件夹中的内容了：

![](https://s2.loli.net/2022/07/06/61qjEJyv3pwmsWt.jpg)

# 4. 使用 iCloud 同步（不推荐，因为 Obsidian 文件嵌套很深，iCloud 同步会很灾难）

如果你是苹果系用户，完全可以通过 iCloud 将 Hexo 项目作为 Obsidian 库同步到各个设备上，让每个设备都可以通过 Obsidian 实时查看和编辑笔记。

你只需要将你的 Hexo 项目复制到 iCloud 的 Obsidian 文件夹即可，但是需要注意的一点是，你项目的 `node_modules` 也同步到 iCloud 上的话就太恐怖了。为了避免这一情况，我们需要将 `node_modules` 命名为 `node_modules.nosync` 这样就不会被 iCloud 同步。但是我们又需要 `node_modules` 来让项目正常运行，因此我们可以使用软链来创建一个 `node_modules` 软链到 `node_modules.nosync` 就能一举两得。简化成终端指令可以为：

```sh
# 重命名 node_modules
mv node_modules node_modules.nosync

# 创建 node_modules 软链
ln -s node_modules.nosync/ node_modules
```

