---
title: Sequelize 一对多关系及多表的级（tao）联（wa）查询
tags: [Sequelize]
categories:
  - Back
  - Node
date: 2020-02-21 12:59:43
---

# Sequelize 建立一对多关系

首先我们假设这么一个场景：

在一个宿舍管理系统种，Building 表记录了宿舍楼的信息，Floor 表记录了宿舍楼层的信息，Room 表记录了宿舍房间的信息，CleanRecord 表记录了房间的打扫信息。其中 CleanRecord 表通过 roomId 关联 Room 表，Room 通过 floorId 关联 Floor 表，Floor 通过 buildingId 关联 Building 表，其可视化关系表现如下。

![](http://img.cdn.esunr.xyz/markdown/20200221132951.png)

以 Building 与 Floor 为例，一栋宿舍楼种又多个楼层，所以宿舍楼与楼层之间是 1:n 的关系，而对于一个楼层来说，它只归属于一栋宿舍楼，所以楼层于宿舍楼之间是 1:1 的关系。我们也可以依次得出 Record 于 Room 之间的关系，Room 与 Floor 之间的关系。

我们利用 Sequelize 依次建立各个表的 Model：

```js
const { Model } = require("sequelize")

class Record extends Model {}
Record.init(
  {
    time: {
      type: DataTypes.DATE
    }
  },
  {
    sequelize: db.sequelize,
    modelName: "Record",
    paranoid: true
  }
)

class Record extends Model {}
Record.init(
  {
    number: {
      type: DataTypes.INTEGER,
      comment: "房间号",
      unique: "compositeIndex"
    }
  },
  {
    sequelize: db.sequelize,
    modelName: "cleanRecord",
    paranoid: true
  }
)
// ... ... 省略建立 Floor 与 Building ... ...
```

之后我们要为各个表之间进行关联，才可以在系统种创建该表。对于一对多关系，sequelize 在 Model 上存在 `hasMany()` 方法与 `belongsTo()` 方法，分别是在**目标**上建立外键与在**源**上建立外键，根据我们设计好的关系，我们建立如下连接：

```js
Building.hasMany(Floor)
Floor.hasMany(Room)
Room.hasMany(Record)
```

这样一对多关系就建立好了，在每个一对多 (1:n) 关系种，1 的一方的 Model 实例上都挂载了相应的 get 方法与 set 方法，可以调用归属于其下的子数据，如：

```js
const room = await Room.findOne({ where: {id: 1} })
let records = await room.getRecords() // 获取 id 为 1 的房间下的所有记录
```

虽然这样建立了 Building 与 Floor 的关系，并可以通过 Building 查询到相应的 Floor 列表，但是 Floor 与 Building 之间并未建立起关系，我们无法通过 Floor 找到对应的 Building，其他的表也是如此。这是因为我们仅仅建立了一组单向的关系，要想让双方都可以查找到彼此，那么必须建立一个双向关系。

通过前面的分析，Floor 与 Building 之间、Room 与 Floor 之间、Record 与 Room 之间都是 1:1 的关系，对于一对多关系，sequelize 在 Model 上存在 `belongsTo()` 与 `hasOne()` 方法，分别是在**源**上建立外键与在**目标**上建立外键。根据我们设计好的关系，我们再来进行 1:1 关系的关联：

```js
Floor.belongsTo(Building)
Room.belongsTo(Floor)
Record.belongsTo(Room)
```

同时，其源模型的实例上也创建了相应的 get 与 set 方法：

```js
const room = await Room.findOne({ where: {id: 1} })
const floor = await room.getFloor() // 获取 room 归属的楼层
```

# 2. 级联查询

在上述关系下，我们可以使用级联查询来连接各个表，用到了查询的 `include` 选项，比如我们要查找 Rocrd 与 Room 信息的完整数据：

```js
const records = await Record.findAll({ include: [{model: Room}] })
```

那么在每条记录下就会产生一个 room 字段来存放房间相关的信息，records 的值为：

```js
[
  {
    id: 1,
    time: "xxxx-xx-xx",
    roomId: 1,
    room: {
      id: 1,
      nnumber: 101,
      floorId: 1
    }
  },
  // ... ...
]
```

`include` 种还可以嵌套 `include`，形成 `A表连接（B表连接C表）` 的效果，如：

```js
const records = await Record.findAll({ 
  include: [{
    model: Room,
    include: [{
      model: Floor,
      include: [{
        model: Building
      }]
    }]
  }] 
})
```

这样查询的结果就十分套娃了：

```js
[
  {
    id: 1,
    time: "xxxx-xx-xx",
    roomId: 1,
    room: {
      id: 1,
      number: 101,
      floorId: 1,
      floor: {
        id: 1,
        layer: 1,
        buildingId: 1,
        building: {
          id: 1,
          name: "于心苑"
        }
      }
    }
  },
  // ... ...
]
```

多表联合查询也可以过滤条件，假如我们想通过多表连接的方式查找某个 id 为 2 房间的所有打扫记录，那么在 `include` 添加 `where` 条件也可以过滤出结果：

```js
const records = await Record.findAll({ 
  include: [{
    model: Room,
    where: {id: 1}  
  }]
})
```

> 相当于直接使用 rooms.getRecords()

那么如果我们想查找某层楼的所有宿舍的打扫记录应该如何查（tao）找（wa）呢？那就是在嵌套的 include 中添加 where 条件：

```js
const records = await Record.findAll({ 
  include: [{
    model: Room,
    include: [{
      model: Floor,
      where: { id: 2 }
    }]
  }] 
})
```

但是这样查找却会发现结果如下：

```js
[
  {
    id: 1,
    time: "xxxx-xx-xx",
    roomId: 1,
    room: null
  },
  {
    id: 2,
    time: "xxxx-xx-xx",
    roomId: 2,
    room: {
      id: 2,
      nnumber: 202,
      floorId: 2,
      floor: {
        id: 2,
        layer: 2,
        buildingId: 1
      }
    }
  },
  // ... ...
]
```

我们发现不符合条件的结果也别查出来了，但是 room 字段是 null。我们来分析一下当前执行连接查询的方式是：**Record 连接查询 (Room 连接查询 Floor)**，也就是 (A & (B & C))。执行查询过程中是 Room 连接查询 Floor 后生成的新表再与 Record 表进行连接查询。我们只过滤了 Room 表连接查询 Floor 表的结果，但为过滤生成的新表与 Record 表的结果，所以会产生一个空记录。

我们将查询语句中添加一个判断连接的新表的 roomId 不能为 null：

```js
const records = await Record.findAll({ 
  include: [{
    model: Room,
    where: { id: { [Op.isNot]: null } },
    include: [{
      model: Floor,
      where: { id: 2 }
    }]
  }] 
})
```

这下查询结果就正常：

```js
[
  {
    id: 2,
    time: "xxxx-xx-xx",
    roomId: 2,
    room: {
      id: 2,
      nnumber: 202,
      floorId: 2,
      floor: {
        id: 2,
        layer: 2,
        buildingId: 1
      }
    }
  },
  // ... ...
]

```