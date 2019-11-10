---
title: MongoDB快速使用指南
tags: [Mongodb]
categories:
  - Front
  - Mongodb
date: 2019-06-04 22:13:04
---
# 1. 基本概念

## 知识点

MongoDB有以下几个重要概念，分别对应关系型数据库中的概念模型：

* 数据库（Database） - 数据库（Database）
* 集合（Collection）- 数据表（Table）
* 文档（Document）- 记录（Record）

## 数据库使用步骤

1. 建立数据库(KomaBlog)
2. 建立数据集合(Posts，categories，Tags)
3. 建立数据(Post:{"_id"：""，"title"：""})

> 每一个文档（记录）的字段可以不同

* KomaBlog
  * Posts
    * {"_id": "1", "title": "我的第一篇博客"}
    * {"_id": "2", "title": "我的第二篇博客"}
    * {"_id": "3", "title": "我的第三篇博客","delflg"：1}
  * Categories
    * {"_id"：“1"，"title"：“游戏"}
    * {"_id"："2"，"title"："技术"}
  * Tags
    * {"_id"："1"，"title"："光荣系列"}
    * {"_id"：“2"，“title"：“任天堂系列“}
    * {"_id"："3"，“title"："Ubuntu"}

## NoSql

在NoSql的数据库中，操作数据都是通过指令或程序语言完成的，比如在MongoDB中使用过Javascript和JSON数据结构，来操作和管理数据的。



# 2. 简简单单NoSql

## 知识点

* mongo命令行工具
* 建立删除数据库

## 实战演习

~~~bash
$ mongo
> help
> exit
$ mongo
> show dbs;
> use komablog;
> show collections;
> db.createCollection("posts");
> db.createCollection("categories");
> db.createCollection("tags");
> show collections;
> show dbs;
> db.stats();
> db.dropDatabase();
> show dbs;
~~~



# 3. 操作集合（Collection）

## 知识点

* MongoDB数据集合的操作

## 实战演习

~~~bash
$ mongo
> show dbs;
> use komablog;
> show collections;
> db.createCollection("users");
> show collections;
> db.users.renameCollection("staff"); // users -> staff
> show collections;
> db.staff.drop();
> show collections;
> db.dropDatabase();
> show dbs;
~~~




# 4. 操作文档（Document）

## 知识点

* MongoDB数据文档的操作

## 实战演习

~~~bash
$ mongo
> use komablog;
> show collections;
> db.createCollection("posts");
> db.posts.insert(
... {
...     title: "我的第一篇博客",
...     content: "已经开始写博客了，太激动了。"
... }
... );
> show collections;
> db.posts.find();
> db.posts.insert(
... {
...     title: "我的第二篇博客",
...     content: "写点什么好呢？",
...     tag: ["未分类"]
... }
... );
> db.posts.find();
> for(var i = 3; i <=10; i++ ) {
...     db.posts.insert({
...         title: "我的第" + i + "篇博客"
...     });
... }
> db.posts.find();
> db.posts.count();
> db.posts.remove({}); // 大括号内的是数据字段的匹配条件，如果留空会删除所有的数据
> db.posts.count();
> db.posts.find();
~~~




# 5. 带条件的文档

## 知识点

* db.[collection_name].find({"":""})
* $gte (>=) , $gt (>) , $lte (<=) , $lt (<)
* $eq (=) , $ne (!=)
* 正则表达式:/k/, /^k/
* db.[collection_name].distinct("field_name");

## 实战演习

~~~bash
$ mongo
> use komablog;
> db.posts.remove({});
> db.posts.insert({title:"怪物猎人世界评测","rank":2,"tag":"game"});
> db.posts.insert({title:"纸片马里奥试玩体验","rank":1,"tag":"game"});
> db.posts.insert({title:"Utunbu16LTS的安装","rank":3,"tag":"it"});
> db.posts.insert({title:"信长之野望大志销量突破10000","rank":4,"tag":"game"});
> db.posts.insert({title:"Ruby的开发效率真的很高吗","rank":7,"tag":"it"});
> db.posts.insert({title:"塞尔达传说最近出了DLC","rank":4,"tag":"game"});
> db.posts.find({"tag": "game"});
> db.posts.find({"rank": {$gte: 4}});
> db.posts.find({"rank": {$gt: 4}});
> db.posts.find({"rank": {$lte: 4}});
> db.posts.find({"rank": {$lt: 4}});
> db.posts.find({"title": /u/});
> db.posts.find({"title": /^R/});
> db.posts.find({"title": /^U/});
> db.posts.distinct("tag");
~~~



# 6. 复杂条件抽文档

## 知识点

* 且查询：db.[collection_name].find({ "": "", "": "" })
* 或查询：db.[collection_name].find({ $or: [{...},{...}] });
* 某一字段存在多个可能数据：db.[collection_name].find({ "": {$in: [...]} });
* 获取是否存在某一字段的数据：db.[collection_name].find({ "": {$exists: true} });

## 实战演习

~~~bash
$ mongo
> use komablog;
> db.posts.find();
> db.posts.find({ "title": /u/, "rank":{$gte:5} });
> db.posts.find({ $or: [{"title": /u/}, {"rank":{$gte:4}}] });
> db.posts.find({ "rank": {$in: [3,4]} });
> db.posts.insert({ "title":"惊！骑士发生重大交易", "istop": true });
> db.posts.find({ "istop": {$exists: true} });
~~~



# 7. 指定抽出字段

## 知识点

* db.[collection_name].find({}, {field1: true, field2: 1})

## 实战演习

~~~bash
$ mongo
> use komablog;
> db.posts.find();
> db.posts.find({}, {title:true, rank:1});
> db.posts.find({}, {title:true, rank:1, _id:0});
~~~



# 8. 文档的方法

## 知识点

* 排序：sort()
  * `sort({rank:1})` 进行升序排序
  * `sort({rank:-1})` 进行降序排序
* 限制：limit([Number])
  * 抽取查询结果的前[Number]条数据
  * 使用 `findOne()` 代替 `find()` 可以查询首条记录
* 跳过：skip([Number])
  * 跳过前[Number]条数据
  * 与 `limit()` 配合使用可以实现分页

## 实战演习

~~~bash
$ mongo
> use komablog;
> db.posts.find();
> db.posts.find({}, {_id:0}).sort({rank:1});
> db.posts.find({}, {_id:0}).sort({rank:-1});
> db.posts.find({}, {_id:0}).limit(3);
> db.posts.find({}, {_id:0}).sort({rank:-1}).limit(3);
> db.posts.findOne({}, {_id:0});
> db.posts.find({}, {_id:0});
> db.posts.find({}, {_id:0}).limit(3);
> db.posts.find({}, {_id:0}).skip(3).limit(3);
~~~





# 9. 文档更新（update）

## 知识点

* update(\<filter\>, \<update\>, \<options\>)
  * 使用 `$set` 来设置新值。
  * 如果过滤出多条数据后使用 `$set` 设置新值，在Mongodb中会只更新过滤出的第一条选项。使用设置选项 `multi: true` 可以更新过滤出的所有数据。·
  * 如果不使用 `$set` 在 `<update>` 中直接填写一个JSON格式的数据字段，那么Mongodb会删除原来文档的所有数据，将文档更新为新传入的数据。

### 命令参考网页

https://docs.mongodb.com/manual/reference/method/db.collection.update

## 实战演习

> 更新数据的key值必须用 `""` 包裹

~~~bash
$ mongo
> use komablog;
> db.posts.findOne({"title":"怪物猎人世界评测"});
> db.posts.update({"title":"怪物猎人世界评测"}, {$set: {"rank": 10} });
> db.posts.find();
> db.posts.update({"title":"怪物猎人世界评测"}, {"rank": 99});
> db.posts.find();
> db.posts.update({"tag":"it"}, {$set: {"rank": 50}});
> db.posts.find();
> db.posts.update({"tag":"it"}, {$set: {"rank": 60}}, {multi: true});
> db.posts.find();
~~~



# 10. 玩几个特殊函数

今天为您讲几个操作文档字段的函数。

> 只要开头为 `$` 的都是特殊函数

## 知识点

* $inc: 递加
* $mul: 相乘
* $rename: 修改字段名
* $set: 新增or修改字段
* $unset: 字段删除

## 实战演习

~~~bash
$ mongo
> use komablog;
> db.posts.find({title:"怪物猎人世界评测"}, {_id:0});
> db.posts.update({title:"怪物猎人世界评测"}, {$inc: {rank: 1}});
> db.posts.find({title:"怪物猎人世界评测"}, {_id:0});
> db.posts.update({title:"怪物猎人世界评测"}, {$mul: {rank: 2}});
> db.posts.find({title:"怪物猎人世界评测"}, {_id:0});
> db.posts.update({title:"怪物猎人世界评测"}, {$rename: {"rank": "score"}});
> db.posts.find({title:"怪物猎人世界评测"}, {_id:0});
> db.posts.update({title:"怪物猎人世界评测"}, {$set: {"istop": true}});
> db.posts.find({title:"怪物猎人世界评测"}, {_id:0});
> db.posts.update({title:"怪物猎人世界评测"}, {$unset: {"istop": true}});
> db.posts.find({title:"怪物猎人世界评测"}, {_id:0});
~~~



### 11. 文档的特殊更新

## 知识点

* upsert:有则更新，无则追加
  * 配置选项
* remove:条件删除数据

## 实战演习

~~~bash
$ mongo
> use komablog;
> db.posts.find({}, {_id:0});
> db.posts.update({title:"其实创造比大志好玩"}, {title:"其实创造比大志好玩", "rank":5,"tag":"game"});
> db.posts.find({}, {_id:0});
> db.posts.update({title:"其实创造比大志好玩"}, {title:"其实创造比大志好玩", "rank":5,"tag":"game"}, {upsert:true});
> db.posts.find({}, {_id:0});
> db.posts.update({title:"其实创造比大志好玩"}, {title:"其实创造比大志好玩", "rank":7,"tag":"game"}, {upsert:true});
> db.posts.find({}, {_id:0});
> db.posts.remove({title:"其实创造比大志好玩"});
> db.posts.find({}, {_id:0});
~~~


# 12. 使用索引

## 知识点

* 获取索引：getIndexes()
* 创建索引：createIndex({...}, {...})
  * 第一个参数填写索字段名，其value为 `1` 或 `-1` 代表该索引按照升序或者降序排序
  * 第二个参数为可选项，填写 `{unique: ture}` 可以将该索引设置为unique索引
* 删除索引：dropIndex({...})

## 实战演习

~~~bash
$ mongo
> use komablog;
> db.posts.getIndexes();
> db.posts.createIndex({rank:-1});
> db.posts.getIndexes();
> db.posts.dropIndex({rank:-1});
> db.posts.getIndexes();
> db.posts.createIndex({title:1}, {unique:true});
> db.posts.getIndexes();
> db.posts.find({}, {_id:0});
> db.posts.insert({title:"怪物猎人世界评测"});
~~~



# 13. 备份和恢复

## 知识点

> `mongodump` 和 `mongorestore` 都是系统指令

* 备份：mongodump
* 恢复：mongorestore

## 实战演习

~~~bash
$ mongo
> show dbs;
> use komablog;
> db.posts.find({}, {_id:0});
> exit
$ mkdir dbbak
$ cd dbbak
$ mongodump -d komablog
$ ls
$ mongo komablog
> db.posts.find({}, {_id:0});
> db.posts.remove({});
> db.posts.find({}, {_id:0});
> exit
$ mongorestore --drop
$ mongo komablog
> db.posts.find({}, {_id:0});
> exit
$ mongodump --help
~~~


# 14. 来源声明

## 课程文件

https://gitee.com/komavideo/LearnMongoDB

## 小马视频频道

http://komavideo.com