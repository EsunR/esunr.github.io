---
title: 让 Claude Code 像 OpenClaw 一样连接你的浏览器
tags: []
categories:
  - AI
date: 2026-03-17 10:33:22
---
# 前言

年后 OpenClaw 国内爆火，但说实话自己在云端或者虚拟机部署一个玩玩还行，但是真的让在自己本地部署一个助手级的 AI，OpenClaw 那个烂代码和安全性我属实不敢恭维。

OpenClaw 并没有创新什么东西，只是内置了一堆 Skill 以及能够通过 IM 来远程调用，仅此而已。但如果是在本地干活来说，远程调用是没有必要的，那 OpenClaw 的优势就只剩下开箱即用的一堆自动化 Skill 了，但不得不说 OpenClaw 的 Browser Tool 确实好用，底层调用的是 Playwright 框架，运行时还会自己编写执行脚本，只要 token 够用以及有足够多的耐心，那么其可以胜任 80% 的需求（虽然配好 OpenClaw 的 Browser 也简直是一种顶级折磨）。

那 Claude Code 就不能实现同等的需求了吗？那必须有的，官方已经出了 [Playwright Plugin](https://claude.com/plugins/playwright)，在官方的 [Plugin 订阅源](https://github.com/anthropics/claude-plugins-official)里安装即可（或者你也可以直接去安装 Playwright 的 MCP）。安装完成之后，当你想访问某个页面，Claude Code 就会自动调用 Playwright 的 MCP 服务来访问这个页面并进行自动化操作。

但实际用下来存在以下的问题 ：

- Playwright 非常依赖大模型的能力，可以用和会用的差别很大；
- Playwright 并非为 AI 设计，没有针对 Agent 自动化提供针对性的优化；
- 由于 Playwright 本质是拉取整个页面的内容，所以他会连带 AI 不需要读取的样式等一起反馈给 AI，如果连续操作多个页面，会导致上下文丢失；

所以相比 Playwright MCP，我更推荐使用 Vercel 推出的 [Agent Browser](https://agent-browser.dev/)，一款专门用于 AI Agent 的浏览器 Cli 工具，相对于 Playwright MCP 来说，其抓取的结构更适合 AI 阅读、更减少 Token 消耗，同时还针对对浏览器下载、会话保持等场景进行了优化。

# Agent Browser 安装

Agent Browser 提供了多种安装方式，推荐使用 npm 全局安装：

```bash
# 全局安装（推荐）
npm install -g agent-browser

# 首次使用需要下载 Chrome
agent-browser install
```

`agent-browser install` 命令会从 [Chrome for Testing](https://developer.chrome.com/blog/chrome-for-testing/) 下载 Chrome 浏览器，这是 Google 官方提供的自动化测试渠道，无需额外安装 Playwright 或 Node.js 依赖。

如果你使用 macOS，也可以通过 Homebrew 安装：

```bash
brew install agent-browser
agent-browser install
```

Linux 用户需要安装额外的系统依赖：

```bash
agent-browser install --with-deps
```

安装完成后，你可以通过以下命令快速体验：

```bash
agent-browser open example.com
agent-browser snapshot                    # 获取页面的可访问性树
agent-browser screenshot page.png         # 截图
agent-browser close
```

# 装载 Skill

Agent Browser 本身只是一个命令行工具，为了让 LLM 能够了解如何使用这个工具，Agent Browser 官方提供了一系列开箱即用的 Skill，将其安装到 Claude Code、Codex、Github Copilot 等 Agent 工具中后，当我们的会话中包含网页请求相关的要求时，LLM 就会调用 Agent Browser。

Agent Browser 提供以下官方 Skills：

| Skill              | 描述                                                                                    |
| ------------------ | ------------------------------------------------------------------------------------- |
| **agent-browser**  | 核心 Skill，教授完整的 agent-browser API：导航、快照、表单填充、截图、数据提取、会话、认证、Diff 比较等                    |
| **dogfood**        | 系统性探索测试工具，像真实用户一样导航应用，发现 Bug 和 UX 问题，生成带有截图和复现视频的结构化报告                                |
| **electron**       | 自动化任何 Electron 应用（VS Code、Slack、Discord、Figma 等），通过连接其内置的 Chrome DevTools Protocol 端口 |
| **slack**          | 基于 Slack 的浏览器自动化，检查未读消息、导航频道、搜索对话、发送消息等，无需 API 令牌                                     |
| **vercel-sandbox** | 在 Vercel Sandbox 微型 VM 中运行 agent-browser + 无头 Chrome，支持 Next.js、SvelteKit、Nuxt 等框架    |

我们可以通过 [skills](https://github.com/vercel-labs/skills) CLI 工具直接安装这些 skill，这是一个 skill 管理工具，支持 OpenCode、Claude Code、Codex、Cursor 等 40+ 种 AI Agent 的 skill 的统一管理。

```bash
# 安装 agent-browser 核心技能
npx skills add vercel-labs/agent-browser --skill agent-browser

# 安装探索测试技能
npx skills add vercel-labs/agent-browser --skill dogfood

# 安装 Electron 自动化技能
npx skills add vercel-labs/agent-browser --skill electron

# 安装 Slack 自动化技能
npx skills add vercel-labs/agent-browser --skill slack

# 安装 Vercel Sandbox 技能
npx skills add vercel-labs/agent-browser --skill vercel-sandbox
```

# 配置 Agent Browser 让其更好用

Agent Browser 的一些默认配置并不太好用，比如默认使用的是无头模式（headless）、每次会话启动的都是一个新的 Chrome Profile 因此无法持久化一些登录信息等。但是你都可以在 `~/.agent-browser/config.json` 中进行修改（你需要手动创建配置文件），以下是参考配置：

```json
{
    "headed": true, // 默认以 headful 模式打开页面，方便真人介入操作
    "profile": "~/.agent-browser/profiles/default", // 创建一个持久化的 Chrome Profile 给 Agent Browser 使用
    "downloadPath": "./downloads" // 默认的文件下载路径（不能使用 `~`，只能使用相对路径写法）
}
```

# 实用用例

LLM + 浏览器自动化也是需要调教的，如果你只想通过一句话就让 LLM 达到你的最终目的大概率是没法成功的，因为它会像一个新人小白一样不断的进行操作 - 截图 - 思考 - 再操作的流程。因此对于一个比较流水线式的工作，你应该为其描述一个完整的工作流，固化为一个 Skill，那么下次你再让 LLM 替你干活的时候，它就会读取这份 skill 按照完整的工作流做事，避免了像一个无头苍蝇一样乱撞。

例如我们想让 Claude Code 帮我们读取 BLS 的日志并进行分析，就可以为其简单描述一个流程：

```
1. 使用 agent-browser 登录 BLS 平台
2. 点击 `.xxx` 元素，进入日志列表
3. 按照用户需求生成日志的查询语句，日志规则参考 `reference/sql.md` 文件（这个文件你可以让大模型爬百度云的文档来生成）
4. 操作页面中的过滤器，并输入查询语句进行查询
5. 点击下载日志按钮（下载按钮元素为 `.xxx`），使用 `agent-browser download .xxx ~/Download` 下载完整日志到本地
6. 在本地分析日志，给出结论
```

让 Claude Code 按照这个流程完成一次完整的工作，在工作的过程中我们可以随时打断并调整 Claude Code 的工作流，当其完成后将所有的操作总结生成一份 SKILL.md，这样我们就完成了 Cluade Code 对一个流水线式的工作的初步调教。后续我们就不断完善、优化这份 SKILL，直至 Claude Code 能够彻底流畅的完成这个任务。