# Changelog

## 0.0.4 (2026-09-13)

- 修正 flag 文档：逐个实测 0.16.5 headless 解析器，`--help` 列出的以下 flag 实际**未实现**（传入报 `Unknown option`）：`--max-turns`、`--allowed-tools` / `--disallowed-tools`、`--target`、`--permission-mode`、`--settings`、`--surface`、`--browser-use`、`--allow-main-worktree-yolo`
- SKILL.md / references/cli.md 的标志表改为实测标注（✅/❌），并注明选项位置建议（统一放 `-p` 之前最稳；`--locale` 在 prompt 之后会被拒）

## 0.0.3 (2026-09-13)

- wrapper 运行时优先级调整：优先用**系统 Node（>=22）**直接运行 `zcode.cjs`（纯 Node bundle，无 Chromium 开销），无合适 Node 时回退到 Electron 二进制（`ELECTRON_RUN_AS_NODE=1`）
- skill 文档同步更新调用范式说明

## 0.0.2 (2026-09-13)

- 默认模型改为 **GLM-5.3-Flash**：CLI 模型配置（`~/.zcode/cli/config.json`）只注册 `glm-5.3-flash` 一个模型，`model.main` / `lite` 均指向它
- headless 实测通过（`-p/--json`、`--attach`、`--mode plan`、`--resume`，默认走 flash）

## 0.0.1 (2026-09-13)

首个版本。

- `use-zcode` skill：教 Codex、Claude Code 等编码代理何时、如何通过 headless CLI 委托任务给 ZCode
  - 使用场景决策、跨平台定位 CLI（macOS / Windows / Linux）
  - headless 范式：`zcode -p ... --json`、`--attach`、`--mode`、`--resume`、`--max-turns`
  - 典型工作流与决策规则；`references/cli.md` 完整 CLI 速查
- `install.sh`（幂等）：
  - 创建 `~/.local/bin/zcode` wrapper（ZCode CLI 随桌面 App 分发，不在 PATH）
  - 从桌面配置（`~/.zcode/v2/config.json`）复用 coding-plan key 生成 headless CLI 模型配置（绕过 `zcode login` 的 OAuth bug，见 zai-org/feedback#51）
  - 向 `~/.codex/AGENTS.md`、`~/.claude/CLAUDE.md` 注入带标记的指针规则
- 遵循 [vercel-labs/skills](https://github.com/vercel-labs/skills) 管理模式，支持 `npx skills add dej4vu/zcode-for-agents -g`
- 已在本机（macOS, ZCode.app 3.11.2 / CLI 0.16.5）实测：headless 单次任务、`--attach`、`--mode plan`、`--resume` 全部通过
