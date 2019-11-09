---
title: Gulp快速使用指南
date: 2019-07-22 21:30:36
tags: [快速使用, Gulp]
categories: [Front, 构建工具]
---
> Gulp学习版本为3.9.1

# 1. Gulp特点

- 任务化
- 基于流
  - 输入流
  - 输出流

# 2. API
- `gulp.src(globs[, options])` 输入文件：输入流
- `gulp.dest(path[, options])` 输出文件：输出流
- `gulp.task(name[, deps], fn)` 任务化
- `gulp.watch(glob[, opts], tasks)` 监视

# 3. 目录结构

```
|- dist
|- src
    |- js
    |- css
    |- less
|- index.html
|- gulpfile.js
|- package.json
    {
        "name": "gulp_study",
        "version": "1.0.0"
    }
```

# 4. 安装gulp

* 全局安装：

```
npm install gulp -g
```

* 局部安装：

```
npm install gulp -S
```

* 配置编码

```js
// gulpfile.js
var gulp = require('gulp')
// 注册任务
gulp.task('任务名', function(){
    // 配置任务的操作
})

gulp.task('default', [])
```

之后我们可以使用 `gulp 任务名` 来执行某个特定的任务，或者使用 `gulp` 来执行默认的任务序列**（gulp4 已弃用）**

# 5. 常用的gulp插件

*   sass的编译（`gulp-sass`）

*   less编译 （`gulp-less`）

*   重命名（为压缩的文件加'.min'）（`gulp-rename`）

*   自动添加css前缀（`gulp-autoprefixer`）

*   压缩css（`gulp-minify-css`）

*   js代码校验（`gulp-jshint`）

*   合并js/css文件（`gulp-concat`）

*   压缩js代码（`gulp-uglify`）

*   压缩图片（`gulp-imagemin`）

*   自动刷新页面（`gulp-livereload`，谷歌浏览器亲测，谷歌浏览器需安装livereload插件）

*   图片缓存，只有图片替换了才压缩（`gulp-cache`）

*   更改提醒（`gulp-notify`）

# 6. 合并压缩js任务

## 6.1 配置任务

我们在 `src/js` 文件夹中创建两个js文件，分别对应了两个方法，我们想要将这两个js文件合并为一个文件，需要在 `gulpfile.js` 文件中定义任务流：

```js
gulp.task('js', function() {
    // 深度遍历
    // return gulp.src('src/js/**/*.js') 
    // 浅度遍历
    return gulp.src('src/js/*.js') // 找到目标文件，将数据读取到gulp的内存中
})
```

## 6.2 下载和使用插件

1. 安装插件

当gulp读取文件到内存中后，会进行一系列操作，这些操作会用到gulp插件：

```
cnpm install gulp-concat gulp-uglify gulp-rename --save-dev
```

2. 引入插件

引入插件：

```js
// gulpfile.js
var concat = require('gulp-concat')
var uglify = require('gulp-uglify')
var rename = require('gulp-rename')
```

3. 注册任务

在引入插件之后我们便可以执行链式调用来配置任务了，每一个操作用 `pipe` 方法来进行连接：

```js
// gulpfile.js
gulp.task('js', function () {
    return gulp.src('src/js/*.js')
        .pipe(concat('build.js')) // 临时合并文件
        .pipe(gulp.dest('dist/js/')) // 临时输出文件到本地
        .pipe(uglify())
        .pipe(rename({ suffix: '.min' })) // 重命名
        .pipe(gulp.dest('dist/js/'))
})
```

## 6.3 执行任务

调用已注册的任务，我们可以得到一个已经合并的文件 `build.js` 和一个合并并压缩的文件 `build.min.js`

```sh
gulp js
```

> gulp会自动忽略为调用的函数方法

# 7. 合并压缩css任务

1. 下载插件

```sh
npm install gulp-less gulp-clean-css --save-dev
```

2. 引入和使用插件

```js
// gulpfile.js
var gulp = require('gulp')
var concat = require('gulp-concat')
var rename = require('gulp-rename')
var less = require('gulp-less')
var cssClean = require('gulp-clean-css')

// 注册转换less的任务
gulp.task('less', function () {
    return gulp.src('src/less/*.less')
        .pipe(less()) // 编译less文件为css文件
        .pipe(gulp.dest('src/css')) // 将less编译为css文件后存放到css文件夹中，等待后续统一合并
})

// 合并压缩css文件
gulp.task('css', function () {
    return gulp.src('src/css/*.css')
        .pipe(concat('build.css'))
        .pipe(rename({ suffix: '.min' }))
        .pipe(cssClean({ compatibility: 'ie8' })) // 压缩、设置兼容到ie8
        .pipe(gulp.dest('dist/css/'))
})

gulp.task('default', [])
```

3. 执行任务

```sh
> gulp less
[15:18:39] Using gulpfile D:\test\gulp_study\gulpfile.js
[15:18:39] Starting 'less'...
[15:18:39] Finished 'less' after 43 ms

> gulp css
[15:18:46] Using gulpfile D:\test\gulp_study\gulpfile.js
[15:18:46] Starting 'css'...
[15:18:46] Finished 'css' after 48 ms
```



# 8. 线性执行任务

```js
// gulpfile.js
... ...
gulp.task('default', ['js', 'less', 'css'])
```

在用这种方式时，gulp的每个编译任务是移异步进行的，如果将编写任务中的 `return` 去掉，则编译过程是同步进行的，如：

```diff
  gulp.task('js', function () {
-   return gulp.src('src/js/*.js')
+   gulp.src('src/js/*.js')
      .pipe(concat('build.js')) // 临时合并文件
      .pipe(gulp.dest('dist/js/')) // 临时输出文件到本地
      .pipe(uglify())
      .pipe(rename({ suffix: '.min' })) // 重命名
      .pipe(gulp.dest('dist/js/'))
  })
```

