---
categories:
  - AI
---
# 1. Skills

## 项目 Skills 的重要性

Skill 是 Agent 工作过程中的重要文件，编写一个完善的 Skill 能够更好的指导 Agent 去正确的理解和处理工作。

Skill 分为全局和项目级别：

- 全局 Skill：如果你的 Skill 是用于优化你个人的工作流、或者是增强 Agent 能力的，比如浏览器相关的能力、PDF 读取的能力、Superpowers，那么这些 Skill 的定位应该是全局的，否则会对团队他人的 Agent 工作流造成影响，这是不被允许的；
- 项目 Skill：如果某个 Skill 是专门为项目定制的，比如正确添加一个前端页面的工作流程、进行数据库 Migration 的工作流程。亦或者是某些 Skill 是仅为了提升当前项目的开发准确性的，比如当前项目是使用了 Nextjs 技术栈，那么安装官方的 Nextjs skill 有助于 Agent 更好的理解 Next 项目的最佳实践， 那么这个 Skill 就可以作为项目 Skill 安装；

对于团队项目来说，**团队成员应该为了 Agent 工作的准确性编写各种 Skill**，如单测、浏览器自动化回归、日志查询、项目上线部署，这些繁杂的流程都应该抽离为 Skill 与团队共享，对于让 Agent 更好的理解项目是相当有用的。

## 如何在团队间共享 Skills

### 目前存在的困境

在一个团队中，团队成员会使用各种各样的 Code Agent 工具，这是没法统一的，此外每个 Agent 工具读取 Skills 的路径也是不一样的，这就会出现这样的问题：团队成员 A 使用的是 claude code，其 Skills 编写和读取的路径为 `.claude/skills`，而团队成员 B 使用的是 cursor，其 Skills 路径为 `.cursor/skills`。团队成员 A 和团队成员 B 之间编写的 Skills 在各自的 Code Agent 工具中是无法通用的。

为了保持 Skills 的统一性，vercel-lab 编写了 skills 这个安装器，意图是将 skills 进行类似 npm package 那样进行标准化管理，我们可以借助这个工具标准化 Skill 的创建与安装，并实现团队间的共享。

对于 Skills 的安装，如果这个 Skills 是按照标准流程发布的，那么就可以直接使用 skills 指令进行安装，如：

```sh
npx skills add vercel-labs/agent-skills
```

在安装过程中，如果一个 skills 仓库中包含了多个 skills，cli 会询问你具体安装哪个，按需选择即可：

```
◆  Select skills to install (space to toggle)
│  ◻ deploy-to-vercel (Deploy applications and websites to Vercel. Use when the ...)
│  ◻ vercel-cli-with-tokens
│  ◻ vercel-react-native-skills
│  ◻ web-design-guidelines
└
```

然后 cli 会询问你具体应用给哪个 Agent，但是在选择前你会看到 cli 提示你会始终创建一个 `.agents/skills` 目录，并且将 skills 安装到这个目录下。这是因为 vercel 试图创建一个标准化的 skills 目录来让所有的 Code Agent 工具读取，就是 `.agents` 目录，目前已经有数个 Agent 支持了，比如 Cursor、Codex、Opencode 等。但是仍有一些不愿意支持，比如 Claude Code，因此对于不支持的 Code Agent 工具，你需要在下面进行手动勾选。

```
◇  55 agents
◆  Which agents do you want to install to?
│
│  ── Universal (.agents/skills) ── always included ────────────
│    • Amp
│    • Antigravity
│    • Cline
│    • Codex
│    • Cursor
│    • Deep Agents
│    • Dexto
│    • Firebender
│    • Gemini CLI
│    • GitHub Copilot
│    • Kimi Code CLI
│    • OpenCode
│    • Warp
│
│  ── Additional agents ─────────────────────────────
│  Search:
│  ↑↓ move, space select, enter confirm
│
│ ❯ ○ AiderDesk (.aider-desk/skills)
│   ○ Augment (.augment/skills)
│   ○ IBM Bob (.bob/skills)
│   ● Claude Code (.claude/skills)
│   ○ OpenClaw (skills)
│   ○ CodeArts Agent (.codeartsdoer/skills)
│   ○ CodeBuddy (.codebuddy/skills)
│   ○ Codemaker (.codemaker/skills)
│  ↓ 32 more
│
│  Selected: Amp, Antigravity, Cline +11 more
└
```

然后会询问将这个 Skill 安装为项目还是全局，如果是项目级别，那么 `.agent` 目录会在项目目录进行创建，否则会创建在操作系统的用户目录下：

```
◆  Installation scope
│  ● Project (Install in current directory (committed with your project))
│  ○ Global
└
```

然后 skills 会要求你选择 skill 的安装方式，如果是 `Copy to all agents`，那么它会将 skill 复制到每个你勾选的 Code Agent 工具的 skill 目录下，这样就不能统一更新了。所以推荐的做法是选择 `Symlink`，他会只在 `.agent/skills` 目录下安装一份 Skill，然后会将 skill 以系统软连接的方式链接到每个 Code Agent 工具的专属 skill 目录下面：

> 但是目前存在一个 bug，你的 Code Agent 的专属目录必须先创建出来（比如如果你是用 claude code 就要先创建 .claude 目录），否则你使用 Symlink 的方式去安装就会发现只生成了一个 `.agent` 目录。

```
◆  Installation method
│  ● Symlink (Recommended) (Single source of truth, easy updates)
│  ○ Copy to all agents
└
```

安装完成后你会发现项目中还生成了一个 `skills-lock.json` 的文件，他规定了所有 skill 的安装版本，防止团队成员间安装的开源 skill 版本不一致造成的错误。

# 2. Rules

# 3. Spec
