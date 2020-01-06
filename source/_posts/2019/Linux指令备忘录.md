---
title: Linux指令备忘录
tags: []
categories:
  - Other
date: 2019-12-05 17:09:57
---

# 1. 系统相关

### 关机与重启

关机指令：

```sh
shutdown 
 [-t] 在改变到其它runlevel之前﹐告诉init多久以后关机。
 [-r] 重启计算器。
 [-k] 并不真正关机﹐只是送警告信号给每位登录者〔login〕。
 [-h] 关机后关闭电源〔halt〕。
 [-n] 不用init﹐而是自己来关机。不鼓励使用这个选项﹐而且该选项所产生的后果往往不总是你所预期得到的。
 [-c] cancel current process取消目前正在执行的关机程序。所以这个选项当然没有时间参数﹐但是可以输入一个用来解释的讯
```

```sh
halt 
halt = shutdown -h
[-n] 防止sync系统调用﹐它用在用fsck修补根分区之后﹐以阻止内核用老版本的超级块〔superblock〕覆盖修补过的超级块。
[-w] 并不是真正的重启或关机﹐只是写wtmp〔/var/log/wtmp〕纪录。
[-d] 不写wtmp纪录〔已包含在选项[-n]中〕。
[-f] 没有调用shutdown而强制关机或重启。
[-i] 关机〔或重启〕前﹐关掉所有的网络接口。
[-p] 该选项为缺省选项。就是关机时调用poweroff。
```

```
init
init 0为关机﹐init 1为重启
```

重启指令：

```
reboot
```

# 2. 账号相关

### 创建用户

```sh
sudo useradd [Options] UserName
```

其中各选项含义如下：

-c comment 指定一段注释性描述。
-d 目录 指定用户主目录，如果此目录不存在，则同时使用-m选项，可以创建主目录。
-g 用户组 指定用户所属的用户组。
-G 用户组，用户组 指定用户所属的附加组。
-s Shell文件 指定用户的登录Shell。
-u 用户号 指定用户的用户号，如果同时有-o选项，则可以重复使用其他用户的标识号。

为用户添加密码：

```sh
sudo passwd UserName
```

通常 `useradd` 指令创建一个新用户需要对新用户进行各种初始化设置，如果不想手动设置，可以使用 `adduser` 指令快速添加一个新用户：

```sh
sudo adduser UserName
```

### 用户组群

创建组：

```sh
sudo groupadd GroupName 
```

将用户加入组（三选一）：

```sh
sudo usermod -G GroupName UserName  # 这个会把用户从其他组中去掉
sudo usermod -a GroupName UserName
sudo gpasswd -a UserName GroupName
```

查看当前用户所在组：

```sh
groups
> root
```

查看固定用户的权限组

```sh
groups root esunr
> root[用户名]: root[用户组]
> esunr: esunr
```

查看组：

```sh
cat /etc/group

在/etc/group 中的每条记录分四个字段：
第一字段：用户组名称；
第二字段：用户组密码；
第三字段：GID
第四字段：用户列表，每个用户之间用,号分割；本字段可以为空；如果字段为空表示用户组为GID的用户名；
```

### 切换用户

切换用户：

```sh
su [username]
```

### 使用 root 用户

创建并登录root用户：

```sh
sudo passwd root # 创建 root 用户
su 				 # 登录 root 用户
```

# 3. 权限相关

### 权限基本知识

权限示例：`-rw-rw-r--`

**权限一共有10位数其中：**

- 最前面那个 `-` 代表的是类型：`-` 代表文件，`d` 代表文件夹

- 中间那三个 `rw-` 代表的是所有者（user）

- 然后那三个 `rw-` 代表的是组群（group）

- 最后那三个 `r--` 代表的是其他人（other）

**rwx 的含义：**

r 表示文件可以被读（read），w 表示文件可以被写（write），x 表示文件可以被执行（如果它是程序的话）。

**用数字代替rwx：**

- r = 4

- w = 2

- x = 1

**Tips：**

- 如果递归删除一个文件夹，文件夹内有当前用户没有权限的文件的话，会跳过删除，只删除有权限的文件。

- 如果一个文件是只读属性，用户去强制修改后原来的文件会被命名为 `FileName~` 的形式保留下来。

### 权限的查看

查看文件权限：

```sh
ls -l FileName  # 查看指定文件权限
ls -l 			# 查看当前文件夹所有文件的权限详情，如果有子文件是文件夹，则列出文件夹权限详情
```

查看文件夹权限：

```sh
ls -ld FolderName   # 查看指定文件夹权限
ls -ld 				# 查看当前文件夹权限
```

权限输出：

```sh
total 0 [文件列表总大小]
-rw-rw-r--[权限详情] 1[硬连接个数] esunr[创建人] esunr[归属组] 17[文件大小] Dec 5 17:34 test[文件名]
```

> 文件被创建后，默认的权限为 -rw-rw-r-- 也就是 664

