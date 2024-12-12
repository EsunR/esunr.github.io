---
title: MacOS Python 环境搭建
tags:
  - Python
categories:
  - 后端
  - Python
date: 2024-12-12 15:02:51
---
# 1. 环境管理

## pyenv

pyenv 是用来管理 python 版本的工具。

功能：

- 允许您基于每个用户更改全局 Python 版本。
- 提供对每个项目的 Python 版本的支持。
- 允许您使用环境变量覆盖 Python 版本。
- - 一次搜索来自多个版本的 Python 的命令。这可能有助于使用 tox 测试跨 Python 版本。

安装：

```sh
brew install pyenv
```

zsh 环境变量配置：

```sh
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
```

列出可用的 python 版本并安装：

```sh
pyenv install -l

# 安装指定版本 Python
pyenv install 3.10.4

# 安装最新版本 Python3
pyenv install 3
```

列出当前安装的 Python

```sh
pyenv versions
```

切换 Python 版本：

```sh
# 仅当前会话
pyenv shell <version>

# 位于当前目录或其子目录时选择
pyenv local <version>

# 全局切换
pyenv global <version>

# 全局切换为系统提供的 python 版本
pyenv global system
```

卸载 python：

```sh
pyenv uninstall <version>
```

## venv

venv 是 Python 内置的用来创建虚拟环境的包，使用 venv 指令后可以创建一个与系统环境隔绝的 Python 环境，比如当使用 pip 时只会将安装的包安装到虚拟环境中。

> Python 3.5 之前使用 pyvenv 来创建虚拟环境

创建虚拟环境：

```sh
# 在当前工作目录下创建 venv 环境，虚拟环境的内容将被保存在 venv 目录下
python -m venv venv
```

> `-m` 指令保证 venv 模块从当前的 Python 环境中进行加载

创建虚拟环境之后让虚拟环境生效：

```sh
source ./vevn/bin/activate
```

退出虚拟环境：

```sh
deactivate
```

## pip

[参考](https://packaging.python.org/en/latest/tutorials/installing-packages/#source-distributions-vs-wheels)

pip 是 Python 的包管理工具，其默认的源是 [PyPI](https://pypi.org/)

使用 pip 安装：

```sh
# 安装最新版本
python -m pip install "SomeProject"

# 安装特定版本
python -m pip install "SomeProject==1.4"

# 安装大于或等于一个版本，且小于另一个版本
python -m pip install "SomeProject>=1,<2"

# 安装与特定版本兼容的版本
python -m pip install "SomeProject~=1.4.2" # 在这种情况下，这意味着安装任何版本“==1.4.*”也是“>=1.4.2”的版本

# 安装多个包
python -m pip install <package1> <package2> ...
```

> 如果要分发包，则需要使用 `setuptools` 和 `wheel`

安装 requirements 文件中的依赖项：

```sh
python -m pip install -r requirements.txt
```

创建 requirements.txt：

```sh
python -m pip freeze > requirements.txt
```

# 2. IDE 搭建

VSCode 安装以下插件：

- Python：基础扩展，包含了 Python Debugger、Pylance
- Python Environment Manager：环境管理
- Python Indent：代码缩进增强
- autopep8：格式化工具
- PyLint：Python Lint 工具