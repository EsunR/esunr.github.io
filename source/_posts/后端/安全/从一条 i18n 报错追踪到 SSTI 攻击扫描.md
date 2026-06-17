---
categories:
  - 后端
  - 安全
---
## 一、问题发现

线上服务日志中频繁出现以下错误：

```
Nuxt I18n server context has not been set up yet.
```

起初怀疑是 `@nuxtjs/i18n` 模块在 SSR 渲染流程中的初始化时序问题。但仔细观察后发现，**并非所有请求都会报错**，只有访问 `xxx.xxx.com/` 根路径时才偶发。正常用户请求根路径并不会触发，这引起了我们的警觉。

## 二、什么是 SSTI 攻击

### 模板引擎的工作原理

现代 Web 开发中，服务端通常使用模板引擎（如 Twig、Jinja2、Smarty、FreeMarker）来生成动态 HTML。模板引擎的核心机制是：**在模板字符串中用特殊语法标记变量，渲染时将变量替换为实际数据**。

例如一个 Twig 模板：

```html
<h1>欢迎您，{{ username }}</h1>
<p>您有 {{ notification_count }} 条未读消息</p>
```

渲染时，`{{ username }}` 被替换为真实用户名，`{{ notification_count }}` 被替换为消息数量。

模板引擎通常还提供**过滤器**（filter）和**函数调用**能力，方便开发者处理数据：

```twig
{{ name|upper }}              {# 转大写 #}
{{ price|number_format(2) }}   {# 格式化数字 #}
{{ ['ls']|filter('system') }}  {# Twig 特性：调用系统命令 #}
```

最后一个例子是关键 —— Twig 的 `filter` 过滤器可以传入回调函数名，而 `system` 正是 PHP 的内置函数，能执行操作系统命令。这是 Twig 设计中的一个"特性"，但在攻击者手中就成了武器。

### SSTI 攻击的原理

**SSTI（Server-Side Template Injection，服务端模板注入）** 是一种将恶意模板语法注入到用户输入中的攻击方式。当服务端将用户输入**直接拼接进模板字符串**而非作为变量传入时，攻击者的输入会被模板引擎当作代码执行。

对比正常用法和漏洞用法：

```php
// ✅ 安全：用户输入作为变量传入
$template = 'Hello, {{ name }}!';
echo $twig->render($template, ['name' => $userInput]);

// ❌ 漏洞：用户输入直接拼接到模板字符串中
$template = 'Hello, ' . $userInput . '!';
echo $twig->render($template);
```

在安全写法中，即使用户输入 `{{ 7*7 }}`，模板引擎只会原样输出 `{{ 7*7 }}`，因为它是作为 `name` 变量的值传入的。

在漏洞写法中，如果用户输入 `{{ 7*7 }}`，模板引擎会解析这段模板语法，输出 `49`。这就意味着攻击者的输入被当作代码执行了 —— 从 `{{ 7*7 }}` 到 `{{ ['cat /etc/passwd']|filter('system') }}` 只是换个 payload 的事。

### 什么样的场景会中招

SSTI 的核心前提是：**用户输入被拼接到模板字符串中，而非作为变量传入**。在真实业务中，以下几种常见写法容易中招：

#### 场景一：动态模板拼接

最常见的漏洞模式。开发者为了灵活生成页面内容，把用户输入拼接到模板字符串中：

```php
// PHP + Twig：用户可控的 host 被拼入模板
$host = $_SERVER['HTTP_X_FORWARDED_HOST'] ?? $_SERVER['HTTP_HOST'];
$template = "<p>您正在访问 {{ site_name }}，域名：{$host}</p>";
echo $twig->createTemplate($template)->render(['site_name' => $siteName]);
```

```python
# Python + Jinja2：用户可控的 URL 参数被拼入模板
name = request.args.get('name', '')
template = f"<h1>欢迎，{name}</h1>"
return render_template_string(template)
```

```java
// Java + FreeMarker：用户可控的搜索关键词被拼入模板
String keyword = request.getParameter("q");
String template = "搜索结果：${keyword}";
templateEngine.process(template, model, writer);
```

在这些代码中，`x-forwarded-host`、URL 参数 `name`、搜索关键词 `q` 的值被直接拼接进模板字符串。攻击者只要在对应位置注入 `{{ ['cat /etc/passwd']|filter('system') }}`（Twig）或 `{{ ''.__class__.__mro__[1].__subclasses__() }}`（Jinja2），模板引擎就会执行恶意代码。

#### 场景二：邮件/通知模板渲染

很多系统允许管理员自定义邮件模板，且模板内容中可以使用变量：

```python
# 管理员在后台配置的邮件模板
template = "您好 {{ user.name }}，点击 <a href='{{ host }}/reset?token={{ token }}'>此处</a> 重置密码"

# 如果 host 来自用户可控的 header
host = request.headers.get('X-Forwarded-Host', '')
rendered = template.replace('{{ host }}', host)  # ← 字符串替换，不是模板变量
```

