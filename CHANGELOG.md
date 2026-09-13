# Changelog

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
