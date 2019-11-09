---
title: 基于Canvas的FlappyBird小游戏开发总结
tags: [Canvas, 项目实战]
categories:
  - [Front, JS]
  - [Front, HTML]
date: 2019-05-15 22:05:26
---
[Github 源码地址](https://github.com/EsunR/FlappyBird-Canvas)  

[演示 Demo](https://www.esunr.xyz/git/FlappyBird/index.html)

# 掉落算法
我们现在要研究一个问题，就是某元素一开始位置是y=100，如果限制变化常数是8，此时第一帧变为y=1e8（变化8），第二帧变为y=124（变化16）。第三帧是y=156（变化32）

![](http://markdown.img.esunr.xyz/20190510210237.png)

```diff
img.onload = function () {
  setInterval(function () {
    ctx.clearRect(0, 0, 600, 600);
    f++;
    ctx.fillText(f, 20, 20);
    ctx.fillText(`isDropDown: ${isDropDown}`, 20, 40);

    if (isDropDown) {
+     dropf++
+     y += dropf * 0.35; // 每帧下落的距离
+     d += 0.07;  // 每帧旋转的弧度
    }

    ctx.save();
    ctx.translate(x, y); // 将坐标系拉到要绘制小鸟的位置
    ctx.rotate(d);  // 旋转坐标系
    ctx.drawImage(img, -24, -24); // 绘制小鸟
    ctx.restore();
  }, 20)
}
```

给界面设置一个 `isEnergy` 的参数，记录小鸟是否拥有能量。当点击屏幕时，小鸟拥有能量，等小鸟上飞一段时间后小鸟失去能量，之后小鸟开始下落。

那么上升的这段距离，与掉落的公式不同，应该为：

```diff
- y += dropf * 0.35;
+ y -= (20 - dropf) * 0.35;
```

`dropf` 为小鸟自身动画的帧编号， `y` 为小鸟在画布上的y轴坐标。当小鸟开始上升，y的值需要线性减小。

当 `drop < 20` 时，`(20 - dropf) * 0.35;` 是一个正数，y越减越小，说明小鸟开始下落。但当 `drop > 20` 时，`(20 - dropf) * 0.35;` 的值是一个负数，y越减越大，说明小鸟又开始下落了，就会产生如下效果：

![](http://markdown.img.esunr.xyz/垃圾箱.gif)

这说明：**小鸟上升了20帧后，开始进行掉落。**

那么我们结合掉落算法与 `hasEnergy` 进行小鸟能量状态的判断，当用户点击Canvas时，小鸟获取能量（hasEnergy == true），之后小鸟上飞一段距离，失去能量（hasEnergy == false），同时进行小鸟头部旋转的调整。

在此要注意，我们要控制 `dropf` 何时归零，因为 `dropf` 控制了每帧小鸟移动的距离，即控制了小鸟的速度，拥有能量和失去能量时，小鸟的速度都需要初始化，即把 `dropf` 归零，我们在以下情况下需要将 `dropf` 归零：

1. 用户点击Canvas时，小鸟获取能量，上升速度初始化
2. 小鸟准备下落时，`hasEnergy` 改为 `false`，同时小鸟需要以初始速度下落。

这部分的代码入下
```javascript
// ... ...
var dropf = 0;
var hasEnergy = false; // 能量状态
// ... ...

img.onload = function () {
setInterval(function () {
  // 清屏... ...
  
  dropf++
  // 鼠标点击屏幕，会给小鸟传递能量
  if (!hasEnergy) {
    // 如果没有能量，小鸟掉落并旋转
    y += dropf * 0.6;
    d += 0.05;  // 每帧旋转的弧度
  } else {
    // 如果有能量，小鸟先想上飞，再掉落
    y -= (20 - dropf) * 0.35; // 每帧下落的距离
    d -= 0.03;
    if (dropf > 20) {
      // 如果向上飞了20帧，就让小鸟失去能量重新开始下落
      hasEnergy = false;
      // 下落时小鸟帧设置为0,归为下落速度的初始值
      dropf = 0;
    }
  }

  // 绘制小鸟... ...
}, 20)

canvas.addEventListener("click", function () {
  hasEnergy = true;
  // 下落前小鸟帧设置为0,归为上升速度的初始值
  dropf = 0;
  d = 0;
})
```


# 碰撞检测
管子和小鸟的碰撞，会导致游戏结束，就要检测碰撞。
类和类之间如何通信？

- 类和类之间没有第三方，需要通过发布订阅模式（观察者模式）
- 类和类之间有一个中介者，比如这个游戏，此时非常简单，直接通过中介者就能找到对方，比如：
   ```javascript
   game.bird.x;
   game.bord.y
   ```

因为鸟只有一个，用管子去检查鸟非常方便，所有碰撞检测是管子的方法，管子每一帧都要检测自己是不是撞到鸟了。使用AABB盒来进行碰撞检测，就是一个矩形的包围盒。 

> AABB盒： AABB盒，一个3D的AABB就是一个简单的六面体，每一边都平行于一个坐标平面，矩形边界框不一定都是立方体，它的长、宽、高可以彼此不同。坐标轴平行（Axially-aligned）不仅指盒体与世界坐标轴平行，同时也指盒体的每个面都和一条坐标轴垂直，这样一个基本信息就能减少转换盒体时操作的次数。AABB技术在当今的许多游戏中都得到了应用，开发者经常用它们作为模型的检测模型。但是，提高精度的同时也会降低速度。 

对小鸟和管子进行碰撞检测，分表需要考虑到小鸟的三个边与管子的三个边之间的关系，分为以下两种情况：

1. 小鸟与上管子碰撞时

![20190513150421.png](http://img.cdn.esunr.xyz/markdown/20190513150421.png)

1. 小鸟与下管子碰撞时

![20190513150827.png](http://img.cdn.esunr.xyz/markdown/20190513150827.png)

其中，将相同项合并之后，得出只要满足如下结果，就说名小鸟与管子发生碰撞：

```
鸟.R > 上管.L 且
鸟.L < 上管.R 且
鸟.T < 上管.B 或 鸟.B〉下管.T
```

再分析管子 LBRT 的各个值：对于管子来说，管子L就是 `this.x` ，管子R就是 `this.x + 52` ，上管子B就是 `this.height` ，下管子T就是`this.height + this.kaikou` 。

![20190513152915.png](http://img.cdn.esunr.xyz/markdown/20190513152915.png)

最终我们总结出如下规则：
```javascript
if (game.bird.R > this.x && game.bird.L < this.x + 52) {
  if (game.bird.T < this.height || game.bird.B > this.height + this.kaikou) {
    console.log("BOOM!");
  }
}
```

# 计数器处理

对不同位数字要进行不同的处理，处理方式如下：

![20190513171916.png](http://img.cdn.esunr.xyz/markdown/20190513171916.png)

在 Game 类的主循环中添加：

```javascript
var scoreLength = this.score.toString().length;
for (var i = 0; i < scoreLength; i++) {
  this.ctx.drawImage(this.R['shuzi' + this.score.toString().charAt(i)], this.canvas.width / 2 + 32 * (i - scoreLength / 2), 100);
}
```

当小鸟通过管子后，需要让 Game 类上挂载的 `score` +1 ，之后再利用函数节流的思想，在 Pipe 类上定义一个 `alreadPass` 用来判断是否让 `score` 进行增加操作，在 Pipe 类的 `update` 函数中加入如下代码：
```javascript
// 如果小鸟通过管子就加分
if(game.bird.L > this.x + 52 && !this.alreadPass){
  game.score ++ ;
  this.alreadPass = true;
}
```

# 场景管理器

FlappyBird中有三个场景：欢迎界面、游戏界面、Gameover界面。

三个场景的业务、逻辑、监听完全不一样。

所以我们可以用场景管理器来负责管理自己当前场景的演员的更新和渲染。

![场景管理器](http://img.cdn.esunr.xyz/markdown/20190513194730.png)

Game类说起，此时Game不要负责渲染背景、小鸟、大地、管子了。而是仅仅负责渲染、更新场景管理器。

```diff
// 游戏主循环
  this.timmer = setInterval(() => {
    // 清屏
    this.ctx.clearRect(0, 0, this.canvas.height, this.canvas.width);

-   // 渲染、更新所有的演员和渲染所有的演员
-   _.each(this.actors, function (actor) {
-     actor.update();
-     actor.render();
-   })

-   // 每40帧渲染一组管子
-   if (this.f % 100 == 0) {
-     this.pipe = new Pipe();
-   }
-   
-   // 打印分数
-   var scoreLength = this.score.toString().length;
-   for (var i = 0; i < scoreLength; i++) {
-      this.ctx.drawImage(this.R['shuzi' + this.score.toString().charAt(i)], this.canvas.width / 2 + 32 * (i - scoreLength /-2), 100);
-   }

+   // 场景管理器的渲染
+   this.sm.update();
+   this.sm.render();

    // 打印帧编号
    this.printFix();

    
  }, 20)
}
```

场景管理器有三个方法 `enter()` 、 `update()` 、 `render()` 。其中定时器在每帧执行 `update()` 方法和 `render()` 方法。

使用 `enter()` 方法由业务来调动：

- 场景1：进入游戏，玩家可以点击开始菜单
- 场景2：准备开始游戏，向玩家展示游戏教程
- 场景3：开始游戏，玩家操作小鸟游玩
- 场景4：小鸟死亡，开始掉落，播放死亡动画
- 场景5：显示“Game Over”文字提示，用户点击界面可重新返回场景1