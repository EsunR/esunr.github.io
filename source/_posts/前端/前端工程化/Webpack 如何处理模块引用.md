---
categories:
  - 前端
  - 前端工程化
---
# 获取未经压缩的 Webpack 打包产出

1. 移除 babel-loader；
2. `optimization.minimize` 设置为 false 以关闭 teser 对代码的压缩；
3. `optimization.concatenateModules` 设置为 false，避免 ESM 模块被提升到主 IIFE 中，不便于我们观察；

# Webpack Runtime

在查看 webpack 导出内容前，我们需要先了解一下 webpack 的运行时方法、属性。

## `__webpack_require__.g`

表示全局对象，这段代码的作用是确保在各种不同的 JavaScript 运行环境中，能够准确地获取到全局对象，从而保证模块化代码在不同环境中的兼容性：

```js
!(function () {
  __webpack_require__.g = (function () {
    if (typeof globalThis === 'object') return globalThis;
    try {
      return this || new Function('return this')();
    } catch (e) {
      if (typeof window === 'object') return window;
    }
  })();
})();
```

## `__webpack_require__.p`

表示脚本的公共路径，如果在 webpack 构建文件中设置了 `output.publicPath`，则会被赋值为设置的路径：

```js
/* webpack/runtime/publicPath */
!(function () {
  __webpack_require__.p = '/';
})();
```

如果没有指定 publicPath，webpack 将会按照下面的方法，在不同的脚本运行环境来自动获取基础路径，如果无法正常获取则会报错：

```js
!(function () {
  var scriptUrl;
  // 在 web worker 环境下获取 scriptUrl
  if (__webpack_require__.g.importScripts)
    scriptUrl = __webpack_require__.g.location + '';
  var document = __webpack_require__.g.document;
  
  // 在浏览器环境下获取 scriptUrl
  if (!scriptUrl && document) {
    // Document.currentScript 属性返回当前正在运行的脚本所属的 <script> 元素
    if (document.currentScript) scriptUrl = document.currentScript.src;
    if (!scriptUrl) {
      var scripts = document.getElementsByTagName('script');
      if (scripts.length) {
        var i = scripts.length - 1;
        while (i > -1 && !scriptUrl) scriptUrl = scripts[i--].src;
      }
    }
  }
  // 当支持不支持自动 publicPath 的浏览器时，您必须通过配置手动指定 output.publicPath
  // 或者传递一个空字符串 ("") 并从您的代码中设置 __webpack_public_path__ 变量以使用您自己的逻辑。
  if (!scriptUrl)
    throw new Error('Automatic publicPath is not supported in this browser');
  // 通过正则表达式替换 scriptUrl 中的 # 和 ? 之后的内容，以及最后一个 / 之后的内容，最终得到的就是 publicPath
  scriptUrl = scriptUrl
    .replace(/#.*$/, '')
    .replace(/\?.*$/, '')
    .replace(/\/[^\/]+$/, '/');
  // 设置 publicPath
  __webpack_require__.p = scriptUrl;
})();
```

在代码运行时，我们可以使用 `__webpack_public_path__` 来指定模块引用的基础路径，如：

```js
// 在代码运行 1000 ms 后将基础路径指定为 '/woo'
setTimeout(() => {
  __webpack_public_path__ = '/woo';
}, 1000);
```

编译后的代码实际上就是将 `__webpack_require__.p` 进行了重新赋值：

```js
setTimeout(() => {
  __webpack_require__.p = '/woo';
}, 1000);
```

## `__webpack_require__.o`

这个方法是 Webpack 用于检测对象是否具有指定名称的属性，但不会检查原型链上的属性。

```js
/* webpack/runtime/hasOwnProperty shorthand */
!(function () {
  __webpack_require__.o = function (obj, prop) {
    return Object.prototype.hasOwnProperty.call(obj, prop);
  };
})();
```

## `__webpack_modules__`

webpack 将编写代码时使用 cjs、esm 导入导出的模块进行转换后存放在该变量下，其格式为：

```ts
type WebpackModules = {
	[moduleId: string]: (module, exports, __webpack_require__) => void
}
```

## `__webpack_module_cache__` 

webpack 的模块缓存，默认为一个空对象，用于存放模块的注册结果，避免重复注册。

## `__webpack_require__`

如果要使用 Webpack 处理过的模块，就需要使用该方法进行导入，该方法创建了一个 `module` 对象，并从 `__webpack_modules__` 拿到对应的模块注册方法，执行模块并将模块导出的内容挂载在 `module` 对象上，让后将 `module` 对象缓存在 `__webpack_module_cache__` 中：

```js
function __webpack_require__(moduleId) {
  // 检查模块是否已经被读取过了
  var cachedModule = __webpack_module_cache__[moduleId];
  if (cachedModule !== undefined) {
    return cachedModule.exports;
  }
  // 创建一个新模块并加入缓存
  var module = (__webpack_module_cache__[moduleId] = {
    id: moduleId,
    loaded: false,
    exports: {},
  });

  // 执行模块（也就是注册模块）
  __webpack_modules__[moduleId](module, module.exports, __webpack_require__);

  // 标记加载状态
  module.loaded = true;

  // 返回模块导出对象
  return module.exports;
}
```

