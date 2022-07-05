---
title: Git 修改已提交的 commit 中的信息
tags: [Git]
categories:
  - Git
date: 2022-07-04 15:57:46
---

# 修改某次 Commit

调用 `git log` 查看 **要修改的 commitId 前的一个 commitId**

然后调用：

```sh
git rebase -i <commit id>
```

进入 rebase 模式后，按 `i` 进入编辑模式，将修改的 commit 状态修改为 `edit`：

```
修改前：pick xxxxxx Commit Message
修改后：edit xxxxxx Commit Message
```

按 `esc` 后输入 `wq` 指令，按 `Enter` 确认退出 rebase 模式。

之后便可以执行修改指令：

- 改作者和邮件地址：`git commit --amend --author="AuthorName <email@address.com>"`
- 改日期时间：`git commit --amend --date="Thu, 07 Apr 2005 22:13:13 +0200"`
- 改commit评注：`git commit --amend -m "New Commit Message"`

修改完成后执行 `git rebase --continue`

最后将修改强行覆盖到远程仓库 `git push origin master --force`

> 原文地址：https://blog.csdn.net/Revivedsun/article/details/113002659

# 批量修改历史 Commit

批量修改脚本：

```sh
#!/bin/sh

git filter-branch --env-filter '

# 之前的邮箱
OLD_EMAIL="xxx@xxx.com"
# 修改后的用户名
CORRECT_NAME="EsunR"
# 修改后的邮箱
CORRECT_EMAIL="xxx@xxx.com"

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags
```

脚本执行完毕后，使用 `git push origin --force` 即可