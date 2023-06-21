---
title: 如何配置 SSH 管理多个 Git 仓库和以及多个 Github 账号
tags:
  - git
  - Github
  - SSH
categories:
  - Git
date: 2023-06-21 16:30:29
---

# 1. Why SSH ?

在使用 github 时或者免密登录到远程服务器时，总要使用到 SSH 这个工具来创建密钥并进行连接，那什么是 SSH 呢，我们先来看一下它的简单定义：

> SSH是一种加密协议，全称为Secure Shell，用于安全地远程登录到服务器或其他远程设备上执行命令或传输文件。它提供了一种安全的加密通信机制，使得远程登录和文件传输等操作不会被恶意攻击者窃取或篡改，确保了数据的保密性和完整性。SSH采用公钥密码学技术，能够有效地防止被中间人攻击或网络窃听。

举例来说，如果我们要使用 Github 这种 git 代码托管平台的话，首先本地要生成一个 SSH `私钥(如id_rsa)` 和 `公钥(如id_rsa.pub)`，然后将 `公钥` 填写到 Github 的 SSH Key 管理面板中。当我们向 Github 推送代码的时候会首先发起身份校验。此时，本地会将用户信息通过 SSH `私钥` 执行『签名』操作。当签名信息发送到 Github 的时候，Github 就会使用用户保存在平台上的 `公钥` 来校验签名信息，使用 `私钥` 签名信息只能由对应的 `公钥` 进行校验，因此如果 Github 对签名校验通过，就可以认证当前的用户对代码仓库拥有响应的操作权限，之后就可以让用户提交的代码入库了，整体流程如下图：