这里的问题是 `host` 是通过字符串替换（而非模板变量注入）进入模板的。如果 `host` 中包含模板语法，会被模板引擎二次解析。

#### 场景三：日志/错误页面模板

一些框架会生成自定义错误页面，将请求信息嵌入模板渲染：

```php
// Laravel 的错误页面模板中直接使用请求信息
// 如果错误页面模板中有类似这样的代码：
$errorPage = "<h1>404 Not Found</h1><p>请求的页面 {{ url }} 不存在</p>";
$url = $request->headers->get('X-Original-URL') ?? $request->path();
echo $twig->createTemplate(str_replace('{{ url }}', $url, $errorPage))->render();
```

攻击者通过注入 `X-Original-URL` header，使恶意内容进入模板渲染流程。

#### 为什么攻击者选择 `x-forwarded-host`

攻击者选择注入 `x-forwarded-host` 而非 URL 参数，原因有：

1. **反射面广**：几乎所有 Web 框架都会读取这个 header 来构造绝对 URL（重定向地址、链接生成、CORS 响应等），意味着更多的代码路径可能触发漏洞
2. **绕过 WAF**：很多 WAF 会检查 URL 参数和请求体，但对 HTTP header 的检查相对宽松
3. **影响缓存**：如果框架用 `x-forwarded-host` 生成缓存 key 或响应内容，恶意 payload 可能被缓存下来影响其他用户（缓存投毒）
4. **历史漏洞多**：Apache、Nginx、各种 PHP 框架都曾出过 `x-forwarded-host` 相关漏洞，攻击者知道这是高风险点

### 攻击者期望的触发方式

攻击者构造的 payload `xxx{{['cat /etc/passwd']|filter('system')}}bbb` 期望的触发路径是：

```
1. 攻击者在 HTTP 请求头中注入 SSTI payload
          ↓
2. 服务端代码将这个 header 值拼接到模板字符串中（上述场景之一）
          ↓
3. 模板引擎渲染时解析 {{ }} 语法
          ↓
4. filter('system') 被调用，执行 cat /etc/passwd
          ↓
5. 命令输出被嵌入 HTML 响应返回给攻击者
```

攻击者用 `xxx` 和 `bbb` 包裹 payload，目的是**快速判断是否存在漏洞**：

- 如果响应中出现了 `/etc/passwd` 的内容 → SSTI 漏洞确认，可以进一步利用
- 如果响应中原样返回了 `xxx...bbb` → 模板语法未被解析，不存在 SSTI
- 如果响应中出现了 `49`（如果 payload 换成 `{{ 7*7 }}`）→ SSTI 漏洞确认

这是一种**探针式扫描**：先低风险地探测是否存在漏洞，再决定是否深入利用。

## 三、定位根因

排查过程中，一条异常请求的完整日志引起了注意：

```json
{
  "headers": {
    "x-forwarded-host": "xxx{{['cat /etc/passwd']|filter('system')}}bbb",
    "user-agent": "Mozilla/5.0 ...;BD-rain inf-ssl-duty-scan",
    "host": "xxx.xxx.com"
  },
  "method": "GET",
  "fullUrl": "/"
}
```

**`x-forwarded-host` 的值正是上文提到的 SSTI 攻击 payload！** 攻击者期望这个值被服务端拼入模板后触发命令执行。虽然我们的服务没有使用 PHP 模板引擎，但恶意 header 依然造成了问题 —— 它导致了 i18n 模块初始化失败。

### 为什么会触发 i18n 报错

我们项目使用 `@nuxtjs/i18n` v10.2.3，其服务端初始化流程如下：

```
请求到达 → Nitro request hook → initializeI18nContext(event) → 设置 event.context.nuxtI18n
    ↓
路由匹配 → SSR 渲染 → render:before hook → useI18nContext(event) → 读取 event.context.nuxtI18n
```

关键代码在 `@nuxtjs/i18n` 的 `initializeI18nContext` 中：

```javascript
const getHost = (event) => getRequestURL(event, { xForwardedHost: true }).host;

async function initializeI18nContext(event) {
    const defaultLocale = runtimeI18n.defaultLocale || "";
    const options = await setupVueI18nOptions(
        getDefaultLocaleForDomain(getHost(event)) || defaultLocale
    );
    // ...
    event.context.nuxtI18n = ctx;
}
```

当 `x-forwarded-host` 包含恶意 payload 时：

1. `getHost(event)` 读取到恶意字符串 `xxx{{['cat /etc/passwd']|filter('system')}}bbb`
2. `getDefaultLocaleForDomain()` 尝试用这个非法 host 匹配域名→locale 映射，内部逻辑因格式异常而失败
3. `setupVueI18nOptions()` 抛出异常
4. Nitro 框架的 `callHook("request", event).catch()` **静默捕获**了该异常，`event.context.nuxtI18n` 仍为 `null`
5. 后续 `render:before` 中 `useI18nContext(event)` 检测到 `nuxtI18n == null` → 抛出 **`Nuxt I18n server context has not been set up yet.`**

