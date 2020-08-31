---
title: 从WebGL谈起到react-three-fiber
tags: [React, 图形学]
categories:
  - Front
  - React
date: 2020-08-31 10:24:48
---

# 1. WebGL

## 1.1 何为 WebGL

在探讨什么是 WebGL 之前我们需要先来了解一下 OpenGL。

在早期的计算机上，绘制 3D 图像需要单独针对与一种硬件与一种操作系统进行“定制化”的编程，然而这样的开发成本无疑是巨大的。因此出于减少开发成本，关爱程序员发际线的人道主义精神，OpenGL 诞生了。OpenGL 被定义为是一个用于渲染2D或者3D矢量图形的跨语言、跨平台的应用程序编程接口，对于 OpenGL 硬件层面的具体实现都交给了显卡的生产厂商，而开发者就只需要使用 OpenGL 的 API 就可以实现各种各样的图形操作了。

> Tips：跟 OpenGL 同级下可对比的还有很多人所熟知的微软 DirectX 开发套件。此外，各家用游戏主机平台也有其对应的图形 API，这些规范比 OpenGL 的出现要更早。

回归 WebGL，WebGL 就是 OpenGL 在互联网浏览器端的一种实现。更具体的来说，WebGL 是基于 OpenGL ES 的，其语法之间有相似与关联性，而 OpenGL ES 又是 OpenGL 在嵌入式以及移动端的改良优化版本，其属于 WebGL 规范的子集，简化了部分 API，其具体的关系详情可以参考下图：