> 但是我们不推荐这么做（占内存，速度慢）

当我们需要逐个执行任务的时候，可以在设置任务的第二个参数位置，去设置它的依赖任务，如我们如果需要设置先执行 `less` 任务，再执行 `css` 任务，那么 `css` 任务的依赖任务就是 `less` 任务，我们可以进行如下设置：

```js
// gulpfile.js
gulp.task('css', ['less'], function () {
  return gulp.src('src/css/*.css')
    // ... ...
})
```






# 9. html压缩

1. 下载插件

```sh
npm install gulp-html --save-dev
```

2. 引入和使用插件

```js
// glupfile.js
var htmlMin = require('gulp-html')
// ... ...

// 注册压缩html的任务
gulp.task('html', function () {
  return gulp.src('index.html')
    .pipe(htmlMin({ collapseWhitespace: true })) // 压缩html
    .pipe(gulp.dest('dist/')) // 输出
})
```

3. 执行任务

```sh
gulp html
```

> 注意路径问题，压缩输出的 html 换到了另外的一个路径下，这个所以导出 html 前，必须将路径配置到 `dist` 目录下。

# 10. 半自动进行项目构建

1. 下载插件
   
```sh
npm install gulp-livereload --save-dev
```

2. 配置编码

```js
// 监视任务
gulp.task('watch', ['default'], function () {
  // 开启监听
  livereload.listen();
  // 确认监听的目标以及绑定相应的任务
  gulp.watch('src/js/*.js', ['js']);
  gulp.watch(['src/css/*.css', 'src/less/*.less'], ['css'])
})
```

在设置完监听任务后，需要在监听的任务中再额外增加一个 `pipe(livereload())` 方法，如：

```diff
  gulp.task('js', function () {
    return gulp.src('src/js/*.js')
      .pipe(concat('build.js')) // 临时合并文件
      .pipe(gulp.dest('dist/js/')) // 临时输出文件到本地
      .pipe(uglify())
      .pipe(rename({ suffix: '.min' })) // 重命名
      .pipe(gulp.dest('dist/js/'))
+     .pipe(livereload())
  })
```

3. 执行任务

```sh
gulp watch
```

之后当我们编辑监听中的代码时，就可以自动打包编译，之后再**手动刷新**浏览器后就可以浏览效果，如果想要**自动刷新**看下一节全自动构建项目。


# 11. 全自动构建项目

1. 安装插件

```
npm install gulp-connect --save-dev
```

2. 引入并使用插件

```js
var connect = require('gulp-connect')
// ... ...

// gulpfile.js
// 注册监视任务（全自动）
gulp.task('server', ['default'], function () {
  // 配置服务器选项
  connect.server({
    root: 'dist/',
    livereload: true, // 实时刷新
    port: 5000
  })
  // 确认监听的目标以及绑定相应的任务
  gulp.watch('src/js/*.js', ['js']);
  gulp.watch(['src/css/*.css', 'src/less/*.less'], ['css'])
})
```

相似的，在设置完全自动监听的任务后，需要在监听的任务中再额外增加一个 `.pipe(connect.reload())` 方法，如：

```diff
  gulp.task('js', function () {
    return gulp.src('src/js/*.js')
      .pipe(concat('build.js')) // 临时合并文件
      .pipe(gulp.dest('dist/js/')) // 临时输出文件到本地
      .pipe(uglify())
      .pipe(rename({ suffix: '.min' })) // 重命名
      .pipe(gulp.dest('dist/js/'))
+     .pipe(connect.reload())
  })
```

3. 执行任务

```sh
gulp server
```

## 12. 扩展

### 12.1 使用 open 模块自动打开浏览器

```
npm install open --save-dev
```

```js
// gulpfile.js
var open = require('open')

... ...

// 注册监视任务（全自动）
gulp.task('server', ['default'], function () {
  ... ...
  open('http://localhost:5000')
})
```

## 12.2 使用 gulp-load-plugins 插件

1. 下载：

```
cnpm install gulp-load-plugins --save-dev
```

2. 引入：

```js
var $ = require('gulp-load-plugins')
```

3. 之后我们便可以直接使用 `$` 对象来调用所有的插件方法：

```js
var gulp = require('gulp')
// var concat = require('gulp-concat')
// var uglify = require('gulp-uglify')
// var rename = require('gulp-rename')
// var less = require('gulp-less')
// var cssClean = require('gulp-clean-css')
// var htmlMin = require('gulp-htmlmin')
// var livereload = require('gulp-livereload')
// var connect = require('gulp-connect')
// var open = require('open')
var $ = require('gulp-load-plugins')

// 注册压缩html的任务
gulp.task('js', function () {
  return gulp.src('src/js/*.js')
    .pipe($.concat('build.js')) // 临时合并文件
    .pipe(gulp.dest('dist/js/')) // 临时输出文件到本地
    .pipe($.uglify())
    .pipe($.rename({ suffix: '.min' })) // 重命名
    .pipe(gulp.dest('dist/js/'))
    .pipe($.livereload())
    .pipe($.connect.reload())
})
```

4. 命名规则：

使用 `$` 对象引入的 gulp 插件必须有其对应的命名方法，其规则为：
- 忽略连接符前的 gulp，直接写插件名称，如：`gulp-concat` 插件对应的引入方法为 `$.concat`
- 如果有多个连接符，则采用驼峰命名，如：`gulp-clean-css` 插件对应的引入方法为 `$.cleanCss`