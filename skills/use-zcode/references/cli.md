# ZCode CLI 速查

> 采集自 `zcode --help`（zcode 0.16.5，随 ZCode.app 3.11.2 分发）。如与你本机版本不符，以 `zcode --help` 输出为准。

## 调用方式

ZCode CLI 不在 PATH 中，随桌面 App（Electron）分发。按平台定位：

| 平台 | 主程序 | CLI 入口（zcode.cjs） |
|---|---|---|
| macOS | `/Applications/ZCode.app/Contents/MacOS/ZCode` | `/Applications/ZCode.app/Contents/Resources/*/zcode.cjs` |
| Windows | `%LOCALAPPDATA%\Programs\ZCode\ZCode.exe` 或 `C:\Program Files\ZCode\ZCode.exe` | 同目录 `resources\*\zcode.cjs` |
| Linux | `/opt/ZCode*/zcode`、`/usr/lib/zcode*/zcode` | 同目录 `resources/*/zcode.cjs` |

目录名可能随版本变化，用 glob 探测取第一个存在的匹配。`zcode.cjs` 是纯 Node bundle，运行时两种选择：

1. **系统 Node（>=22，首选）**：`node <zcode.cjs> <args>`——无 Chromium 开销；
2. **Electron 二进制回退**：`ELECTRON_RUN_AS_NODE=1 <主程序> <zcode.cjs> <args>`——机器上没有合适 Node 时使用。

`install.sh` 生成的 `~/.local/bin/zcode` wrapper 已自动按此优先级选择，之后直接用 `zcode <args>`。

## 子命令

| 子命令 | 作用 |
|---|---|
| `tui` | 交互式终端界面 |
| `app-server` | stdio 协议服务（供客户端集成） |
| `doctor` | 诊断安装、登录、配置状态 |
| `login` / `logout` | 登录 / 登出 |
| `version` | 版本号 |
| `skills list` | 列出已发现的 skills |
| `commands list` | 列出可用的 slash 命令 |
| `plugins list` | 列出插件 |

## Headless / 运行模式

| 标志 | 说明 |
|---|---|
| `-p, --print "prompt"` | positional prompt 的 headless 运行，跑完退出 |
| `--prompt "prompt"` | 同为非交互单条 prompt |
| `--json` | 机器可读输出（**没有** `--output-format`，用这个替代） |
| `--max-turns <n>` | 限制 agent 轮数 |
| `--target <text>` / `--target-replace` | headless 模式的目标 / goal |

## 上下文与工作目录

| 标志 | 说明 |
|---|---|
| `--cwd <path>` | 工作目录 |
| `--attach <path>` | 给 `--prompt` 附带本地文件（可重复） |

## 权限

| 标志 | 说明 |
|---|---|
| `--mode <build\|edit\|plan\|yolo>` | 权限模式；`--prompt` / `-p` 默认宽权限（yolo） |
| `--permission-mode` | `--mode` 的旧别名 |
| `--allowed-tools <list>` | 工具白名单 |
| `--disallowed-tools <list>` | 工具黑名单 |
| `--allow-main-worktree-yolo` | 允许在主 worktree 中使用 yolo |

## 会话

| 标志 | 说明 |
|---|---|
| `--resume <sess_...>` | 续接指定会话 |
| `-c, --continue` | 续接最近会话 |

## 其他

| 标志 | 说明 |
|---|---|
| `--settings <path>` | 指定 settings 文件 |
| `--locale <en-US\|zh-CN\|auto>` | 输出语言 |
| `--browser-use headless` | 浏览器任务用无头模式 |
| `--browser-executable <path>` | 指定浏览器可执行文件 |
| `--surface <terminal\|desktop>` | 运行表面 |
| `--no-browser` / `--no-color` / `--verbose` | 杂项开关 |

## 已知限制

- **无 `--model` 标志**：模型由配置或会话内 `/model [id]` 决定。
- **`--settings` 在 headless 解析器中未实现**（help 里列出但会报 Unknown option）。
- 内置 slash 命令（`/compact`、`/expert`、`/fork`、`/mcp`、`/mode`、`/model`、`/new`、`/resume`、`/rewind`、`/skill [name] [task]`、`/goal` 等）在交互会话内使用，headless 下不可依赖。

## 模型配置（headless 必需）

headless CLI 的模型 provider 配置在 `~/.zcode/cli/config.json`（与桌面 App 的 `~/.zcode/v2/config.json` 是两套独立入口，不同步；`zcode login` 的 OAuth 有已知 bug，见 zai-org/feedback#51）。schema（可从 `install.sh` 自动生成）：

```json
{
  "provider": {
    "bigmodel": {
      "kind": "anthropic",
      "name": "BigModel Coding Plan",
      "options": {
        "apiKeyRequired": true,
        "baseURL": "https://open.bigmodel.cn/api/anthropic",
        "apiKey": "<coding-plan API key>"
      },
      "models": { "glm-5.3-flash": { "name": "GLM-5.3-Flash" } }
    }
  },
  "model": { "main": "bigmodel/glm-5.3-flash", "lite": "bigmodel/glm-5.3-flash" }
}
```

要点：

- `kind: "anthropic"` 表示走 Anthropic 兼容协议；`model.main` 的格式是 `<providerId>/<modelId>`。
- **端点选择**：`https://open.bigmodel.cn/api/anthropic`（BigModel Coding Plan 的 key）可用；桌面 App 使用的 `https://zcode.z.ai/api/v1/zcode-plan/anthropic` 对裸 headless CLI 一律返回 `3007 captcha verify failed`（风控拦截，与模型名无关），不要用。
- 配置文件解析失败会被静默吞掉并统一报 "Model config is missing"；诊断要看 `~/.zcode/cli/log/zcode-*.jsonl` 里的 `config.file.invalid` 事件。
- 报 429 / code 1308 是账号 5 小时用量上限（等待重置），不是配置错误。
