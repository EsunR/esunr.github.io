---
title: BeeGo快速使用指南
date: 2019-11-09 14:03:52
tags: [Go, BeeGo]
categories: GoLang
---

# 1. 安装与使用

## 1.1 安装Bee

```
go get github.com/astaxie/beego
go get -u github.com/astaxie/beego
go get -u github.com/beego/bee
```

## 1.2 创建一个Bee项目

创建一个标准的 Bee 项目：

```sh
bee new myproject
```

创建一个 api 应用：

```
bee api apiproject
```

创建一个标准的 Bee 项目的目录结构：

```
├─conf
├─controllers
├─models
├─routers
├─static
│  ├─css
│  ├─img
│  └─js
├─tests
└─views
```

## 1.3 启动

在本地以开发模式启动应用：

```sh
$ bee run
```

# 2. Router

## 2.1 默认访问

在 `mian.go` 中引入路由系统：

```diff
// main.go
package main

import (
+   _ "Bee-Study/quickstart/routers"
	"github.com/astaxie/beego"
)

func main() {
	beego.Run()
}
```

首先在 Controller 层创建对应的 Controller 逻辑：

```go
// controllers/default.go
package controllers

import (
	"github.com/astaxie/beego"
)

type MainController struct {
	beego.Controller
}

func (c *MainController) Get() {
	c.Ctx.WriteString("hello")
}
```

然后将路由文件创建于 routers 目录下：

```go
// routers/router.go
package routers

import (
	"Bee-Study/quickstart/controllers"
	"github.com/astaxie/beego"
)

func init() {
    beego.Router("/", &controllers.MainController{})
}
```

当我们访问 `localhost:prot/` 时就会触发 Controller 层的逻辑， 由于浏览器发送的是 GET 请求，所以就会触发 `MainController` 的 `Get()` 方法，输出 `hello`。

## 2.2 不同路由匹配不同方法

由于我们在 MainController 中定义了默认的 Get 方法，所以所有指向 MainController 的路由只要发送 Get 请求就会触发 MainController  的 `Get()` 方法。但通常我们都希望一个 Controller 对象可以处理多个路由请求，所以我们在调用 `beego.Router` 时可以传入第三个参数，即让当前匹配的路由可以在对应的请求方式下，触发 Controller 对象下的某一方法：

```go
// router.go
beego.Router("/test", &controllers.MainController{}, "get:handleTest")
```

```go
// controller.go
func (c *MainController) handleTest(){
    // do something
}
```

# 3. Controller

## 3.1 创建一个 Controller 

Controller 主要负责逻辑控制，通过上一节我们已经创建除了一个简单的 Controller。Controller 不需要在 `main.go` 中挂载，只需要在对应的 Router 下使用对应的 Controller 即可。

创建一个 Controller 我们要继承一个 `beego.Controller` 对象：

```go
type MainController struct {
	beego.Controller
}
```

之后我们可以复写其 `Get()` 方法：

```go
func (c *MainController) Get() {
	c.Data["Website"] = "beego.me"
	c.Data["Email"] = "astaxie@gmail.com"
	c.TplName = "index.tpl"
}
```

## 3.2 Controller 对象

一个 `beeg.Controller` 类型的实例上挂载了如下的常用属性：

- **Data：** 向 Template 中传入的数据

- **TplName：**  vies 文件目录下的模板名称

- **Ctx：** 上下文对象

  - **Ctx.WriteString(content)：** 返回内容

- **Redirect(url, code)：** 重定向 

  > c.Redirect(“/register”, 302)

- **GetString(key)：** 获取 post 数据

  > name := c.GetString(“userName”)

- **GetFile(key)：**获取文件

  ```go
  f, h, err := c.GetFile(“uploadname”)
  defer f.Close()
  if err !- nil{
      return
  }else{
      c.SaveToFile("uploadname", "./static/img" + h.Filename)
  }
  ```

# 4. ORM

## 4.1 创建一个Model

Bee 自带一个ORM框架，如果未下载需要手动安装：

```sh
$ go get github.com/astaxie/beego/orm
```

如果我们要连接 Mysql 数据库，则需要另外安装驱动：

```sh
$ go get github.com/go-sql-driver/mysql
```

之后我们在 `/models/model.go` 文件中需要引入 orm 与 mysql 驱动：

```go
// model.go
import (
	"github.com/astaxie/beego/orm"
	_ "github.com/go-sql-driver/mysql"
)
```

之后定义一个数据库模型：

```go
// model.go
type User struct {
	Id   int
	Name string
	Pwd  string
}
```

创建一个 init() 函数，在整个程序运行初始化时自动创建定义的数据库：

```go
// model.go
func init() {
    // 连接数据库 参数：别名、数据库类型、连接uri
	_ = orm.RegisterDataBase("default", "mysql", "root:root@tcp(localhost:3306)/beego_study?charset=utf8")
    // 注册 Model
	orm.RegisterModel(new(User))
	// 创建表 参数：别名、更改字段后是否重新创建、是否显示创建过程
	_ = orm.RunSyncdb("default", false, true)
}
```

最后不要忘记在 `mian.go` 中加载 models：

```go
// mian.go
import (
	_ "Bee-Study/quickstart/models"
    // ... ...
)
```

## 4.2 ORM 的基本操作

示例中的 `User` 为定义好的 Model 对象。如上述示例中我们在 models 包中创建的 `model.go` 文件中的 `User` 对象，其引入方式为 `models.User`。接下来的操作我们都是通过创建一个 ORM 对象来操作我们所创建的 Model 对象。

> 对数据库的操作都是在 Controller 层完成的。

### 4.2.1 插入

