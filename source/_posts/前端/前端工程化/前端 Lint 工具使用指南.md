---
title: 前端 Lint 工具使用指南
tags:
  - lint
  - eslint
  - stylelint
  - commitlint
  - 前端工程化
  - 代码检查
categories:
  - 前端
  - 前端工程化
date: 2022-07-11 14:11:22
---

# 1. ESLint

[官网](https://eslint.org/)

ESLint 可以静态分析你的代码，得以让你快速发现代码中的错误部分。它内置于大多数文本编辑器中，你还可以将 ESLint 作为持续集成管道的一部分，在持续集成的过程中帮你检查代码。

## 1.1 安装

> 如果你使用 VSCode，记得安装 ESLint 插件

```
npm install eslint --save-dev
```

## 1.2 使用 Eslint 推荐配置

 ESLint 内置了一个推荐的规则集 `eslint:recommended` ，你可以按照如下配置开启，首先，创建 `.eslintrc.js` :

```js
module.exports = {
    "extends": [
        "eslint:recommended"
    ],
    "parserOptions": {
	    // ECMAScript 语言版本，默认为 5
        "ecmaVersion": 2018,
        // 模块引用类型，默认为 script，如果使用 ESModule，设置为 module
        "sourceType": "module"
    }
}
```

[配置规则详情](https://eslint.org/docs/rules/)(只有规则列表中标有 ✅  的才是 `eslint:recommended` 规则集中启用的)

## 1.3 与 Prettier 一起使用

prettier 相关的规则 npm 包有两款，一款是 [eslint-config-prettier](https://github.com/prettier/eslint-config-prettier)，另外一款是 [eslint-plugin-prettier](https://github.com/prettier/eslint-plugin-prettier#readme)，这两款 npm 包的区别如下：

`eslint-config-prettier` 只是一个规则集，仅作为 `extends` 使用，他仅仅是禁用了一些第三方规则中与 prettier 冲突的部分，但它本身并不提供 eslint 的校验，**因此你需要将其搭配其他 eslint 规则插件使用**，并作为 `extends` 的最后一项使用用以覆盖那些其他插件规则中与 prettier 相冲的部分：

```js
module.exports = {
    "extends": [
        "eslint:recommended",
        "eslint-config-prettier"
    ],
    "parserOptions": {
        "ecmaVersion": 2018,
        "sourceType": "module"
    }
}
```

`eslint-plugin-prettier` 是一个插件，它将 prettier 的规则作为 eslint 规则使用，当你的代码中出现不符合 prettier 规范的代码时，会触发 eslint 的报错警告，参考配置如下：

```js
module.exports = {
    plugins: ["prettier"],
    parserOptions: {
        ecmaVersion: 2018,
        sourceType: "module",
    },
    rules: {
        "prettier/prettier": "error"
    },
};
```

最好的做法是将 `eslint-config-prettier` 和 `eslint-plugin-prettier` 共同使用，前者会消除掉 eslint 中对格式的校验部分，后者可以将 prettier 的设置作为代码的格式校验规则并应用到 eslint 中：

```js
module.exports = {
  extends: ["prettier"],
  plugins: ["prettier"],
  parserOptions: {
    ecmaVersion: 2018,
    sourceType: "module",
  },
  rules: {
    "prettier/prettier": "error",
    "arrow-body-style": "off",
    "prefer-arrow-callback": "off",
  },
};
```

> 关闭 arrow-body-stlye 和 prefer-arrow-callback 的规则，否则会 [出问题](https://github.com/prettier/eslint-plugin-prettier#arrow-body-style-and-prefer-arrow-callback-issue)

## 1.4 与 Typescript 集成

如果你的项目是 typescript 搭建的，那么你需要一份 typescript 的规则集以及 parser，推荐使用 `@typescript-eslint/parser` 与 `@typescript-eslint/eslint-plugin`：

```sh
yarn add --dev @typescript-eslint/parser @typescript-eslint/eslint-plugin
```

.eslintrc.js:

```js
module.exports = {
  extends: ['eslint:recommended', 'plugin:@typescript-eslint/recommended'],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  root: true,
};
```

更多信息可以参考[官方指南](https://typescript-eslint.io/docs/)

## 1.5 与 Husky 集成

使用 `lint-staged` + `husky` 的配置对每次代码进行提交检查是一个好习惯，你可以先看[《使用 husky 每次提交时进行代码检查》](https://blog.esunr.site/2022/05/d36522b1089c.html)这篇文章来快速了解 husky 的使用。

安装完 `lint-staged` 和 `husky` 后，在 `package.json` 中添加：

```json
"lint-staged": {  
	"src/**/*.{js,vue,ts}": "eslint --cache --fix",
	"src/**/*": "prettier --write"
}
```

在 `pre-commit` hook 中添加：

```sh
npx lint-staged
```

# 2. Stylelint

[官网](https://stylelint.io/)

Stylelint 与 ESLint 其实一样，都是对代码进行静态分析，在你编写代码的时候就检查代码中的错误并给出警报或者帮你自动修复。

## 2.1 安装

> 如果你使用 VSCode，记得安装 Stylelint 插件

```sh
npm install --save-dev stylelint stylelint-config-standard
```

## 2.2 配置

创建一个 `stylelint.config.js` 文件，并写入：

```js
module.exports = {
    extends: [
        'stylelint-config-standard',
    ]
}
```

当然你也可以添加其他的插件，比如你想用 StyleLint 来检查 stylus 样式，就可以使用 [stylelint-plugin-stylus](https://ota-meshi.github.io/stylelint-plugin-stylus/#introduction) 插件。

## 2.3 使用自定义规则

如果你想要自定义规则，则可以在 `rules` 字段中添加，比如：

```js
module.exports = {
    extends: [
        'stylelint-config-standard',
    ],
    rules: {
        'stylus/property-no-unknown': [
            true,
            {
                // https://stylelint.io/user-guide/rules/list/property-no-unknown/
                ignoreProperties: ['fixed', 'absolute', 'relative'],
            },
        ],
        'stylus/at-rule-no-unknown': [
            true,
            {
                // https://stylelint.io/user-guide/rules/at-rule-no-unknown
                ignoreAtRules: ['forward', 'use'],
            },
        ],
        'stylus/selector-type-no-unknown': [
            true,
            {
                // https://stylelint.io/user-guide/rules/list/selector-type-no-unknown/
                ignoreTypes: ['odd', 'even', '2n', '2n+1', '/\-?\d?n\+\d/', '/^[1-9]/', '/(\-)?n/'],
            },
        ],
        // >>> 和 /deep/ 指令已被废弃、使用 v-deep(.cls) 代替
        // https://github.com/vuejs/rfcs/blob/master/active-rfcs/0023-scoped-styles-changes.md
        'selector-pseudo-class-no-unknown': [
            true,
            {
                ignorePseudoClasses: ['v-global', 'v-deep', 'v-slotted', 'deep'],
            },
        ],
        'selector-pseudo-element-no-unknown': [
            true,
            {
                ignorePseudoElements: ['v-deep', 'v-global', 'v-slotted'],
            },
        ],
        // 禁止分号
        'stylus/semicolon': [
            'never',
        ],
        // 禁止冒号
        'stylus/declaration-colon': ['never'],
        'comment-empty-line-before': ['always', {
            // http://stylelint.cn/user-guide/rules/comment-empty-line-before/
            except: ['first-nested'],
        }],
    },
}
```

## 2.4 与 husky 集成

stylelint 仍推荐与 `lint-staged` 和 `husky` 集成，在 `lint-staged` 规则里写入：

```json
{
  "*.css": "stylelint",
  "*.scss": "stylelint --syntax=scss" // 如果需要 scss 校验的话
}
```

# 3. CommitLint

[官网](https://commitlint.js.org/#/?id=getting-started)

## 3.1 安装

```sh
npm install @commitlint/cli @commitlint/config-conventional -D
```

## 3.2 配置

创建一个 `commitlint.config.js` 文件来配置 commitlint 的规则，以下是官方推荐的一行配置：

```sh
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js
```

## 3.3 生成标准化的 commit

可以使用 [commitzen](https://github.com/commitizen/cz-cli) 来帮助生成标准化的 commit，从而通过 commitlint 的校验。

安装：

```sh
npm install commitizen -D
```

在 `package.json` 中添加 `scripts`：

```json
"scripts": {
  "commit": "cz"
}
```

同时，在 `package.json` 中添加 `config`：

```json
"config": {
  "commitizen": {
    "path": "cz-conventional-changelog"
  }
}
```

然后每次提交代码时，将 `git commit -m "xxx"` 替换为 `npm run commit` 然后按照 cli 指令输入内容即可。

## 3.3 与 husky 集成

创建 `commit-msg` hook 并添加内容：

```sh
#!/bin/sh
. "\$(dirname "\$0")/_/husky.sh"

npx --no -- commitlint --edit "\${1}"
```

为 hook 添加执行权限：

```sh
chmod a+x .husky/commit-msg
```

如果使用 husky 4，则在 package.json 中添加：

```json
"husky": {
	"hooks": {
		"commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
	}
}
```