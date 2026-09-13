# zcode-for-agents

让 **Codex、Claude Code** 等编码代理学会使用 **ZCode**（智谱 GLM 的编码代理）：提供一份遵循 [vercel-labs/skills](https://github.com/vercel-labs/skills) 管理模式的 skill，教宿主 agent 何时、如何通过 ZCode 的 headless CLI 委托任务。

灵感与结构参考了 [Hermes 的 autonomous-ai-agents-codex skill](https://hermes-agent.nousresearch.com/docs/zh-Hans/user-guide/skills/bundled/autonomous-ai-agents/autonomous-ai-agents-codex)（教 agent 调用 Codex CLI 的同型范例）与 [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc)（把 Codex 接入 Claude Code 的官方插件）。

## 它解决什么

宿主 agent（Codex / Claude Code / ZCode 等）默认不知道：

1. ZCode CLI **不在 PATH**——它随桌面 App 分发（`/Applications/ZCode.app/.../zcode.cjs`），要用 `ELECTRON_RUN_AS_NODE=1` 方式调用；
2. headless 委托范式：`zcode -p "<任务>" --json`、`--cwd`、`--attach`、`--mode`、`--resume` 等；
3. **何时该委托**：浏览器/桌面自动化、文档生成（Word/PPT/Excel/PDF）、定时任务、并行子任务。

本项目的 `use-zcode` skill 把这三件事写成 agent 可执行的规则。

## 安装

**① 安装 skill**（vercel-labs/skills 模式，自动软链到所有已装 agent 的目录）：

```sh
npx skills add dej4vu/zcode-for-agents -g
```

**② 创建 zcode 命令**（skills CLI 做不了的部分）：

```sh
git clone https://github.com/dej4vu/zcode-for-agents.git
cd zcode-for-agents && bash install.sh
```

`install.sh` 幂等，做三件事：

- 在 `~/.local/bin/zcode` 写入 wrapper（等价于 `ELECTRON_RUN_AS_NODE=1 ... zcode.cjs "$@"`），跨平台探测安装位置（macOS / Windows / Linux）；
- 若 `~/.zcode/cli/config.json` 不存在且桌面 App 已登录，从 `~/.zcode/v2/config.json` 复用 coding-plan key 生成 headless CLI 的模型配置（桌面与 CLI 的模型配置是两套独立入口，且 `zcode login` 的 OAuth 有已知 bug [feedback#51](https://github.com/zai-org/feedback/issues/51)）；
- 向 `~/.codex/AGENTS.md` 和 `~/.claude/CLAUDE.md` 注入一小段带标记的指针规则（`--no-pointers` 可跳过；已安装 skill 的 agent 会自动触发 skill，指针段是兜底）。

## 验证

```sh
zcode version                          # wrapper 就绪
npx skills list -g                     # use-zcode 已安装
zcode -p "列出当前目录的文件名" --json    # headless 冒烟测试（在任意临时目录执行）
```

## 卸载

```sh
bash uninstall.sh              # 移除 wrapper 与指针段
npx skills remove use-zcode -g # 移除 skill
```

## 项目结构

```
skills/use-zcode/
├── SKILL.md              # 核心：使用场景 / 前置条件 / headless 范式 / 标志表 / 工作流 / 决策规则
└── references/
    └── cli.md            # ZCode CLI 完整速查（子命令、全部 flag、已知限制）
install.sh / uninstall.sh # zcode wrapper + 指针段（幂等）
```

## License

MIT