# Webpack 打包 CJS 模块

创建一个 CJS 规范的模块：

```js
function add(a, b) {
  return a + b;
}

function reduce(a, b) {
  return a - b;
}

module.exports = {
  add,
  reduce,
};

exports.CJS_CONSTANCE = 'constance';
```

webpack 会将代码打包为：

```js
// Webpack 处理后的 CJS 模块
var __webpack_modules__ = {
  834: function (
    module,
    exports,
  ) {
    function add(a, b) {
      return a + b;
    }

    function reduce(a, b) {
      return a - b;
    }

    module.exports = {
      add,
      reduce,
    };
    
    exports.CONSTANCE = 'constance';
  }
}
```

当执行 `__webpack_require__(834)` 时，会将模块导出的对象挂载在 `module` 上，并返回 `module.exports`。

# Webpack 打包 ESM 模块

创建一个 ESM 规范的模块：

```js
export function cloneDeep(obj, hash = new WeakMap()) {
  // ... ...
  return cloneObj;
}

export function esmAdd(a, b) {
  return a + b;
}

export function unusedFunc() {
  console.log('this is a unused function');
}

export const ESM_CONSTANCE = 'constance';

export default function () {
  console.log('this is a default export');
}

```

webpack 对于使用 ESM 规范引入的模块，并不是将其赋值到 `module.exports` 上，而是使用 `__webpack_require__.d`：

```js
// Webpack 处理后的 ESM 模块
var __webpack_modules__ = {
  624: function (
    __unused_webpack_module,
    __webpack_exports__,
    __webpack_require__,
  ) {
    'use strict';
    // 将 ESM 模块中的导出内容挂载到 exports 对象上
    // 这样使用 __webpack_require__ 就可以拿到导出内容了
    // 需要注意的是，未使用的 ESM 导出不会在此被注册，如 unusedFunc
    /* harmony export */ __webpack_require__.d(__webpack_exports__, {
      /* harmony export */ K1: function () {
        return /* binding */ ESM_CONSTANCE;
      },
      /* harmony export */ Xh: function () {
        return /* binding */ cloneDeep;
      },
      /* harmony export */ ZP: function () {
        return /* export default binding */ __WEBPACK_DEFAULT_EXPORT__;
      },
      /* harmony export */
    });
    /* unused harmony exports esmAdd, unusedFunc */
    function cloneDeep(obj, hash = new WeakMap()) {
      // ... ...
      return cloneObj;
    }

    function esmAdd(a, b) {
      return a + b;
    }

    function unusedFunc() {
      console.log('this is a unused function');
    }

    const ESM_CONSTANCE = 'constance';

    /* harmony default export */ function __WEBPACK_DEFAULT_EXPORT__() {
      console.log('this is a default export');
    }
  }
};
```

`__webpack_require__.d` 接受一个 `__webpack_require__` 中创建的 `exports` 对象，以及一个导出声明 `definition`。`definition` 是一个对象，其 key 为一个随机字符，value 为一个函数，函数执行后返回对应 ESM 模块导出的某个方法，`__webpack_require__.d` 就是将 `definition` 定义的各个方法挂载到 `exports` 对象上：

```js
/* webpack/runtime/define property getters */
!(function () {
  // define getter functions for harmony exports
  __webpack_require__.d = function (exports, definition) {
	// 遍历 definition 对象
    for (var key in definition) {
      if (
        __webpack_require__.o(definition, key) &&
        !__webpack_require__.o(exports, key)
      ) {
        // 挂载属性
        Object.defineProperty(exports, key, {
          enumerable: true,
          get: definition[key],
        });
      }
    }
  };
})();
```

之所以使用 `__webpack_require__.d` 对 ESM 导出的内容通过属性注册的方式注册到 `module.exports` 上而不是直接赋值，这是因为 ESM 和 CJS 的特性不同决定的：ESM 导出的内容是只读的，所以 `exports` 上的属性只有 getter 没有 setter；ESM 模块导出的是对值的引用，因此需要返回存放值的变量，而 CJS 返回的是对值的拷贝。

# Webpack 打包混用模块

### CJS 中使用 require 引入

```js
const { esmAdd } = require('./index');

function add(a, b) {
  return esmAdd(a, b);
}

function reduce(a, b) {
  return a - b;
}

module.exports = {
  add,
  reduce,
};

exports.CJS_CONSTANCE = 'constance';
```

打包后：

```js
var __webpack_modules__ = {
  834: function (module, exports, __webpack_require__) {
    const { esmAdd } = __webpack_require__(624);

    function add(a, b) {
      return esmAdd(a, b);
    }

    function reduce(a, b) {
      return a - b;
    }

    module.exports = {
      add,
      reduce,
    };

    exports.CJS_CONSTANCE = 'constance';
  }
}
```

使用 `__webpack_require__` 来引入其他模块，没啥特别的。

## CJS 中使用 import 引入

