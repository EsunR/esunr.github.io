---
title: 基于Three.js实现的跳一跳小游戏开发日志
tags:
  - Canvas
  - 微信小程序
categories:
  - 项目日志
date: 2019-09-03 20:45:21
---

# 说明

项目用到的技术有 

- ES6
- Canvas
- ThreeJS
- WebGL
- 微信小游戏开放能力

[关联项目](https://github.com/EsunR/JumpToJump)

# MVC模式概览

![MVC.jpg](http://img.cdn.esunr.xyz/MVC.png)

# Camera 相机

> src/scene/camera.js

Camera 是场景的一部分，采用单例模式，游戏中只存在一个相机实例。

游戏中的相机采用 `OrthographicCamera` 正交相机，初始时相机的位置为空间坐标下的 `(-10, 10, 10)`，眺望点为世界坐标轴中心。

同时相机的可视空间范围由视锥大小与手机屏幕成比例计算，视锥标准值存放于 `scene-conf.js` 文件中，计算公式如下：

```js
this.instance = new THREE.OrthographicCamera(
  -sceneConf.frustumSize, // left
  sceneConf.frustumSize, // right
  sceneConf.frustumSize * aspect, // top 
  -sceneConf.frustumSize * aspect, // bottom
  -100, 85
)
```

# Scene 场景

> src/scene/scene.js

Scene 是场景管理器，采用单例模式，因为游戏中只存在一个 Scene，导出的即为一个实例化后的场景，其 `THREE.Scene` 实例挂载在 `instance` 对象上。

在 `init()` 函数中进行场景的初始化，主要负责实例化 `THREE.Scene`，将相机、光线这些全局的元素引入到场景中，并进行初始化等操作。

在系统定义的 Scene 中，主要是用于管理整个场景的变化。同时涉及光线与相机的操作（如相机的位移），必须作为 Scene 的方法，在外部调用 Scene 实例的方法，从而进行操作与更改，这样做的好处是能够将操作更加集中，并且减少重复的函数编写。

> 由于分数是在相机坐标系上添加的，所以也必须在 Scene 上定义分数更新、添加的操作（因为这些操作设计操作到相机实例）

若是在场景中添加物体，则可以使用 `scene.instance.add()` 方法将物体直接添加到场景中，如果在，这也是场景管理器的重要作用之一。

# Light 光线

> src/scene/light.js

光线是场景的一部分，采用了单例模式，游戏中只存在一个光线实例。在场景中存在两种光线，环境光（AmbientLight）与平行光（DirectionalLight）。

由于游戏中的光直接照射地面阴影效果不好，所以在场景中定义了一个平面作为光照的目标，这个平面在 (x, y) 平面之上。

![20190906143045.png](http://img.cdn.esunr.xyz/markdown/20190906143045.png)

# 动画系统

> lib/animation.js
 
`animation.js` 是一个动画工具库，该 js 文件向外暴露了 `customAnimation` 对象以及 `TweenAnimation()` 方法。

`customAnimation.to()` 方法是建立用户动画的主要方法，其有如下几个参数：

```
(customAnimation.to function)(duration: any, from: any, to: any, type: any, delay?: number, complateCallback: any): void

duration: 动画时长
from: 动画操作对象的属性，如 bottle.instruction.position
to: 动画结束后操作对象的属性值
type: 动画类型，具体见 tween.js
delay: 动画延时（可选，默认为0）
complateCallback：动画结束后的回调函数（可选）
```

在 `customAnimation.to()` 内部调用了 `TweenAnimation()`，该方法负责了当前时刻所操作物体属性的具体值，其内部主要做了如下的操作：

1. 对方法参数的检测，由传入的参数来获取动画的计算函数；
2. 预计算动画在传入时间内需要渲染的帧数，并将标识参数重置；
3. 对每一帧进行绘制，通过两帧动画绘制的时间间隔求出当前的帧率； `fps = Math.ceil(1000 / interval)`
4. 当fps小于30时，对动画进行补帧，将帧数标识符累加到当前时刻应渲染的数量； `increment = Math.floor((interval / 17))`
5. 如果帧率大于30fps，执行回调函数，将当前计算的数值计算结果返回；
6. 检查是否所有动画帧都已经渲染完毕，如果未渲染完毕，使用 `requestAnimationFrame()` 执行自身函数。

简单的工作流如下：

![20190906150614.png](http://img.cdn.esunr.xyz/markdown/20190906150614.png)

# 瓶身跳跃

Bottle的跳跃实际上是在一个方向向量上的移动，获取了跳跃的方向向量，之后再计算跳跃的目标点，然后通过 `customAnimation.to()` 方法添加移动的动画，就可以完成一个跳跃效果。

### 计算向量

> gamePage.setDirection()

首先要获取跳跃的方向向量，其重点在于获取两个坐标：

- Bottle自身坐标
- 下一个Block的中心坐标

这两点之间的连线就可以确定Bottle的移动方向。Bottle自身坐标可以通过 `position` 属性来获得，我们将其记为 `currentPosition` 挂载与 game-page 实例上，而下一个Block的中心坐标就是该Block生成时的坐标，在生成下一个Block时将其坐标信息记为 `targetPosition` 挂载于 game-page 实例上。之后通过 `THREE.Vector3()` 将两点转化为一个向量信息，在通过 `normalize()` 方法将其转换为一个单位向量，将单位向量传入到 bottle 实例的 `setDirection()` 方法中，由方法内部将信息挂载到 bottle 实例上。之后，可以调用 bottle 实例上的 `axis` 属性以及 `direction` 属性来获取跳跃的方向信息。

之后拥有了跳跃方向后，通过计算 touchstart 事件与 touchend 事件之间的时间间隔，即可以按照公式计算出竖直上抛运动的初始速度vy与vx，将其挂载与 bottle 实例上的 `velocity` 属性中，将其用于计算。

### 计算公式

> src/object/bottle.js

水平方向的计算公式为：`translateH = vx * △t`

竖直方向的计算公式为：`translateY = vy * △t- 0.5 * gravity * △t * △t - gravity * flyingTime * △t`

只要将水平方向的移动增量加上方向向量，就可以在水平方向上移动Bottle瓶身：`this.obj.translateOnAxis(this.axis, translateH)`

竖直方向则只需变换Y轴坐标位置即可：`this.obj.translateY(translateY)`

# 预判及碰撞检测

> gamePage.getHitStatus()

当用户按压屏幕时，Bottle以及Block开始进行压缩的动画，用户将手指移开屏幕即发生 `touchend` 事件时，就开始使用 `getHitStatus()` 方法进行Bottle的落地点预判。

预判主要为了给Bottle每次跳跃的状态，以下几个常量用来定义Bottle跳跃后的状态：

```js
// game-page.js
const GAME_OVER_NORMAL = 0 
const HIT_NEXT_BLOCK_CENTER = 1 
const HIT_CURRENT_BLOCK = 2 
const GAME_OVER_NEXT_BLOCK_BACK = 3
const GAME_OVER_CURRENT_BLOCK_FRONT = 4
const GAME_OVER_NEXT_BLOCK_FRONT = 5
const HIT_NEXT_BLOCK_NORMAL = 6
```

通过公式计算出Bottle的预估落地点后，通过 **射线法** 来计算落地点是否在Block上，根据不同的结果可以将Bottle的跳跃结果定义为以上的常量。但要注意的是Bottle有可能仍落在当前的Block上，所以进行射线法判定跳跃点时，既要判断 `nextBlock` 又要判断 `currentBlock`。

关于射线法的计算，需要得到所计算Block的上平面顶点坐标，具体的计算方法挂载在Block的抽象类上（src/block/base.js），调用 `block.getVertices()` 即可获取平面的四个顶点数组用于射线法的计算。关于射线法的具体算法存放在 `src/utils/index.js` 的 `pointInPolygon()` 方法中。

# 计分系统

> src/view3d/scoreText

计分系统需要使用到字体文件，字体文件存放在 `src/view3d/font.js` 文件下。

在 `font.js` 中，使用 `import` 引入一个单独的 THREE JS 可以防止缺少依赖。font 字体为 json 格式，将其存放在 `font` 变量中后，使用 `new THREE.Font(font)` 实例化一个字体对象 `fontObj`。将字体对象导出后，就可以提供给外部使用。

```js
import * as THREE from '../../libs/three.js'
const font = {...}
const fontObj = new THREE.Font(font)
export default fontObj
```

拥有字体文件后，需要有字体实例可以添加到游戏中，这里使用工厂模式，向外提供一个字体对象，将 THREE JS 字体对象绑定在 `instance` 属性上：

```js
init(options) {
  this.material = new THREE.MeshBasicMaterial({
    color: (options && options.fillStyle) ? options.fillStyle : 0xffffff,
    transparent: true
  })
  if (options && options.opacity) {
    this.material.opacity = options.opacity
  }
  this.options = options || {}
  const geometry = new THREE.TextGeometry('0', {
    "font": font,
    "size": 6.0,
    "height": 0.1
  })
  this.instance = new THREE.Mesh(geometry, this.material)
  this.instance.name = 'scoreText'
}
```

由于文字随着分数的增加而不断增加，所以在 ScoreText 上要挂载一个 updateScore 的方法来替换 instance 实例，生成一个新的文字，之后再通过场景管理器，将原有的文字删除，重新添加上新的文字实例。其内部过程如下：

![20190902200721.png](http://img.cdn.esunr.xyz/markdown/20190902200721.png)


# 暂停动画的逻辑

在动画函数库中设置两个标识符，`animationId` 与 `stoppedAnimationId`。

- `animationId`：用于记录动画ID，每次动画赋予ID都是在这个值上累加
- `stopAnimationId`：标记被暂停的动画

当一个动画被创建后（`TweenAnimation` 函数中），会被赋予一个动画ID：

```js
// animation.js
const selfAnimationId = ++animationId
```

同时设定一个判断条件，如果当前的动画 ID 小于 `stoppedAnimationId`，就跳过动画的执行：

```js
// animation.js
if (start <= frameCount && selfAnimationId > stoppedAnimationId) {
  options.callback(value)
  requestAnimationFrame(step)
} else if (start > frameCount && selfAnimationId > stoppedAnimationId) {
  // 参数true用于检测该回调是否是完成时的回调函数
  options.callback(to, true)
}
```

这个停止动画的操控在 `StopAllAnimation()` 方法中执行：

```js
// animation.js
export function StopAllAnimation() {
  stoppedAnimationId = animationId
}
```

外部调用这个方法可以停止当前场景中的所有动画

# 场景复位

在跳跃场景中，场景中所有的物体都会产生位移，包括Bottle、地面、光线、相机等，同时还会生成大量的Block，当游戏结束时需要对场景进行复位。

最简便的操作是将场景中的所有物体移除，game-page 实例上的 `restart()` 方法负责处理重置场景，其中主要进行了如下几个操作：

- 调用 `bindTouchEvent()` 将场景切换时移除的事件重新绑定
- 调用 `deleteObjectsfromScene()` 将场景中所有物体的删除，其中Block的删除操作需要进行遍历删除
- 调用各场景物体对象上的 `init()` 方法，对单个场景物体的参数进行重置
- 重新将移除的场景物体加入到场景中
- 对分数计数器进行重置

# 粒子系统 Particles

瓶身跳跃时会出现粒子聚合效果，当瓶身落下时会出现粒子发散效果。

如果要想创建一个粒子效果，则需创建单个粒子个体，将粒子作为瓶身的一部分，添加到瓶身的 Object3D 对象上，构建单个粒子个体的过程在 `bottle.js` 的 `init()` 方法中。

其中粒子贴图分为两种：绿色粒子与白色粒子，其中负责聚合效果的粒子有20个，负责散发效果的粒子有10个。这些粒子在未使用状态下时是不可见的，同时每个粒子贴图都附着在一个独立存在的宽高为2的 PlaneGeometry 对象上，所以实际上粒子只是一个朝向相机的平面贴图。

同时，每个粒子实体上挂载了两个属性：`gathering` 与 `scattering`，分别用来设置当前粒子的状态是正在执行聚合动画还是正在执行发散动画。

### 粒子聚合 Gather

![20190905110518.png](http://img.cdn.esunr.xyz/markdown/20190905110518.png)

`bottle.js` 中的 `gatherParticles()` 方法负责控制粒子的聚合效果，其内部调用 `_gatherParticles(particle)` 负责每个粒子的具体动画效果的展现。

`gatherParticles()` 将每个粒子的 `gathering` 属性设置为 `true`，意味着当前粒子正在执行聚合动画，之后将执行聚合动画的单个粒子实例传入到 `_gatherParticles(particle)`，在这里通过定时器将动画设置为分为两批执行。

`_gatherParticles(particle)` 控制单个粒子实例，将单个粒子位置与大小在一定范围内的随机初始化，其中粒子出现的距离范围为`(1, 8)`，缩放的大小范围为`(1, 1.8)`，且只随机出现在瓶身底部平面之上的四个象限内。设置了初始位置之后，开始在随机一段时间后执行聚合动画，当粒子的聚合动画执行完毕后，会检测当前瓶身的状态，如果 `bottle.gathering === true`，则表明粒子聚合动画仍在执行，则重新调用 `_gatherParticles(particle)`，直到 `bottle.gathering !== true`，停止粒子的运动。

为了停止粒子的运动，使用 `resetGatherParticles()` 方法，将粒子队列中所有的粒子 `gathering` 属性设置为 `false`。

当用户按压屏幕，在瓶身进行 `shrink` 的过程时执行 `gatherParticles()` 开始聚合粒子。当用户手指离开屏幕，在瓶身进行 `flying` 的过程时执行 `resetGatherParticles()` 停止聚合粒子。

### 粒子发散 Scatter

![20190905110609.png](http://img.cdn.esunr.xyz/markdown/20190905110609.png)

与粒子聚合相似，在 `bottle.js` 中 `scatterParticles()` 负责设置粒子的聚合状态，在这里只使用10个白色粒子完成发散动画即可。
 
`_scatterParticle(particle)` 负责单个粒子实体进行发散动画，在初始化过程中，其距离的设置与聚合粒子不一样，由于其贴近瓶身发散，所以粒子距瓶身的距离更近，距离范围为 `(1, 2)`。同时其动画执行的时间更短，运动的距离更远。

由于粒子发散的动画是单次的，所有粒子在动画执行完毕后即可将自身的 `scattering` 与 `visiable` 属性设置为 `false`，无需要重复调用自身动画。

# UI绘制

场景切换可以通过MVC系统，调用每个页面实例中传入的callbacks，从而切换游戏主场景与游戏菜单UI。

UI通常是二维平面，所以我们可以将UI的绘制转为2d Canvas的绘制。在 ThreeJS 中，可以将一个2d的离屏 Canvas 作为纹理绘制到一个3D平面上，这利用到了 ThreeJS 的 CanvasTexture，示例如下：

```js
// 创建一个离屏Canvas
this.canvas = document.createElement('canvas')
this.canvas.width = this.width
this.canvas.height = this.height

// 创建一个3D平面
this.texture = new THREE.CanvasTexture(this.canvas)
this.material = new THREE.MeshBasicMaterial({ map: this.texture, transparent: true });
this.geometry = new THREE.PlaneGeometry(sceneConf.frustumSize * 2, aspect * sceneConf.frustumSize * 2)
this.obj = new THREE.Mesh(this.geometry, this.material)

// 获取离屏Canvas的上下文对象
this.context = this.canvas.getContext('2d')
```

要注意的是，作为UI使用的离屏Canvas出现的相对坐标不是世界坐标系，而是相机，因为UI始终是正对相机的，所以我们将绘制了UI的平面添加到相机对象上，同时设置其位置属性，让其在相机的可视范围内：

```js
this.camera.add(this.obj)
this.obj.position.z = 80
```