### 权限的修改

修改文件权限：

```sh
chmod 777 FileName
```

递归修改文件权限：

```
chmod -R 777 FolderName
```

如果递归修改权限的文件夹中有当前执行指令用户没有权限的文件，那么就会出现提醒拒绝修改，只修改用户有权限的文件。

修改文件的归属组：

```sh
chown [-R] 用户名:群组名 文件或目录
```

# 4. 文件相关

### 复制文件

```sh
cp [Option] SorceFile TargetFile
cp -r FolderName TargetFolder	 	# 复制文件夹，移动文件夹不受制于权限，文件的权限信息会一并被复制
cp -r FolderName1/* FolderName2		# 将 FolderName1 下的文件全部覆盖到 FolderName2 下，覆盖文件不会有提示
cp -r -i FloderName1 FolderName2 	# 将 FolderName1 下的文件全部覆盖到 FolderName2 下，覆盖文件会有提示
```

> 文件复制默认覆盖，但是文件夹递归复制不会覆盖文件

参数说明：

-a:是指archive的意思，也说是指复制所有的目录

-d:若源文件为连接文件(link file)，则复制连接文件属性而非文件本身

-f:强制(force)，若有重复或其它疑问时，不会询问用户，而强制复制

-i:若目标文件(destination)已存在，在覆盖时会先询问是否真的操作

-l:建立硬连接(hard link)的连接文件，而非复制文件本身

-p:与文件的属性一起复制，而非使用默认属性

-r:递归复制，用于目录的复制操作

-s:复制成符号连接文件(symbolic link)，即“快捷方式”文件

-u:若目标文件比源文件旧，更新目标文件 

# 5. 应用相关

### 查找应用

通过以下指令可以查找到安装过的应用：

```shell
dpkg --get-selections | grep ‘软件相关名称’
```

### 卸载应用

`apt-get purge / apt-get --purge remove`

删除已安装包（不保留配置文件）。

如软件包a，依赖软件包b，则执行该命令会删除a，而且不保留配置文件

`apt-get autoremove`

删除为了满足依赖而安装的，但现在不再需要的软件包（包括已安装包），保留配置文件。

`apt-get remove`

删除已安装的软件包（保留配置文件），不会删除依赖软件包，且保留配置文件。

`apt-get autoclean`

APT的底层包是dpkg, 而dpkg 安装Package时, 会将 \*.deb 放在 /var/cache/apt/archives/中，apt\-get autoclean 只会删除 /var/cache/apt/archives/ 已经过期的deb。

`apt-get clean`

使用 apt\-get clean 会将 /var/cache/apt/archives/ 的 所有 deb 删掉，可以理解为 rm /var/cache/apt/archives/\*.deb。

### 添加环境变量

当在源码安装的过程中如果在生成内容时用 `prefix` 设置了源码安装应用的位置，那么安装的应用携带有 bin 文件，是无法自动与系统做关联的，我们就无法在 bash 中直接使用它们，与 Windows 相似的，我们需要添加系统环境变量中的 PATH 才能连接到应用的 bin 文件，这时如果直接在命令行中使用 `export` 设置 PATH 的话只是临时的，如果想要永久产生影响就还是需要去修改 `/etc/.profile` 文件，这是在系统每次启动时会自动执行的文件，我们在这里设置 PATH 会让系统在每次开机时都应用这些 PATH，与其相类似的文件还有以下几个：

1. **/etc/profile：** 此文件为系统的每个用户设置环境信息,当用户第一次登录时,该文件被执行. 并从/etc/profile.d目录的配置文件中搜集shell的设置。

2. **/etc/bashrc:** 为每一个运行bash shell的用户执行此文件.当bash shell被打开时,该文件被读取（即每次新开一个终端，都会执行bashrc）。

3. **~/.bash\_profile:** 每个用户都可使用该文件输入专用于自己使用的shell信息,当用户登录时,该文件仅仅执行一次。默认情况下,设置一些环境变量,执行用户的.bashrc文件。

4. **~/.bashrc:** 该文件包含专用于你的bash shell的bash信息,当登录时以及每次打开新的shell时,该该文件被读取。

5. **~/.bash\_logout:** 当每次退出系统(退出bash shell)时,执行该文件. 另外,/etc/profile中设定的变量(全局)的可以作用于任何用户,而~/.bashrc等中设定的变量(局部)只能继承 /etc/profile中的变量,他们是"父子"关系。

6. **~/.bash\_profile:** 是交互式、login 方式进入 bash 运行的~/.bashrc 是交互式 non\-login 方式进入 bash 运行的通常二者设置大致相同，所以通常前者会调用后者。

```bash
sudo vim /etc/profile

###### /etc/profile
# $PATH 表示已经设置的环境变量
export PATH=xxx/xxx/bin:$PATH 
######
```

保存后再运行该文件让其生效：

```bash
source /etc/profile
```

输出环境变量检查是否设置成功：

```bash
echo $PATH
```