![20190820205613.png](http://img.cdn.esunr.xyz/markdown/20190820205613.png)

WebGL 已经完全集成到浏览器的所有网页标准中，可将影像处理和效果的 GPU 加速使用方式当做网页 Canvas 的一部分，因此 WebGL 元素可以加入其他 HTML 元素之中并与网页或网页背景的其他部分混合。

在编程风格上，WebGL 程序由 **JavaScript 编写的句柄** 和 **OpenGL Shading Language（GLSL）编写的着色器代码** 组成（没错，是由两种语言构成）。GLSL 类似于 C 语言的风格，但其本身并非 C 语言，其可以在计算机的图形处理器（GPU）上运行。

> Tips: 在早期 GPU 尚未出现的时候 CPU 需要负责图形运算。但是随着图像处理技术的发展，3D 图形的计算量变得逐渐庞大，图形加速卡、显卡便应运而生。那些重复的图形运算工作都可以由 GPU 来进行运算了，而 CPU 就可以用来处理其他更加复杂且多元的任务，这就是 GLSL 为什么运行在 GPU 而非 CPU 的原因。

![20190820204937.png](http://img.cdn.esunr.xyz/markdown/20190820204937.png)

## 1.2 WebGL 核心概念

在 WebGL 的使用过程中，会牵涉到大量计算机图形学的相关概念，这些概念往往比较难懂，如果在刚开始没有办法理解，那么可以在后续的代码实现过程中，再回头来梳理这些概念。

### 1.2.1 着色器

在 OpenGL ES 2.0 中可以使用着色器编程，意味着可以调用显卡并行运算的能力，来进行业务中需要的开发。

着色器是使用我们上面所提及的 GLSL 语言所编写的程序，它携带着绘制形状的顶点信息以及构造绘制在屏幕上像素的所需数据，换句话说，它负责记录着像素点的位置和颜色。

着色器又分为 **顶点着色器（VertexShader）** 和 **片段着色器（FragmentShader）**，它们是两种不同的着色器函数，在开发者使用 GLSL 编写完着色器后，需要将其传递给 WebGL，使之在GPU执行时编译。

顶点着色器的作用是计算顶点的位置。根据计算出的一系列顶点位置，WebGL 可以对点、线和三角形在内的一些图元进行 **光栅化** 处理。当对这些图元进行光栅化处理时需要使用片段着色器方法。片段着色器的作用是计算出当前绘制图元中每个像素的颜色值。

> Tips：光栅化是指将构成图形的一系列的点进行上色，这是一个很重要的概念。

### 1.2.2 渲染管线

要在 WebGL 中绘制 3D 图形，需要经历一系列的过程，这一过程被称之为渲染管线，具体流程有如下几步：

- 初始化WebGL − JavaScript是用于初始化WebGL的上下文。
- 创建数组 − 我们创建JavaScript数组来保存几何数据。
- 缓冲区对象 − 通过将数组作为参数来创建缓冲区对象(顶点和索引)。
- 着色器 − 我们创建，编译和使用JavaScript链接着色器。
- 属性− 我们可以创建属性，启用它们并使用JavaScript缓冲区对象相关联。
- 制服− 我们还可以使用 JavaScript 制服(uniforms)关联。
- 变换矩阵 − 使用JavaScript，我们可以创建变换矩阵。

WebGL 渲染管线在 WebGL Api 下的执行过程如下图所示：

>  其中重要的操作就是通过 **透视除法（由WebGL底层实现）** 将 **裁剪坐标系** 转化为 **规范化的设别坐标系** 中 

![20190820212148.png](http://img.cdn.esunr.xyz/markdown/20190820212148.png)

### 1.2.3 缓冲区

buffer 是一个重要的概念，开发者在 js 中定义的坐标不能够直接使用，必须将原数据绑定到一个顶点着色器 buffer 中，再将这个顶点着色器与 WebGL 绑定，获取到在 GLSL 语言编写的着色器代码变量，buffer 可以自动将开发者编写的2d坐标转化为三维坐标点，再传入着色器代码中。

### 1.2.4 矩阵运算

在图形的世界中，图形的位置实际上就是图形上各个顶点在某一向量上的位移。那么如果我们能找出点的变化的规律，那就可以将其抽象化为一个变换公式，让计算机去实现动画以及复杂图像的渲染。

在大学高等数学的几何部分，我们已经学过在笛卡尔坐标系中如何对点的坐标进行变换，在线性代数中，我们得知这些变换的过程我们都可以使用矩阵来表示。实际上，矩阵的本质就是运动的描述，在线性空间中，向量描述对象，矩阵描述对象的运动，矩阵乘法对该对象施加运动。对于平移来说，我们还需要引入齐次坐标的概念，而这些概念无论是在二维的或是在三维的坐标中都是通用的。

> Tips: 一切复杂的变换过程都可以简化为多个合成变换，这是一个非常重要的思想。

对于线性代数的讨论因为笔者能力有限，本章不再继续讨论。在图形学中，最常见的移动为平移与绕轴旋转，他们的常用计算公式如下：

**在平面平移时的矩阵计算：**

![20190821151121.png](http://img.cdn.esunr.xyz/markdown/20190821151121.png)

**在旋转时的矩阵运算：**

![20190821151156.png](http://img.cdn.esunr.xyz/markdown/20190821151156.png)

**绕轴渲染的矩阵运算：**

![20190821151215.png](http://img.cdn.esunr.xyz/markdown/20190821151215.png)

![20190821151248.png](http://img.cdn.esunr.xyz/markdown/20190821151248.png)

## 1.3 使用 WebGL

在阐述过 WebGL 基础概念之后，我们就可以利用这些概念来进行编码了，以下将具体的演示如何实现 WebGL 的整个渲染管线，并最终绘制一个旋转的三角形。

### 1.3.1 Shader 的创建与绑定绑定流程

第一步的标题就很唬人，其实换句简单的话来说，就是我们要创建在上文中讲到的两种 Shader（顶点着色器、片元着色器）并将其绑定给 HTML 中的 WebGL 对象，让浏览器明白要绘制怎样的图像，并且让 Javascript 来控制整个渲染的流程，下文会一步一步的解释这个过程。

首先我们需要在 HTML 中创建一个 Canvas：

```html
<canvas id="myCanvas" width="400" height="400">Ops! 你的浏览器不支持 Canvas</canvas>
```

从 HTML 跳回到我们的 Javascript，要想使用 WebGL，我们就需要收件创建一个 WebGL 类型的 Canvas，并获取到其上下文，以便后续的操作：

```js
var canvas = document.getElementById('myCanvas')
var gl = canvas.getContext('webgl')
console.log(gl)
```

那么接下来我们就需要使用 WebGL 的 API 来定义顶点着色器（VertexShader）和片元着色器（FragmentShader）了，这一步会使用到一些陌生的 WebGL API：

```js
// 创建和初始化一个 WebGLProgram 对象
var program = gl.createProgram()

// 定义变量用于存放 GLSL 代码
// 【注意，我们在这里先只定义了变量，并未对他们进行赋值，这两个变量在接下来将用于存放顶点着色器以及片元着色器的 GLSL 的代码片段】
var VSHADER_SOURCE, FSHADER_SOURCE

// shader 应该包含两部分:
// 一部分是 context WebGL api 定义出来 shader
// 第二部分是 shader 本身的代码
function createShader(gl, sourceCode, type) {
  // 创建 shader（着色器）
  var shader = gl.createShader(type)
  gl.sourceCode(shader, sourceCode)
  gl.compileShader(shader)
  return shader
}

// 定义 vertex shader（顶点着色器）
var vertexShader = createShader(gl, VSHADER_SOURCE, gl.VERTEX_SHADER)
// 定义 frament shader（片元着色器）
var fragmentShader = createShader(gl, FSHADER_SOURCE, gl.FRAGMENT_SHADER)
```

只有将定义出的 shader （着色器）与主程序绑定之后，我们才可以来控制着色器绘制图像，之后我们要做的就是操控两种着色器对图像进行绘制。

```js
//  将着色器附加到 program 上
gl.attachShader(program, vertexShader)
gl.attachShader(program, fragmentShader)

// link program to context
gl.linkProgram(program)
gl.useProgram(program)
gl.program = program
```

### 1.3.2 定义着色器的GLSL代码

我们在上一步的代码中之定义了两个着色器的变量，未对他们进行赋值：

```js
var VSHADER_SOURCE, FSHADER_SOURCE
```

接下来本文将指引你如何编写一个 GLSL 代码，并将其赋值给两个变量。

在使用 GLSL 代码前，我们需要了解 GLSL 中的数据类型，在本示例中，需要用到的数据类型有三种：

1. `attribute` ：只能在 vertex shader 中使用的变量，一般用于顶点数据。顶点数据需要利用 WebGL 中的 Buffer 定义，将 Buffer 地址传递到顶点着色器，并且往对应的 Buffer 中传递顶点的数据。
2. `unifor` ：常量，不能被 shader 修改。uniform 变量在 vertex 和 fragment 两只之间的生命方式完全一样，则它可以在 vertex 和 fragment 共享使用（相当于一个可被共享的全局变量）通常用来传递变换矩阵、光线参数等。
3. `varying` ：varying 变量是 vertex 和 fragment shader 之间做数据传递用的



```diff
- var VSHADER_SOURCE, FSHADER_SOURCE

// 定义顶点着色器代码：
+ var VSHADER_SOURCE = `
+   // vec4 代表的是一个四维向量，我们在此定义一个名为 a_Poisiton 的变量
+   attribute vec4 a_Positon;
+   void main(){
+     // gl_Position 是 GLSL 内置的 api
+     gl_Position = a_Position;
+   }
+ `

// 定义片元着色器代码：
+ var FSHADER_SOURCE = `
+   void main(){
+     // 添加一个 rgba 值为 (1.0, 0.0, 0.0, 1.0) 的颜色【红色】
+     gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
+   }
+ `
```

> gl_position 的坐标并没内有经过透视除法的运算，所以其值为一个 vec4，vec4 的第四位参数是代表一个所放系数，用来产生近大远小的效果。

### 1.3.3 使用 buffer 向着色器代码中传值

我们已经定义好了着色器的代码，代码中也存在着变量，因此我们就需要考虑如何用 Javascript 来把值传递给这些变量，从而渲染出一个图形。

buffer 是一个重要的概念，开发者在 js 中定义的坐标不能够直接使用，必须将原数据绑定到一个顶点着色器 buffer 中，再将这个顶点着色器与 WebGL 绑定，获取到在 GLSL 语言编写的着色器代码变量，buffer 可以自动将开发者编写的 2d 坐标转化为三维坐标点，再传入着色器代码中。初始化代码示例如下：

```js
function initVertexBuffers(gl) {
  // 传入三角形的三个顶点到 vertices
  var vertices = new Float32Array([
    0, 0.5, -0.5, -0.5, 0.5, -0.5
  ])
  // 顶点个数
  var n = 3
  // 创建一个 buffer
  var vertexBuffer = gl.createBuffer()
  // 将 vertexBuffer 与 webgl 绑定
  gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer)
  // 将数据写入到 vertexBuffer 中
  gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW)
  // 获取变量 a_Position 在 vertex shader 中的地址
  var a_Position = gl.getAttribLocation(gl.program, 'a_Position')
  // 将 bufferData 传入到 a_Position 的地址，同时需要规定一个顶点对应数组中的几个数据
  gl.vertexAttribPointer(a_Position, 2, gl.FLOAT, false, 0, 0)
  // 启用 a_Position variable
  gl.enableVertexAttribArray(a_Position)
  return n
}
var n = initVertexBuffers(gl)
```

定义顶点时其坐标效如下：

![坐标](https://i.loli.net/2020/08/30/rnfVw21DCTUxEtg.png)

### 1.3.4 图像绘制

通过 buffer 将坐标数据传入顶点着色器后，已经在缓冲区生成了图像，但是图像尚未被渲染与视图上，之后需要进行一个绘制操作，首先需要清空画布，之后定义绘制的类型（如 TRIANGLES 类）、顶点数据的起始位、顶点个数就可以将图像绘制出来：

```js
gl.clearColor(0, 0, 0, 1)
// 调用clear方法将当前绘制结果清空
gl.clear(gl.COLOR_BUFFER_BIT)
// 按照三角形的图源去绘制，从 buffer 的起始位获取数据，绘制 n 个顶点
gl.drawArrays(gl.TRIANGLES, 0, n)
```

最终我们可以绘制出一个红色的平面三角形。

### 1.3.5 绘制动态的三角形

在上图中，我们绘制的时一个“看似”平面的三角形，实际上，其所在的空间是一个三维空间，我们可以在这个三维空间中对其进行旋转位移等操作。

假如我们想让我们绘制好的这个三角形绕 y 轴进行旋转，那么很简单，我们只需要为其创建一个旋转矩阵，在三维空间中，这个矩阵是 4x4 的，其数学表达可以表示如下：

![](https://i.loli.net/2020/08/30/ePYvRAFkmLBapVM.png)

转换为着色器的表达，那么就是在每次运行顶点着色其的代码时，让每一个顶点都与一个矩阵相乘，我么可以将顶点着色器改写为：

```js
var VSHADER_SOURCE =
  "attribute vec4 a_Position;\n" +
  "uniform mat4 u_ModelMatrix;\n" +
  "void main() {\n" +
  // 与一个矩阵相乘
  "  gl_Position = u_ModelMatrix * a_Position;\n" +
  "}\n";
```

之后利用 buffer 进行传参就可以将具体的矩阵传入了，如果想要动画效果，让其在试图内进行动态的旋转，那么我们可以利用 canvas 动画的原理，在每一帧渲染后清空画布，之后再重新执行渲染动作即可。具体的代码就不再复现，感兴趣的可以参考以下源码：

https://github.com/EsunR/JumpToJump/blob/master/Demo/webgl.js

# 2. ThreeJS

## 2.1 ThreeJS 概述

由于原生WebGL相对复杂，所以使用ThreeJS可以大幅减少开发成本，ThreeJS 将常用的 WebGL 表达式、算法、图形封装，以便开发者可以便捷使用，减少对 WebGL 复杂 api 的使用。

使用 ThreeJS 的优势：

- 弥补原生 WebGL 的缺乏抽象和模块化的缺点
- 简便图形学算法的实现
- 简化 GLSL 开发和调试，尽量避免使用 GLSL

缺点：

- 缺少自由度

以下是 ThreeJS 中封装的主要对象：

![](http://study.esunr.xyz/1577946595924.png)

## 2.2 渲染器 Renderer

在场景中设立了物体与光线以及相机后，需要渲染器将场景渲染出来。

Renderer要绑定一个canvas对象，实例化一个 Renderer 的过程如下：

```js
var canvas = document.getElementById("demo-canvas");
var renderer = new THREE.WebGLRenderer({
  canvas: canvas
})
```

通过 Render 可以设置背景色与大小，通常这个大小与整个画布相等：

```js
renderer.setClearColor(new THREE.Color(0x000000, 1.0))
renderer.setSize(400, 400)
```

当完成了相机和场景的定义后，就可以使用渲染器上的 `render()` 方法将其渲染到画面上，第一个参数位传入实例化的 scene，第二个参数位传入实例化的 camera：

```js
renderer.render(scene, camera)
```

通常渲染器会放在一个render函数中被重复调用，渲染器在每次渲染时会自动将上一帧场景清除，重新绘制一帧，这样不停的重新渲染，就会产生动态效果了：

```js
var render = function () {
  // ... 每一帧对场景进行应有的变动
  renderer.render(scene, camera)
  requestAnimationFrame(render)
}
```

## 2.3 相机 Camera

在 ThreeJS 中相机分为两种相机，分别是 **正交投影相机** 与 **透视投影相机**。

**正交投影相机 OrthographicCamera：**

![](https://pic4.zhimg.com/80/v2-62ede52e0bb0d8b49f6cf2e41debc247_hd.jpg)

> 注：图中的”视点”对应着Three中的Camera。
>
> 这里补充一个视景体的概念：视景体是一个几何体，只有视景体内的物体才会被我们看到，视景体之外的物体将被裁剪掉。这是为了去除不必要的运算。
>
> 正交投影相机的视景体是一个长方体，OrthographicCamera的构造函数是这样的：OrthographicCamera( left, right, top, bottom, near, far )
>
> Camera本身可以看作是一个点，left则表示左平面在左右方向上与Camera的距离。另外几个参数同理。于是六个参数分别定义了视景体六个面的位置。
>
> 可以近似地认为，视景体里的物体平行投影到近平面上，然后近平面上的图像被渲染到屏幕上。

实例化一个简单的正交相机可以使用 `new THREE.OrthographicCamera()` 传入的参数分别为定义的空间范围（上下左右前后）：

```js
var camera = new THREE.OrthographicCamera(-width / 2, width / 2, height / 2, -height / 2, -1000, 1000)
```

在一个3D的空间中，相机需要摆放到一个固定的点去观察物体，同时还要设置观察的方向：

```js
// 相机由 (0,0,100) 的坐标望向 (0,0,0) 的坐标
camera.position.x = 0
camera.position.y = 0
camera.position.z = 100
camera.lookAt(new THREE.Vector3(0, 0, 0))
```

假如我们在点 (0,0,0) 处设置了一个平面三角形，按照相机的摆放位置看上去是这样的：

![20190824174049.png](http://img.cdn.esunr.xyz/markdown/20190824174049.png)

当将相机摆放在(100,100,100)的位置，即摆放在三角形的右上角，观察三角形的情况为：

![20190824174230.png](http://img.cdn.esunr.xyz/markdown/20190824174230.png)

> 由于我们使用了正交相机，图形没有近大远小的效果，看起来很奇怪，但是由 AxisHelp 坐标可以看出视角已经发生了变化

**透视投影相机：**

![](https://pic2.zhimg.com/80/v2-3b160a77bda7661c4dd3920ddeaae605_hd.jpg)

> 透视投影相机的视景体是个四棱台，它的构造函数是这样的：PerspectiveCamera( fov, aspect, near, far )
>
> fov对应着图中的视角，是上下两面的夹角。aspect是近平面的宽高比。在加上近平面距离near，远平面距离far，就可以唯一确定这个视景体了。
>
> 透视投影相机很符合我们通常的看东西的感觉，因此大多数情况下我们都是用透视投影相机展示3D效果。

**场景：**

场景是所有物体的容器，也对应着我们创建的三维世界，只有我们在 scene 中添加的物体才会被展示出来。

创建一个 scene 实例：

```js
var scene = new THREE.Scene()
```

向scene中添加一个物体，如AxisHelper（辅助坐标，可以帮助我们观察场景）：

```js
var axesHelper = new THREE.AxisHelper(100)
scene.add(this.axesHelper)
```

# 3. react-three-fiber

react-three-fiber 是一个应用于 React 项目（以下简称 RTF）或者 React-Native 项目中的渲染器，其内部是由 threeJS 实现的。

利用 RTF 可以让我们更便捷的使用组件的风格来构建 threeJS 场景，其对于 ThreeJS 的 API 封装时有规律可循的，我们在这里演示以下如何将 threeJS 的代码转换为 RTF 风格的代码，从而让你更快上手改渲染器。

我们截取 《ThreeJS 开发指南》 第一章节的一段代码，构建出一个三维场景，效果如下：

![](https://i.loli.net/2020/08/31/GxcelV95I2aQJBT.png)

> Tips: 完整源码请查看 https://github.com/josdirksen/learning-threejs/blob/master/chapter-01/02-first-scene.html

## 3.1 场景的创建

在 ThreeJS 中，如果要创建场景，就必须构建一个 `Scene` 对象：

```js
// create a scene, that will hold all our elements such as objects, cameras and lights.
var scene = new THREE.Scene();
```

如果要往场景中添加元素则需要使用 `scene.add()` 进行添加。

而在 RTF 中，创建一个场景与添加元素就好像我们写嵌套组件一样，他们有一层很明显的父子级关系，如我们要添加一个 AxisHelper：

```tsx
<Canvas {...prosp}>
  <axesHelper />
</Canvas>
```

## 3.2 相机的设置

在 ThreeJS 中相机是个很重要的概念，在 ThreeJS 中创建相机我们需要配置其类型、位置、焦点等信息，如下：

```js
var camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.x = -30;
camera.position.y = 40;
camera.position.z = 30;
camera.lookAt(scene.position);
```

在 RTF 中，创建相机是在 Canvas 组件中进行配置的，一个场景只拥有一个相机，同时其默认是一个正交相机：

```tsx
<Canvas
      camera={{
        fov: 45,
        aspect: window.innerWidth / window.innerHeight,
        near: 0.1,
        far: 1000,
        position: [-30, 40, 30],
      }}
    >
    {/* ... ... */}
</Canvas>
```

## 3.3 Mesh 的构建

在 ThreeJS 中如果我们想创建一个几何体，那么基本上都存在三步：

- 实例化一个 Three 内置的几何对象（Geometry）
- 实例化一个材质（Material）对象
- 利用网格（Mesh）将两个对象结合

最后生成的这个集合体我们就可以为其在空间中设置坐标，同时将其添加到场景（Scene）中，让它在空间中显示出来：

```js
 // create a sphere
var sphereGeometry = new THREE.SphereGeometry(4, 20, 20);
var sphereMaterial = new THREE.MeshBasicMaterial({color: 0x7777ff, wireframe: true});
var sphere = new THREE.Mesh(sphereGeometry, sphereMaterial);

// position the sphere
sphere.position.x = 20;
sphere.position.y = 4;
sphere.position.z = 2;

// add the sphere to the scene
scene.add(sphere);
```

如果我们想要在 RTF 中进行同样的操作，那么我们只需要创建一个 `Mesh` 组件，然后用其包裹一个几何对象和材质对象即可：

```tsx
<mesh position={[20, 4, 2]}>
  <sphereGeometry args={[4, 20, 20]} attach="geometry" />
  <meshBasicMaterial
    color={0xff0000}
    wireframe={true}
    attach="material"
  />
</mesh>
```

> Tips：在 RTF 中可以使用 `args` 参数来进行传参，如：
> ```tsx
> <sphereGeometry args={[4, 20, 20]} attach="geometry" />
> ```
> 等同于：
> ```js
> var sphereGeometry = new THREE.SphereGeometry(4, 20, 20);
> ```
> 此外，如果是定义一个 Geometry 或者是 Material，必须为其添加 `attach` 属性进行声明。

## 3.4 完整示例：

```tsx
<Canvas
  camera={{
    fov: 45,
    aspect: window.innerWidth / window.innerHeight,
    near: 0.1,
    far: 1000,
    position: [-30, 40, 30],
  }}
>
  <axesHelper args={[20]} />
  <mesh position={[15, 0, 0]} rotation={[-0.5 * Math.PI, 0, 0]}>
    <planeGeometry args={[60, 20, 1, 1]} attach="geometry" />
    <meshBasicMaterial color={0xcccccc} attach="material" />
  </mesh>

  <mesh position={[-4, 4, 0]}>
    <boxGeometry args={[4, 4, 4]} attach="geometry" />
    <meshBasicMaterial
      color={0xff0000}
      wireframe={true}
      attach="material"
    />
  </mesh>
  <mesh position={[20, 4, 2]}>
    <sphereGeometry args={[4, 20, 20]} attach="geometry" />
    <meshBasicMaterial
      color={0xff0000}
      wireframe={true}
      attach="material"
    />
  </mesh>
</Canvas>
```

# 4. 参考资料

- [Games101(现代计算机图形学入门)](https://link.zhihu.com/?target=https%3A//www.bilibili.com/video/BV1X7411F744%3Ffrom%3Dsearch%26seid%3D16228307511649123560)
- [凹凸实验室：ThreeJS现学现卖](https://aotu.io/notes/2017/08/28/getting-started-with-threejs/index.html)
- [慕课：ThreeJS实战](https://coding.imooc.com/class/282.html)
- [DirectX 和 OpenGL：游戏为什么离不开他们](https://www.youtube.com/watch?v=3OYNerkxI-U)
- [Three.js开发指南：WebGL的JavaScript 3D库](https://item.jd.com/12113317.html)