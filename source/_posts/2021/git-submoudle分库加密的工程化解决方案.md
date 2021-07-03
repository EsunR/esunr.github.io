---
title: Git Submodules 分库加密的工程化解决方案
tags: [git, gulp]
categories:
  - Front
  - 构建工具
date: 2021-07-03 14:21:33
---

# 1. 前言

由于公司的项目分为多个模块，为了方便多个模块分开开发，防止代码混淆，因此每个项目模块都另外开了一个分库来维护，然后有一个整体的项目基座用来关联各个模块的页面跳转，项目上线时也可以单个模块增量上线。

但是这么一套架构就带来另外一个问题，对于每个模块的共用部分，如 utils、hooks、components、mockData 等每次更新时都要复制一份到各个模块中，保证每个模块的公共代码部分都保持一致，这个工作量无疑是庞大的。

因此我们引入了 [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) 来连接多个模块库，这样只要公共部分的代码变更后，其他模块只需要调用 `git submodule foreach git pull origin [branchName]` 来拉取各个子模块的最新代码即可，这一行为可以使用 ci 在服务器端每天定时运行，保证公共代码统一是最新的。

但是我们的公共模块不只服务于我们自己的项目，目前公司有需求聘用外部团队，那么公共代码的源码直接交给外部团队就很不安全了。因此我们现在有一个新的需求，就是对子模块进行加密，同时保证加密模块要与公司内部的代码保持同步更新，对外只提供加密后的模块。

# 2. 解决方案

其实，整体的解决方案并不繁琐，我们可以简单整理为如下几步：

1. 拉取子库最新的代码
2. 将最新的代码进行编译、压缩、混淆
3. 将处理过的代码 push 到单独的新代码库中，如 `component_encrypt`

明确了我们的思路后，接下来就是工程化和自动化的实现，按照以往的经验，仅仅对代码进行编译与压缩，使用 Gulp 最合适不过了，同时 Gulp 也支持 git 操作与普通的命令行操作，我们第一步与最后一步的操作都需要用到 git，也可以借助 Gulp 来实现自动化。

# 3. 实践

明确了以上的三个步骤，我们就开始编写 Gulp 脚本，并在一个子库中进行实验。

我们挑选的子库是我们的 `components` 组件库，其有一个 dev 分支，我们平常迭代代码都是在 dev 分支更新代码，为了不干扰 dev 分支的正常开发，我们单独开一个分支名为 `encrypt`，如果需要进行代码加密的工作，就切到 `encrypt` 分支来进行。

## 3.1 拉取最新代码

