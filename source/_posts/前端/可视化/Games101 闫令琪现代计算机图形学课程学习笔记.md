---
title: Games101 闫令琪现代计算机图形学入门学习笔记
tags:
  - 图形学
  - 学习笔记
  - GAMES101
categories:
  - 前端
  - 可视化
date: 2024-08-18 18:28:30
---
# Lecture 03. 变换（二维与三维）

[课件](https://sites.cs.ucsb.edu/~lingqi/teaching/resources/GAMES101_Lecture_03.pdf)

### 缩放

缩放的数学形式表现：

`x'=s*x+0*y` `y'=0*x+s*y`

矩阵形式：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818183404.png)

> 矩阵相乘的条件是：前一个矩阵的列数必须等于后一个矩阵的行数。在这种情况下
### 反转

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818195950.png)

### 切变

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818200309.png)

### 旋转变换

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818200441.png)

推导过程：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818200814.png)

注意：旋转的中心永远是坐标轴的原点：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818203235.png)

### 平移与齐次坐标

平移无法直接用矩阵相乘的形式来表达：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818201050.png)

虽然我们可以通过矩阵相乘再相加的方式来表示（这种叫做**仿射变换**）平移，但这也就意为这这个变化不是线性变化了：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818201206.png)

齐次坐标通过增加一个纬度的方式来解决了这个问题：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818201646.png)

三维坐标中的点可以映射在二维坐标中：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818202225.png)

仿射变换转为齐次坐标的方式，tx、ty 代表平移 ：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818202335.png)

二维的变换都可以改写为齐次坐标，他们的意义是不会因为增加了一个纬度而改变的：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818202500.png)
### 复杂变换

使用矩阵相乘可以进行复杂的图形变换，但是相乘的顺序很重要：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818203410.png)

形变顺序在矩阵相乘公式中是**从左到右运算的**，因此先旋转后平移的矩阵表达式为：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818203535.png)

再举一个例子，如果想要改变图形的旋转中心，就可以先将其移动到原点，进行旋转后，再将其移动到原来的位置：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818204000.png)

### 三维空间中的形变

相同的，在三维空间中如果发生了平移操作，也要转化为齐次坐标进行描述：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818204156.png)

三维空间中使用齐次坐标描述仿射变换：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818204300.png)

> 上面的公式描述为先进行线性变换，再平移

### 补充：旋转矩阵的逆操作

对于旋转操作来说，如果想要旋转负的 θ 角（也就是逆操作），则要将 sinθ 进行取反，取反后的矩阵就正好是原矩阵的转置矩阵。

因此，我们可以说：在旋转里面，它的逆就等于旋转矩阵的转置：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818213206.png)

在数学上，如果一个矩阵的逆等于它的转置，这个矩阵叫做正交矩阵。

# Lecture 04. 变换（模型、视图、投影）

- [视频](https://www.bilibili.com/video/BV1X7411F744?p=4&vd_source=b233b2041b0c7ce85a2c9111063e461f)
- [课件](https://sites.cs.ucsb.edu/~lingqi/teaching/resources/GAMES101_Lecture_04.pdf)

### 三维形变 —— 缩放与平移

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818214538.png)

### 三维形变 —— 旋转

三维旋转比较复杂，我们可以拆分为单独绕某个轴进行旋转：

![image.png|230](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818214838.png)


绕 x 轴旋转相当于 x 轴的坐标不变，所以与 x 相乘的第一行为 \[1 0 0 0\]：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818214813.png)

相同的，绕 z 轴旋转就是 z 轴坐标对应相乘的矩阵行就是 \[0 0 1 0\]：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818215416.png)

绕 y 轴旋转需要注意，sinα 的取值是负的，这是因为 xyz 的顺序决定的：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818215625.png)

任意的三维旋转都可以写成绕 x 轴、绕 z 轴、绕 y 轴的旋转的组合：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818220153.png)

三个轴的旋转量分别是 α、β、γ，数学上将其称之为**欧拉角**。

三个轴的旋转行为分别被称为 roll、yaw、pitch：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818220345.png)

使用**罗德里格斯旋转公式**可以直接求得在三维空间里的向量绕着某个轴 n 旋转 α 角度后得到的最终向量，而不必将旋转进行 x、y、z 轴上的拆分：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818220833.png)

### 视图/相机变换

首先要定义相机的相关向量：

- 相机的位置使用向量 e；
- 相机的朝向使用向量 h；
- 由于相机自身可能有旋转角度，因此我们使用一个“向上向量” t 来表示相机的自身旋转状态；

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818223058.png)

由于相机和被摄物体之间共同发生了旋转就相当于没有发生旋转，因此我们规定相机始终在世界原点，并且相机的初始朝向朝着 Z 轴的负方向（这是为了操作方便而规定的）：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818223520.png)