**本质问题：** 攻击者通过污染 `x-forwarded-host` header，使 i18n 初始化失败，进而导致 SSR 渲染出错。这是一个 **DoS（拒绝服务）向量** —— 攻击者无需复杂手段，只需构造特殊的 header 就能让请求报 500 错误。

## 四、影响评估

| 维度        | 评估                                                        |
| --------- | --------------------------------------------------------- |
| **命令执行**  | ❌ 未成功。Nuxt/Nitro 不使用 Twig/Smarty 模板引擎，payload 不会被当作模板解析执行 |
| **数据泄露**  | ❌ 未泄露。攻击者未获取任何系统文件内容                                      |
| **服务可用性** | ⚠️ 有影响。恶意请求导致 i18n 初始化失败，SSR 渲染报错，可能返回 500 错误页面           |
| **攻击频率**  | 低频。目前观察到的是扫描探测行为，非针对性攻击                                   |

## 五、修复方案

在服务端最早的中间件 `server/middleware/00.requestCheck.ts` 中增加恶意 header 检测，**在 i18n 初始化之前就拦截恶意请求**，同时利用已有的 `dangerRequestLimiter` 实现渐进式限流。

### 核心实现

```typescript
/**
 * 检测 x-forwarded-host 等请求头是否包含恶意注入 payload（SSTI、XFF 污染、CRLF 注入等）
 * 正常域名仅包含字母、数字、点、连字符和冒号，出现模板/脚本语法字符即为恶意
 *
 * @returns 恶意 header 的名称，无恶意则返回空字符串
 */
function checkMaliciousHeader(event: H3Event): string {
    const MALICIOUS_HEADER_REGEXP: RegExp = /[{}|$`\\]/;
    const HEADERS_TO_INSPECT: string[] = [
        'x-forwarded-host', 'x-forwarded-for', 'x-original-url', 'x-rewrite-url'
    ];
    for (const headerName of HEADERS_TO_INSPECT) {
        const headerValue = getHeader(event, headerName) || '';
        if (headerValue && MALICIOUS_HEADER_REGEXP.test(headerValue)) {
            return headerName;
        }
    }
    return '';
}
```

### 正则设计思路

`/[{}|$`\\]/` 匹配的字符及对应攻击类型：

| 字符 | 攻击类型 |
|------|----------|
| `{` `}` | SSTI 模板语法（Twig `{{ }}`、Jinja2 `{{ }}`、Smarty `{literal}`） |
| `|` | Twig filter 链（`|filter('system')`） |
| `$` | PHP 变量注入（`${system('id')}`）、shell 变量替换 |
| `` ` `` | Shell 命令替换（`` `id` ``） |
| `\` | 转义绕历、CRLF 注入 |

**正常域名字符集**：字母、数字、`.`、`-`、`:`，不会出现以上任何字符。该正则的误报率极低。

## 六、修复效果

以攻击日志中的请求为例：

```
x-forwarded-host: "xxx{{['cat /etc/passwd']|filter('system')}}bbb"
```

**修复前**：请求穿过中间件 → i18n 初始化失败 → SSR 渲染报错 → 日志刷 `Nuxt I18n server context has not been set up yet.` → 用户可能看到 500 页面

**修复后**：请求到达 `00.requestCheck` → `checkMaliciousHeader` 检测到 `{{` 和 `|` → 直接返回 403 → `dangerRequestLimiter` 记录 IP → 持续扫描自动 ban → i18n 不再报错

## 七、延伸思考

### 1. `x-forwarded-host` 污染是常见的攻击面

`x-forwarded-host` 经常被框架用于生成 URL（如 `getRequestURL(event, { xForwardedHost: true })`），如果服务端未校验其合法性，攻击者可以：

- **SSTI 注入**：注入模板语法，若后端使用模板引擎渲染则可能导致 RCE
- **缓存投毒**：伪造 host 让服务端生成指向攻击者域名的 URL，缓存后影响其他用户
- **密码重置投毒**：伪造 host 使重置密码邮件中的链接指向攻击者站点
- **DoS**：如本案例，导致依赖 host 的模块初始化失败

### 2. Nitro 的 hook 错误处理机制

Nitro 的 `callHook("request", event).catch()` 会静默捕获 hook 异常。这是一个合理的设计（避免单个 hook 异常影响整个请求流程），但也意味着：

- 上游 hook 的失败**不会传播**到下游
- 下游 hook 需要自行处理上游数据可能缺失的情况
- **依赖 hook 初始化的上下文数据，必须考虑兜底方案**

### 3. 防御纵深

此次修复在中间件层面拦截恶意请求，属于**入口层防御**。理想情况下还应在框架层面增加防御：

- 向 `@nuxtjs/i18n` 上游反馈：`initializeI18nContext` 不应因 host 格式异常而整体失败，应 catch 异常并回退到 `defaultLocale`
- 框架层面应对 `x-forwarded-host` 做基本的域名格式校验