![](https://s2.loli.net/2023/06/19/sIYxpTdMrtmAFHc.png)

> 关于公钥和私钥，是『非对称加密』相关的内容，公钥通常用于 **内容加密** 或 **认证签名**，是可以在服务器与客户端之间进行传播的；而私钥是用来 **解密公钥加密的内容** 或 **对内容进行签名** 用的，是**需要严格保管的**。

综上，SSH 采用非对称加密的方式来完成客户端与服务器端的认证并建立通信连接，因此可以被用于客户端与 git 平台之间的认证，以及远程服务器之间的免密认证。

# 2. 配置单个 Git 账户

首先，我们来简单复习一下如何配置单个 git 账户。

对于单个 git 账户的场景非常简单，假如我们是一个萌新开发者，想要往 Github 上上传项目（这里我们仅探讨 SSH 协议的方式），那么首先我们要在本地安装 OpenSSH 以及 git。

> 一般 Linux 类操作系统、MacOS 都已经自带了 ssh 和 git，不需要单独安装。windows 操作系统参考 [官方说明](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=gui) 来开启 OpenSSH，git 则可以直接访问 [官网](https://git-scm.com/) 进行安装

安装完 git 之后打开终端，我们先要使用 `git` 指令为全局设置一个 git 账户和邮箱：

```sh
git config --global user.email YourEmailAdress
git config --global user.name YourUserName
```

> 这里 git 的用户名和密码跟你的 Github 账号没有强关联，Github 的账号只是你登录平台用的，而这里的 git 用户名和邮箱是用来标记代码是哪个用户写的。

安装完 OpenSSH 之后打开操作系统上的终端（windows 操作系统推荐使用 git bash 或者 cmder），然后来到 ssh 目录下：

```sh
cd ~/.ssh
```

如果首次安装，这个目录里面会没有任何内容，之后我们执行第一步：**生成一对 SSH 密钥**

```sh
ssh-keygen -t rsa -C "YourEmailAdress"
```

这个指令的意思是使用 `ssh-keygen` 生成密钥，`-t` 参数密钥的加密方式是 `rsa`，`-C` 参数可以为密钥指定备注，通常备注可以为你的邮箱，或者你也可以写成你要连接的远程服务器名（总之不重要）。

输入完成之后会进入一个交互式终端界面，首先会询问你的密钥文件名称：

```
Enter file in which to save the key (/Users/username/.ssh/id_rsa):
```

我们可以使用回车跳过，那么密钥文件名称就自动生成为 `id_加密方式`，如 `id_rsa`。

之后会提示用户输入密码：

```
Enter passphrase (empty for no passphrase):
```

这个密码是用来保护你的私钥的，我们这里避免麻烦可以直接跳过。

生成完成之后，我们在终端中使用 cat 指令，输出生成的公钥内容：

```sh
cat ~/.ssh/id_rsa.pub
```

> 公钥的内容为一串长字符串，字符串的末尾为你输入的密钥备注

之后我们访问 Github 的用户设置界面，并来到 `SSH and GPG keys` 面板

![](https://s2.loli.net/2023/06/19/tkALBmQeihN62c1.png)

点击 `New SSH key` ，之后将前面输出的公钥内容粘贴到 输入框中：

![](https://s2.loli.net/2023/06/19/BFMw14a7KOqcdzZ.png)

之后我们输入 `ssh -T git@github.com` 如果提示 `You've successfully authenticated` 就说明成功与 Github 建立了授权链接，你就可以往你的 Github 仓库推送代码了。

# 3. 配置多个 Git 代码托管平台

作为一个程序员，在工作中，我们可能需要将代码推送到公司的自建 Git 代码托管平台上（如 GithLab）。然而在生活中，当我们参与一些个人的开源项目，则又需要将代码推送到社区的 Git 代码托管平台上（如 Github 或 Gieet）。

> emmm 有点像 Marvel 的超级英雄？

为了应对这个场景，我们通常有两种解决方案：

### 3.1 方案一：多个 Git 代码托管平台配置同一个 SSH 公钥

在第一节我们已经简单了解了 SSH 公钥的作用，那么我们可以简单推断出在使用 SSH 创建身份验证连接的时候，**并没有严格限定我们生成的私钥和公钥只能应用于一个 Git 代码托管平台**。

那么我们只要创建出了一对公私钥，复制公钥内容到多个平台的 SSH Key 管理面板中即可完成对一对公私钥的复用。

当我们创建 SSH 连接的时候，git 会使用默认且唯一的一个私钥来对身份信息进行签名，当推送到不通的平台时，因为使用的是同一个公钥，因此可以正常通过身份认证。

### 3.2 方案二：使用多组密钥并指定给不同的平台

SSH 允许统一个操作系统中存在多对密钥，因此你可以使用 `ssh-keygen` 指令生成多组密钥，同时将不同的密钥分配给不通的 Git 代码托管平台。

#### Setp.1 生成密钥 

首先，我们使用 `ssh-keygen` 生成第一组密钥对，用于提供给 Gtihub 平台使用：

```sh
ssh-keygen -t rsa -C "YourPersonalEmailAdress"
# 输入密钥的名称: id_rsa_github
Enter file in which to save the key (/Users/username/.ssh/id_rsa): id_rsa_github
```

然后，我们再生成第二组密钥对，用于提供给公司的 Git 代码托管平台（如 Gitlab）使用：

```sh
ssh-keygen -t rsa -C "YourCompanyEmailAdress"
# 输入密钥的名称: id_rsa_company
Enter file in which to save the key (/Users/username/.ssh/id_rsa): id_rsa_company
```

此时，你的 `~/.ssh` 目录下会出现四个文件：

```
id_rsa_github
id_rsa_github.pub
id_rsa_company
id_rsa_company.pub
```

然后我们要把生成的密钥使用 `ssh-add` 指令添加到 ssh-agent 的身份验证代理中：

```
ssh-add id_rsa_github
ssh-add id_rsa_company
```

> 如果不实用 `ssh-add` 指令添加新的密钥到 ssh agent 中的话，系统会仍然使用 `id_rsa` 作为默认的 SSH Key，因为 `id_rsa` 是被默认添加到 ssh agent 中的

#### Step.2 为远程服务器配置密钥

`~/.ssh` 目录下存在一个 `config` 文件，如果不存在可以使用 `touch config` 指令这个文件。

这个文件用于配置 SSH 客户端的信息，例如主机名、端口号、用户名、密钥等，对于 Git 代码托管平台来说，我们可以通过这个配置为不通的 Git 代码托管平台服务器配置不同的 SSH 密钥。

继续上面的示例，创建 config 文件后，使用 vim 或者其他任意编辑器编辑 config 文件，输入以下内容：

```
Host github
    User git
    Hostname github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa_github

Host company-git
    User git
    # 替换为你公司的 Git 代码托管平台的服务器
    Hostname company-git-repo.com
    # 你公司 SSH 服务的端口号
    Port 22
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa_company
```

config 配置文件中的各项配置意思为：

- Host：指定连接到的主机名，可以随意指定，相当于实际连接目标主机的别名；
- User：指定使用的用户名，通常为 git，也可以不指定；
- Hostname：指定连接到的主机的实际域名或IP地址。如果是向 Github 推送代码，则为 github.com，如果是向公司的 Git 代码托管平台推送代码，则填写公司主机的地址
- Port：SSH 服务的端口号，默认为 22，可以不写
- PreferredAuthentications：指定优先使用的身份验证方法，指定为publickey，即使用公钥进行身份认证。
- IdentityFile：指定要使用的私钥文件路径，即指向你创建的私钥，我们这里分别为不通的 Git 代码托管平台指定了不同的私钥

配置完成后，我们登录 Github，将 `id_rsa_github.pub` 的公钥内容复制到 SSH Key 管理面板中；同样的，我们登录公司的 Git 代码托管平台上，将 `id_rsa_company.pub` 中的公钥内容复制到对应的管理 SSH Key 的位置（这个位置通常在个人信息设置中，可能被称为 『SSH Key 管理』或者『公钥管理』等名称）

这样，当将代码上传到 Github 时，就会自动使用 `id_rsa_github` 这个密钥对；当将代码上传到公司的 Git 代码托管平台时候，就会自动使用 `id_rsa_company` 这个密钥对。

#### Setp.3 配置不同的 git 用户名以及邮箱

除了解决了不同平台使用不通的公私钥问题外，我们在不通的仓库提交代码时用的用户名和邮箱也可能需要不一样，比如：

- 在 Github 上，我需要用网名来隐藏我的真实身份，因此我提交代码的用户名为 `github-user`，邮箱为 `github-user@github.com`；
- 而在工作中，公司则要求我提交代码时的 git 用户名必须为我的真实姓名拼音，邮箱则为公司邮箱。

这些配置就跟 SSH 的配置无关了，这些就需要调整我们的 git 配置。

首先，我们在全局配置一个 git 用户名和邮箱，这里我建议使用你在 Github 上想要使用的用户名和邮箱，毕竟 Github 常驻，而公司不常驻：

```sh
git config --global user.email github-user@github.com[更改成你的邮箱]
git config --global user.name github-user[更改成你的网名]
```

此时，我们在 git 的配置文件 `~/.gitconfig` 中就可以看到如下的配置段，表示已经配置成功：

```
[user]
	name = github-user
	email = github-user@github.com
```

当我们提交代码的时候就会使用这个默认的用户名和邮箱来提交代码了。

除此之外，git 也支持通过在 git 项目内添加一个『本地配置』来单独配置每个项目的用户名和密码。利用这个能力，当我们将公司的代码 clone 到本地之后，进入到代码仓库，**首先要做的第一件事情就是为这个公司的代码仓库设置独立的 git 用户名和密码**。

```sh
git config --local user.name zhangsan[改为你的真实姓名]
git config --local user.name zhangsan@company.com[改为你公司的邮箱]
```

总结，我们在使用 Github 提交提交代码的时候，无需在项目内单独设置 git 用户名和邮箱，因为会自动使用我们全局设置好的；当我们在编写公司项目的时候，当代码拉下来之后要单独为这个项目设置一个用户名和邮箱。

# 4. 同时配置多个 Github 账号

区别与配置多个多个 Git 代码托管平台，还有一种情况我们是可能遇到的。假如你是一个 Github 上的开发者，你的电脑上配置好了一个提供给 Github 提交代码使用的密钥对，但是同时你又需要管理一个小号~~（比如管理一个你女朋友的账号给她的代码仓库提交代码）~~。

聪明的你一定会想到，我再我的小号中添加我现在已经创建好的专门给 Github 使用的公钥不就可以了吗？想法很不错，是第二节中我们提到的方案一的思路，但是 Github 不允许在多个账户上使用同一个 SSH Key，当你设置了就会出现『Key is already in use』的提示。

那先让我们仿照 3.2 节中描述的方法如法炮制一下，再生成一个新的 SSH Key，名字就叫做 `id_rsa_github_x`：

```sh
ssh-keygen -t rsa -C "YourPersonalEmailAdress"
# 输入密钥的名称: id_rsa_company
Enter file in which to save the key (/Users/username/.ssh/id_rsa): id_rsa_github_x
```

我们把小号的公钥添加到 Github 的 SSH Key 面板中后，在 SSH config 文件中追加上：

```
# github 主账号的配置
Host github
    User git
    Hostname github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa_github
    
# github 新账号的配置
Host github_x
    User git
    Hostname github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa_github_x
```

这个时候，你从小号的 Github 中 clone 下来一个仓库，假设地址为 `git@github.com:user_x/blog.git`，那么就在终端中输入：

```sh
git clone git@github.com:user_x/blog.git
```

然后 commit 一些代码后，执行 push 操作时，就会发现出错啦：

```
ERROR: Permission to user_x/blog.git denied to xxx.
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

这个意思就是说明你没有权限向这个仓库中提交代码，也就是说 SSH 授权出问题了。

实际上，在你使用 `git push` 提交代码的时候，由于你的代码的仓库源在 Github 上，因此 SSH 连接的主机就是 `github.com`，然而当 SSH 发起连接的时候，它会发现你的 SSH config 文件中配置了两段 `Hostname` 都为 `github.com` 的配置，那么 SSH 会优先使用第一段配置中的公钥向 Github 建立身份认证连接。那么当身份认证请求到达 Github 的时候，Github 拿出公钥进行身份认证签名对比后发现你不是你的小号，那么自然就会拒绝你的提交代码的请求。

那么，如何让发起请求的时候，使用我们小号的私钥呢？我们先来看一下执行 clone 代码时候，仓库源那个以 `git` 开头的链接是什么意思：

![](https://s2.loli.net/2023/06/21/ODlc8M1eKrb9agP.png)

清楚了以上各个部分代表的意思后，我们可以利用 SSH 建立连接的一个特性：目标服务器可以直接写成为服务器地址，同时也可以写为我们在 SSH config 文件中配置的 `Host`，也就是服务器的别名。

因此我们可以将仓库的源改为 `git@github_x:user_x/blog.git` ：

```
git remote set-url origin git@github_x:user_x/blog.git
```

此外别忘了我们必须使用 `ssh-add` 指令将生成的 SSH key 添加到 ssh-agent 的身份验证代理中：

```sh
ssh-add ~/.ssh/id_rsa_github_x
```

> 否则建立 SSH 连接时，会使用 id_rsa_github 的密钥对，你始终无法得到正确的身份识别！

然后我们来测试一下连接：

```sh
ssh -T git@github_x
# 输出如下内容就说明身份认证通过了！
Hi user_x[你小号的用户名]! You've successfully authenticated, but GitHub does not provide shell access.
```

如果输出的用户名是你的小号，那就说明可以正常在刚才的那个仓库里推送代码了。

再来测试一下主账号的连接是否正常：

```sh
ssh -T git@github.com
# 输出如下内容就说明身份认证通过了！
Hi user[你主账号的用户名]! You've successfully authenticated, but GitHub does not provide shell access.
```

如果输出的用户名是你的主账号用户名，就说明原有的 Github 连接并没有受到影响，之前的仓库依旧可以正常推送代码。

> `You've successfully authenticated, but GitHub does not provide shell access.` 这个警告无需理会，只是在提醒你 github 不允许 shell 交互（比如像使用 ssh 连接一台远程主机那样）而已。

此后，clone 小号的代码仓库时候也要记得将远程源的『目标服务器』字段改写为你在 ssh config 中编写的 Host 别名，这样才不会与你 Github 主账号的连接冲突。主账号则仍然使用 `github.com` 作为目标服务器地址即可。