```js
import { esmAdd } from './index';

function add(a, b) {
  return esmAdd(a, b);
}

function reduce(a, b) {
  return a - b;
}

module.exports = {
  add,
  reduce,
};

exports.CJS_CONSTANCE = 'constance';
```

打包后：

```js
var __webpack_modules__ = {
  834: function (
    module,
    __unused_webpack___webpack_exports__,
    __webpack_require__,
  ) {
    /* harmony import */ var _index__WEBPACK_IMPORTED_MODULE_0__ =
      __webpack_require__(624);
    /* module decorator */ module = __webpack_require__.hmd(module);

    function add(a, b) {
      return (0, _index__WEBPACK_IMPORTED_MODULE_0__ /* .esmAdd */.bO)(a, b);
    }

    function reduce(a, b) {
      return a - b;
    }

    module.exports = {
      add,
      reduce,
    };

    exports.CJS_CONSTANCE = 'constance';
  }
}
```

这样的产出在浏览器中是无法正常运行的，控制台会报错：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202405081609627.png)

这是因为 `__webpack_require__.hmd` 对 `module` 对象进行了一层包裹，让 module 在执行 set 时产生报错，后续往 `module.exports` 上赋值自然就会报错了，模块无法执行，`__webpack_require__.hmd` 的实现如下：

```js
/* webpack/runtime/harmony module decorator */
!(function () {
  __webpack_require__.hmd = function (module) {
    module = Object.create(module);
    if (!module.children) module.children = [];
    Object.defineProperty(module, 'exports', {
      enumerable: true,
      set: function () {
        throw new Error(
          'ES Modules may not assign module.exports or exports.*, Use ESM export syntax, instead: ' +
            module.id,
        );
      },
    });
    return module;
  };
})();
```

由此可见，在 CJS 中是无法使用 `import` 语法的，同样的使用 `export` 也会报错。

## ESM 中使用 import 引入

```js
import cjsDefault from './utils/cjs.js';

const addResult = cjsDefault.add(1, 2);

console.log(
  'App ready!',
  addResult,
  cjsDefault.CJS_CONSTANCE,
);
```

编译为：

```js
/* harmony import */ var _utils_cjs_js__WEBPACK_IMPORTED_MODULE_1__ =
  __webpack_require__(834);
/* harmony import */ var _utils_cjs_js__WEBPACK_IMPORTED_MODULE_1___default =
  /*#__PURE__*/ __webpack_require__.n(
    _utils_cjs_js__WEBPACK_IMPORTED_MODULE_1__,
  );

const addResult = _utils_cjs_js__WEBPACK_IMPORTED_MODULE_1___default().add(
  1,
  2,
);

console.log(
  'App ready!',
  addResult,
  _utils_cjs_js__WEBPACK_IMPORTED_MODULE_1___default().CJS_CONSTANCE,
);

(0, _utils__WEBPACK_IMPORTED_MODULE_2__ /* ["default"] */.ZP)();
```

可以看到编译后的代码使用 `__webpack_require__.n` 来包裹 CJS 模块的产出，这是因为 CJS 是没有默认导出，而该方法就是将一个 CJS 模块添加默认导出，默认导出值即为 `module.exports` 出的对象，用于兼容在 ESM 场景下的使用，具体实现如下：

```js
/* webpack/runtime/compat get default export */
!(function () {
  // getDefaultExport function for compatibility with non-harmony modules
  __webpack_require__.n = function (module) {
    var getter =
	  // 如果是 esm 模块的话，就导出模块的 default 对象
      module && module.__esModule
        ? function () {
            return module['default'];
          }
        // 否则就导出整个 module 对象
        : function () {
            return module;
          };
    __webpack_require__.d(getter, { a: getter });
    return getter;
  };
})();
```

## ESM 中使用 require 引入

在 ESM 模块中使用 require 是被允许的：

```js
import { add, CJS_CONSTANCE } from './utils/cjs.js';
 ```

会被转换为：

```js
const { cloneDeep, ESM_CONSTANCE } = __webpack_require__(624);
```

但需要注意的是，如果使用了 require 来引入 ESM 模块，及时模块中未使用的方法也是会被 `__webpack_require__.d` 注册导出的，这就会使模块失去 tree-shaking 的特性，因此谨慎使用 require 导入模块：

```js
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
  /* harmony export */ ESM_CONSTANCE: function () {
    return /* binding */ ESM_CONSTANCE;
  },
  /* harmony export */ cloneDeep: function () {
    return /* binding */ cloneDeep;
  },
  /* harmony export */ default: function () {
    return /* export default binding */ __WEBPACK_DEFAULT_EXPORT__;
  },
  /* harmony export */ esmAdd: function () {
    return /* binding */ esmAdd;
  },
  /* harmony export */ unusedFunc: function () {
    return /* binding */ unusedFunc;
  },
  /* harmony export */
});
```

此外，如果 ESM 中有 `export default` 的默认导出，转为 `require` 引入后会被挂载 `default` 属性下。

# 参考

- https://zhuanlan.zhihu.com/p/508808789
- https://zhuanlan.zhihu.com/p/511058113