将相机的向量规范为世界坐标的过程：

1. 将向量 e 放置到世界坐标的原点；
2. 旋转向量 g 对其到坐标轴的 z 轴；
3. 旋转向量 t 对其到坐标轴的 y 轴；
4. 旋转后向量 g x  t 的结果就是 z 轴喽；

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818224417.png)

具体过程如下：

![image.png|500](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818224805.png)

这里需要注意一下，由于将任意的轴旋转到一个规范化的轴上（向量 g 旋转到 -Z，向量 t 旋转到 Y， g x t 旋转到 X）的这一过程很不好描述，但是将规范化的轴（这个轴可以使用向量来表示，比如  (1,0,0)  表示 X 轴）旋转到某一向量上是比较好描述的，因此我们可以先求出后者。有因为旋转矩阵是一个正交矩阵，它的转置矩阵即是它的逆矩阵，这样我们就可以得到任意旋转轴到规范化轴上的旋转矩阵了。

[关联](https://www.cnblogs.com/wbaoqing/p/5422974.html)

### 正交相机拍摄的物体投影在显示设备上

正交投影和透视投影如下：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818230302.png)

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818230515.png)

正交投影的点线都是平行的，大多被用于工程视图，但是我们正常视角下都应该是透视投影。

对于正交投影来说，丢弃 Z 轴即可得到投影的结果：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818230740.png)

不管 x、y 的范围有多大，都将其归一化到 \[-1, 1\] 的取值范围内，这是约定俗成的，为了方便后续的计算。为了实现归一化，空间中的物体也要做相对应的缩放，其过程为先将物体移到原点，然后对物体缩放到 \[-1, 1\] 之间：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818231802.png)

> 在为了归一化而缩放过程中，可能会导致原有的物体被拉伸，如把原本的一个长方体空间拉伸成一个 1:1 的立方体，那么空间里的物体也会被响应的拉伸，最后完成时还要进行视口的还原。

数学表达如下：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818232914.png)

### 透视相机拍摄的物体投影在显示设备上

在进行前，我们先回忆一下齐次坐标的性质，在齐次坐标中，`(x, y, z, 1)` 和 `(kx, ky, kz, k != 0)` 都表示同一个点，那么 `(xz, yz, z², z != 0)` 这个齐次坐标在三维空间中同样能表示 `(x, y, z)`。

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818234709.png)

我们前面已经知道了如何求正交相机的投影，那么对于透视相机来说，我们只要将透视相机的空间压缩为正交相机的空间，那么后续的过程都一样了：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240818235418.png)

根据相似三角形定理，远平面上的点映射到近平面上的点的坐标，就等于相机距离近平面的距离、与相机距离远平面的距离的比值，与原坐标相乘：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240819000004.png)

坐标点用齐次坐标表示后，可以通过上面得到的公式，得到一个透视空间被压缩为正交空间后的新的坐标，我们可以得到新的坐标的 x 和 y 值，但是无法得到转化后的 z 值。

> 为什么 z 是 unknown ？
> - 挤压之后原本在Z方向上均匀分布的点将变得不均匀，疏密程度会发生变化
> - 各位看清楚，这个相似三角形并不平行于yoz所在平面，n，z分别代表原点到对应点的距离而不是z值！这个相似三角形和z值完全没有关系自然得不到z值！！！

我们可以先将齐次坐标乘以 z，得到一个比较好处理的齐次坐标：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240819001125.png)

根据结果，我们可以反推出来将透视空间转为正交空间的投影矩阵：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240819002027.png)

为了求出矩阵的第三行，我们需要利用这个变换过程中的特性：

- 任何近平面的点进过转换后，z 轴坐标不会发生改变；
- 任何远平面的点经过转换后，z 轴的坐标同样不会发生改变；

那么我们就可以取近平面上的某一点 (x, y, n)，它的其次坐标为 (x, y, n, 1)，经过变换后的点仍为 (x, y, n, 1)，利用齐次坐标的特性，将其所有项都乘以 n 后得到 (nx, ny, n², n)：

![image.png|167](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240819005932.png)

那么我们就可以得到：

M x (x, y, z, 1) = (nx, ny, n², n)

进一步我们就可以假设我们要求的矩阵第三行为 \[0 0 A B\]（n² 与 xy 没有关系，所以与 xy 相乘的数必定是 0）：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240819010210.png)

进一步计算后得到计算公式：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240819004302.png)

但是具体的 A、B 是什么我们还未知，可能是 (n, 0) 也可能是 (0, n²)。此时我们还要利用另外一个特性，那就是远平面中心的点在经过转换后，z 轴坐标是不变的，假设这个点是 (0, 0, f)，那么转化为其次坐标后，我们就可以得到公式：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240819004315.png)

最终得出结果：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240819004422.png)

f 代表近平面的中心点到远平面的中心点之间的距离。