我们切到负责加密的分支 `encrypt` 后，如果想要更新最新的代码就需要调用 `git pull origin dev` 来完成，这一步可以借助 [gulp-git](https://github.com/stevelacy/gulp-git) 来模拟这个操作，我们将这个工作流命名为 `pullDev`：

```js
function pullDev(cb) {
  git.pull('origin', 'dev', function () {
    cb();
  });
}
```

但是由于 `components` 这个库比较特殊，其用到了我们另外的 `@types` 库（`@types` 也是一个分库），那么我们要将其 clone 过来，并存放到 `@types` 目录下：

```js
function pullTypes(cb) {
  git.clone('git@123.59.xx.xxx:fe/common_types.git', { args: '@types' }, function () {
    cb();
  });
}
```

## 3.2 加密代码

接下来就是核心部分，我们要对当前的源码进行一系列操作，对其加密。

首先我们的模块采用了 ts 去编写，那么就要将 ts 转为 `.js` 文件与 `.d.ts` 文件，这一步可以用 [gulp-typescript](https://www.npmjs.com/package/gulp-typescript)，这是一个可以利用 gulp 来构建 typescript 文件的工具，类似于原有的 `tsc` 指令，但是比 tsc 指令更易懂，也更适合在 gulp 中使用，Typescript 官方也对其进行了推荐（[官方文档](https://www.tslang.cn/docs/handbook/gulp.html)）

我们先声明一下 ts 的编译配置（由于使用 gulp-typescript 可以直接设置编译配置，不需要额外创建一个 tsconfig.json）:

```js
var tsProject = ts.createProject({
  noImplicitAny: true,
  target: 'es6',
  jsx: 'react',
  declaration: true,
  moduleResolution: 'node',
});
```

有了配置后，我们就创建一个 transTsx 的工作流，用来转换 ts 文件，同时在转换完成后顺便使用 `gulp-minify` 来对代码进行压缩和混淆：

> PS: gulp-minify 是可以对代码进行混淆的。不知道什么原因，如果同时使用 `gulp-minify` 压缩代码并使用 `gulp-uglify` 混淆代码，代码在其他项目的引用中会报错，无法正常使用。

```js
// 声明一些必须忽略的文件
const MUST_IGNORE_FILES = [
  '!./node_modules/**',
  '!./dist/**',
  '!./.git/**',
  '!./.idea/**',
  '!./gulpfile.js',
  '!./package.json',
  '!./yarn.lock',
  '!./CHANGELOG.md',
];

function transTsx() {
  // 添加 ts-ignore 强行阻止编译校验
  // 生成 js 文件和 d.ts 文件
  const tsResult = gulp.src(['./**/*.tsx', './**/*.ts', ...MUST_IGNORE_FILES] /** 编译所有的 tsx、ts 文件，但要滤掉 MUST_IGNORE_FILES 不编译的 */).pipe(tsProject())
  // 对编译好的 js 文件进行压缩混淆处理，并且输出到 dist 目录中，对 dts 文件则直接输出到 dist 目录中
  // (注：这里的 minify 与 dts 的输出并无前后依赖关系，为了加速编译，可以使用 merge 语法并行执行 gulp 编译)
  return merge([
    tsResult.js
      .pipe(
        minify({
          ext: {
            src: '.js',
            min: '.js',
          },
          noSource: true,
        }),
      ).pipe(gulp.dest('dist')),
    tsResult.dts.pipe(gulp.dest('dist')),
  ]);
}
```

很遗憾，如果这样编译是会报错的，因为 typescript 的编译是非常严格的，如果我们的代码不够规范，typescript 的默认编译模式下铁定会报错，但是小型团队人员水平参差不齐，没办法严格约束规范，并且这些错误并不会对代码的逻辑造成什么影响，编译也不会出什么问题，因此我们可以手动禁用 ts 的代码检查。

我们知道，在 ts 文件的代码前加上 `// @ts-nocheck` 备注就可以绕过 ts 的代码检查，那我们如果手动一个个文件去添加那就太麻烦了，好在 gulp 提供了获取文件句柄的方法，这里我们可以在 gulp 中使用 [through2](https://www.npmjs.com/package/through2) 来轻松获取到 pipe 流中当前处理的文件句柄，并对文件内容进行更改，因此我们只需要改一下代码，在进行 ts 编译前为源码加上注释即可：

```js
function transTsx() {
  // 添加 ts-ignore 强行阻止编译校验
  const tsNoCheck = gulp.src(['./**/*.tsx', './**/*.ts', ...MUST_IGNORE_FILES]).pipe(
    through.obj(function (file, encode, cb) {
      var result = file.contents.toString();
      result = '// @ts-nocheck\n' + result;
      file.contents = Buffer.from(result);
      this.push(file);
      cb();
    }),
  );
  // 生成 js 文件和 d.ts 文件
  var tsResult = tsNoCheck.pipe(tsProject());
  return merge([
    tsResult.js
      .pipe(
        minify({
          ext: {
            src: '.js',
            min: '.js',
          },
          noSource: true,
        }),
      ).pipe(gulp.dest('dist')),
    tsResult.dts.pipe(gulp.dest('dist')),
  ]);
}
```

这下，代码也成功编译好了，但是还存在一个遗留问题，由于加密的代码是在其他项目中使用的，其他项目使用了 eslint，如果不进行单独的配置，在项目内使用我们的加密代码时必定会经过 eslint 的检查，为了避免 eslint 的检查，跟避免 ts 检查一样，我们将编译好的 js 代码同样通过 through2 来为代码添加一行 `/* eslint-disable */` 来禁用 eslint 检查，最终 transTsx 流程的代码为：

```js
function transTsx() {
  // 添加 ts-ignore 强行阻止编译校验
  const tsNoCheck = gulp.src(['./**/*.tsx', './**/*.ts', ...MUST_IGNORE_FILES]).pipe(
    through.obj(function (file, encode, cb) {
      var result = file.contents.toString();
      result = '// @ts-nocheck\n' + result;
      file.contents = Buffer.from(result);
      this.push(file);
      cb();
    }),
  );
  // 生成 js 文件和 d.ts 文件
  var tsResult = tsNoCheck.pipe(tsProject());
  return merge([
    tsResult.js
      .pipe(
        minify({
          ext: {
            src: '.js',
            min: '.js',
          },
          noSource: true,
        }),
      )
      .pipe(
        // 编译混淆后的 js 文件禁用 eslint 检查
        through.obj(function (file, encode, cb) {
          var result = file.contents.toString();
          result = '/* eslint-disable */' + result;
          file.contents = Buffer.from(result);
          this.push(file);
          cb();
        }),
      )
      .pipe(gulp.dest('dist')),
    tsResult.dts.pipe(gulp.dest('dist')),
  ]);
}
```

## 3.3 处理后事

ts 的代码已经处理完了，但有时候子库里还有写其他的文件，如 `json`，这些静态文件是不需要处理的，只要将其复制一份到 dist 中就可以了：

```js
function moveOtherFile() {
  return gulp
    .src(['./**/*.*', '!./**/*.tsx', '!./**/*.ts', '!./@types/**', ...MUST_IGNORE_FILES], {
      nodir: true,
    })
    .pipe(gulp.dest('dist'));
}
```

然后可以写一个 cleanTypes 方法，来移除我们最开始 clone 的 `@types` 文件依赖：

```js
function cleanTypes(cb) {
  gulp.src('@types', { allowEmpty: true }).pipe(clean());
  cb();
}
```

## 3.4 同步加密代码到加密子库

我们已经完成了 `components` 代码库 encrypt 分支的基础构建，那我们想在编译完成后，将加密过的代码部署到 `components_encrypt` 库中，然后再把 `components_encrypt` 交给第三方团队，那么如何保持 `components` 与 `components_encrypt` 两个库代码的代码同步呢？这无非就还是一系列的 git 操作，我们可以使用 ci 来自动化部署，但是 ci 的脚本比 gulp 脚本可要难写多了，因此我们这一步也可以用 gulp 来实现，ci 只需要负责运行我们的 gulp 脚本就可以了（有点套娃的意思）。

这里整理一下我的 git 操作思路：

1. 构建完成后 cd 到 dist 目录
2. 执行 git init，在 dist 目录初始化 git
3. 为当前目录添加 git 源（components_encrypt 代码库的源）
4. 切到需要 push 代码的分支
5. 使用 `-f` 强行将当前更改保存到暂存区
6. 填写 commit 信息
7. 使用 `-f` 强行将代码推到远程分支

使用 gulp 还原上述的操作，如下：

```js
const ENCRYPT_REPOSITORY_URL = 'git@123.59.xx.xxx:fe/components_encrypt.git'; // 目标更新仓库
const ENCRYPT_REPOSITORY_BATCH = 'dev'; // 目标更新仓库的分支名（注：该分支不能在 GitLab 中设置为 protected 状态）

// (2)
function initEncryptRepository(cb) {
  git.init({ cwd: './dist' }, function (err) {
    if (err) throw err;
    cb();
  });
}

// (3)
function addOriginEncryptRepositoryUrl(cb) {
  git.addRemote('origin', ENCRYPT_REPOSITORY_URL, { cwd: './dist' }, function (err) {
    if (err) throw err;
    cb();
  });
}

// (4)
function checkoutEncryptRepositoryDevBatch(cb) {
  git.checkout(ENCRYPT_REPOSITORY_BATCH, { args: '-b', cwd: './dist' }, function (err) {
    if (err) throw err;
    cb();
  });
}

// (5)
function addEncryptRepositoryChanges(cb) {
  return gulp.src('./dist/*').pipe(
    git.add({ args: '-f', cwd: './dist' }, function (err) {
      if (err) throw err;
    }),
  );
}

// (6)
function commitEncryptRepositoryChanges(cb) {
  return gulp.src('./dist/*').pipe(
    git.commit('ci: update source', { cwd: './dist' }, function (err) {
      if (err) throw err;
    }),
  );
}

// (7)
function pushEncryptRepositoryChanges(cb) {
  git.push('origin', ENCRYPT_REPOSITORY_BATCH, { args: '-u -f', cwd: './dist' }, function (err) {
    if (err) {
      if (err) throw err;
    } else {
      cb();
    }
  });
}

// 聚合任务
gulp.task(
  'publish',
  gulp.series(
    initEncryptRepository,
    addOriginEncryptRepositoryUrl,
    checkoutEncryptRepositoryDevBatch,
    addEncryptRepositoryChanges,
    commitEncryptRepositoryChanges,
    pushEncryptRepositoryChanges,
  ),
);
```

# 完整代码

```js
var gulp = require('gulp');
var through = require('through2');
var merge = require('merge2');
var ts = require('gulp-typescript');
var minify = require('gulp-minify');
var clean = require('gulp-clean');
var git = require('gulp-git');
var tsProject = ts.createProject({
  noImplicitAny: true,
  target: 'es6',
  jsx: 'react',
  declaration: true,
  moduleResolution: 'node',
});

const MUST_IGNORE_FILES = [
  '!./node_modules/**',
  '!./dist/**',
  '!./.git/**',
  '!./.idea/**',
  '!./gulpfile.js',
  '!./package.json',
  '!./yarn.lock',
  '!./CHANGELOG.md',
];
const ENCRYPT_REPOSITORY_URL = 'git@123.59.xx.xxx:fe/components_encrypt.git'; // 目标更新仓库
const ENCRYPT_REPOSITORY_BATCH = 'dev'; // 目标更新仓库的分支名（注：该分支不能在 GitLab 中设置为 protected 状态）

function pullDev(cb) {
  git.pull('origin', 'dev', function () {
    cb();
  });
}

function pullTypes(cb) {
  git.clone('git@123.59.xx.xxx:fe/common_types.git', { args: '@types' }, function () {
    cb();
  });
}

function cleanTypes(cb) {
  gulp.src('@types', { allowEmpty: true }).pipe(clean());
  cb();
}

function transTsx() {
  // 添加 ts-ignore 强行阻止编译校验
  const tsNoCheck = gulp.src(['./**/*.tsx', './**/*.ts', ...MUST_IGNORE_FILES]).pipe(
    through.obj(function (file, encode, cb) {
      var result = file.contents.toString();
      result = '// @ts-nocheck\n' + result;
      file.contents = Buffer.from(result);
      this.push(file);
      cb();
    }),
  );
  var tsResult = tsNoCheck.pipe(tsProject());
  // 生成 js 文件和 d.ts 文件
  return merge([
    tsResult.js
      .pipe(
        minify({
          ext: {
            src: '.js',
            min: '.js',
          },
          noSource: true,
        }),
      )
      .pipe(
        // 编译混淆后的 js 文件禁用 eslint 检查
        through.obj(function (file, encode, cb) {
          var result = file.contents.toString();
          result = '/* eslint-disable */' + result;
          file.contents = Buffer.from(result);
          this.push(file);
          cb();
        }),
      )
      .pipe(gulp.dest('dist')),
    tsResult.dts.pipe(gulp.dest('dist')),
  ]);
}

function moveOtherFile() {
  return gulp
    .src(['./**/*.*', '!./**/*.tsx', '!./**/*.ts', '!./@types/**', ...MUST_IGNORE_FILES], {
      nodir: true,
    })
    .pipe(gulp.dest('dist'));
}

function cleanDist(cb) {
  gulp.src('dist', { allowEmpty: true }).pipe(clean());
  cb();
}

function initEncryptRepository(cb) {
  git.init({ cwd: './dist' }, function (err) {
    if (err) throw err;
    cb();
  });
}

function addOriginEncryptRepositoryUrl(cb) {
  git.addRemote('origin', ENCRYPT_REPOSITORY_URL, { cwd: './dist' }, function (err) {
    if (err) throw err;
    cb();
  });
}

function checkoutEncryptRepositoryDevBatch(cb) {
  git.checkout(ENCRYPT_REPOSITORY_BATCH, { args: '-b', cwd: './dist' }, function (err) {
    if (err) throw err;
    cb();
  });
}

function addEncryptRepositoryChanges(cb) {
  return gulp.src('./dist/*').pipe(
    git.add({ args: '-f', cwd: './dist' }, function (err) {
      if (err) throw err;
    }),
  );
}

function commitEncryptRepositoryChanges(cb) {
  return gulp.src('./dist/*').pipe(
    git.commit('ci: update source', { cwd: './dist' }, function (err) {
      if (err) throw err;
    }),
  );
}

function pushEncryptRepositoryChanges(cb) {
  git.push('origin', ENCRYPT_REPOSITORY_BATCH, { args: '-u -f', cwd: './dist' }, function (err) {
    if (err) {
      if (err) throw err;
    } else {
      cb();
    }
  });
}

gulp.task(
  'publish',
  gulp.series(
    initEncryptRepository,
    addOriginEncryptRepositoryUrl,
    checkoutEncryptRepositoryDevBatch,
    addEncryptRepositoryChanges,
    commitEncryptRepositoryChanges,
    pushEncryptRepositoryChanges,
  ),
);

gulp.task('build', gulp.series(cleanDist, pullDev, pullTypes, transTsx, moveOtherFile, cleanTypes));
```

最终我们可以在控制台使用 `npx gulp build && npx gulp publish` 来编译并且同步更新我们的代码，我们可以使用 ci 来监听代码库的变更，如果发生变更，ci 就自动切换到 `encrypt` 分支来执行该指令，对代码进行编译并同步到加密库。