# 1. ESLint

[官网](https://eslint.org/)

ESLint 可以静态分析你的代码，得以让你快速发现代码中的错误部分。它内置雨大多数文本编辑器中，你还可以将 ESLint 作为持续集成管道的一部分，在持续集成的过程中帮你检查代码。

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
        "ecmaVersion": 2018,
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

简单来说你可以这样做决定：

- 如果你想用其他的规则并且想用 Prettier，那么就使用 `eslint-config-prettier` 与其他规则配合使用；
- 如果你的代码规范不那么严格（就是懒），仅仅需要 Prettier 的规范即可，那么仅仅安装并配置一个 `eslint-plugin-prettier` 即可。

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

# 3. CommitLint