```go
o := orm.NewOrm()
var user User
user.Name = "slene"
user.Pwd= true

id, err := o.Insert(&user)
if err == nil {
    // fmt.Println(id)
    beego.Info("插入失败",err)
    return
}
```

### 4.2.2 查询

```go
o := orm.NewOrm()
user := User{}
err := o.Read(&user)
```

也可以指定字段查询：

```go
user := User{Name: "slene"}
// 或者：user.name = "slene"
err = o.Read(&user, "Name")
```

同时，可以使用 QuerySeter 对象来进行高级查询，获取一个 QuerySeter对象的方式为：

```go
o := orm.NewOrm()
// 获取 QuerySeter 对象，user 为表名
qs := o.QueryTable("user")

// 也可以直接使用对象作为表名
user := new(User)
qs = o.QueryTable(user) // 返回 QuerySeter
```

- qs.Filter：用来过滤查询结果，起到 **包含条件** 的作用

- qs.Exclude：用来过滤查询结果，起到 **排除条件** 的作用

- qs.All：返回对应的结果集对象

  ```go
  var users []*User
  num, err := o.QueryTable("user").Filter("name", "slene").All(&users)
  fmt.Printf("Returned Rows Num: %s, %s", num, err)
  ```

- 更多用法查看 [官方文档](https://beego.me/docs/mvc/model/query.md)

### 4.2.3 更新

```go
o := orm.NewOrm()
user := User{Id: 1}
if o.Read(&user) == nil {
    user.Name = "MyName"
    if num, err := o.Update(&user); err == nil {
        fmt.Println(num)
    }
}
```

也可以指定更新的字段：

```go
// 只更新 Name
o.Update(&user, "Name")
// 指定多个字段
// o.Update(&user, "Field1", "Field2", ...)
...
```

### 4.2.4 删除

```go
o := orm.NewOrm()
if num, err := o.Delete(&User{Id: 1}); err == nil {
    fmt.Println(num)
}
```

## 4.3 模型创建详解

我们通常要创建一个 struct 作为 ORM 中的 Model，在初始化阶段会根据这个结构体创建数据库表，所以在创建这些 Model 时，实际上是在创建一张表的映射，其中有许多需要注意的地方。

### 4.3.1 字段的命名规范

首先我们推荐使用大写字母开头的驼峰命名法来对结构体的属性进行命名，命名通常会有以下特性：

- 创建的结构体中的名字，生成数据库会将大写转为小写，将驼峰命名法之间改为下划线分隔。
- `RunSyncdb()` 方法的第二个参数设置为 false 时，字段发生变动后，会保留原有的字段并创建一个新字段。

如结构：

```go
type User struct{
    Name String
    Age int
    BirthDay time.Time
}
```

生成的表为：

| 字段      | 类型   |
| --------- | ------ |
| name      | string |
| age       | int32  |
| birth_day | time   |

### 4.3.2 字段的属性设置

在设置了字段类型后，可以在后面通过 `orm:`  来追字段的属性。

设置主键：`pk`

设置自增：`auto`

如设置一个自增的主键：

```go
Id int `orm: "pk;auto"`
```

当 Field 类型为 int, int32, int64, uint, uint32, uint64 时，可以设置字段为自增健, 当模型定义里没有主键时，符合上述类型且名称为 Id 的 Field 将被视为自增键。

设置默认值 `orm:"default(11)"`

设置长度 `orm:"size(100)"`

设置允许为空 `orm:"null"`，数据库默认是非空，设置 `null` 之后就可以变为`ALLOW NULL`

设置唯一： `orm:”unique”`

设置浮点数精度 `orm:"digits(12);decimals(4)"`  总共12位，四位是小数位

设置时间： `orm:"auto_now_add;type(datetime)"`

**auto_now 每次 model 保存时都会对时间自动更新**

**auto_now_add 第一次保存时才设置时间**

设置时间的格式：type

### 4.3.3 一对多关系的创建

如果两张表之间存在一对多关系，则需要外键来连接两张表，如多篇文章对应一个文章类型，可以按照如下定义：

```go
type Article struct{
    Id int
    Content string
    ArticleType *ArticleType `orm:"rel(fk)"`
}

type ArticleType struct{
    Id int
    TypeName string
    Articles[] *Articles `orm:"reverse(many)"`
}
```

当查询时，我们需要使用 `RelatedSel()` 指定连接的表，如：

```go
o := orm.NewOrm()
var articles[]models.Article
o.QueryTable("Article").RelatedSel("ArticleType").Filter("Article__TypeName", "文章类型").All(&articles)
```

当插入时，我们将外键关联的 Model 对象直接传入即可，如我们添加一个文章，并关联该文章的类型：

```go
typeName := ”文章类型“
var artiType model.ArticleType
artiType.TypeName = typeName
err = o.Read(&artiType, "TypeName")
if err != nil{
    beego.Info("类型不存在")
    return
}
article.ArticleType = &artiType
article.Content = "... ..."
// 插入数据
_,err = o.Insert(&article)
// ... ...
```

### 4.3.3 多对多关系的创建

同时我们还存在多对多的关系，如一个用户可以喜欢多篇文章，一篇文章也可以被多个用户喜欢：

```go
type User struct{
    Id int
    Name String
    Articles[]*Article `orm:"rel(m2m)"`
}

type Article struct{
    Id int
    Content string
    ArticleType *ArticleType `orm:"rel(fk)"`
    User[] *Users `orm:"reverse(many)"`
}
```

这样创建完成后，会自动多出一张关系表 user_articles：

| 字段       | 类型       |
| ---------- | ---------- |
| id         | bigint(20) |
| user_id    | int(11)    |
| article_id | int(11)    |

