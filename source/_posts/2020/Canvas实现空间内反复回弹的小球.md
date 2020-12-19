---
title: Canvas实现空间内反复回弹的小球
tags: [Canvas]
categories:
  - Front
  - HTML
date: 2020-12-19 15:27:02
---

# 1. 题目描述

再一个空间内存在一个球体按照一定的速度朝一个方向运动，当碰到空间边缘时，会反弹并继续运动。默认该空间中不存在任何摩擦阻力，再小球反弹过程中也不存在动能损耗（即小球一直再空间内做匀速运动）。

# 2. 题目分析

之前再完美世界的面试中遇到过这道题，小球的运动很好做，这道题的难点再触碰边界时的运动处理。当时把这道题想复杂了，完全再纠结反弹过程中的出入角计算。

其实我们都知道，一个物体再某个方向上的运动，可以被拆分为两个方向的运动（如平抛运动，可以拆分为水平方向的运动与垂直方向的运动）。

![](https://i.loli.net/2020/12/19/7aqFPbWrC2f6pVw.png)

因此，只需要再小球碰壁时，改变其 x 轴或 y 轴的方向，就可以模拟出碰壁效果。

# 3. 代码实现

```html
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document</title>
</head>

<body>
  <canvas id="myCanvas" style="border: 2px solid pink;"></canvas>

  <script>
    const WIDTH = 1000
    const HEIGHT = 500

    const canvas = document.getElementById('myCanvas');
    canvas.width = WIDTH;
    canvas.height = HEIGHT;
    const ctx = canvas.getContext('2d');

    const speed = 10
    const radius = 10
    let currentX = 210
    let currentY = 0
    let xDir = 1
    let yDir = 1

    function animation() {
      // 清除画布
      canvas.width = canvas.width

      // 绘制小球
      ctx.beginPath();
      ctx.arc(currentX, currentY, radius, 0, 2 * Math.PI);
      ctx.fill();
      ctx.stroke()

      // 计算下一帧小球的位置
      currentX += speed * xDir
      currentY += speed * yDir

      // 检测是否需要改变 Y 轴上的方向
      if (currentY <= 0) {
        yDir = 1
        currentY = 0
      }
      if (currentY >= HEIGHT) {
        yDir = -1
        currentY = HEIGHT
      }

      // 检测是否需要改变 X 轴上的方向
      if (currentX <= 0) {
        xDir = 1
        currentX = 0
      }
      if (currentX >= WIDTH) {
        xDir = -1
        currentX = WIDTH
      }

      requestAnimationFrame(animation)
    }

    animation()
  </script>
</body>

</html>
```