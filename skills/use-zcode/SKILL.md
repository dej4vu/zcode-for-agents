---
name: use-zcode
description: 将编码任务委托给 ZCode CLI（headless 运行 GLM 编码代理）。Use when the user mentions ZCode (智谱 GLM 的编码代理), asks to delegate a task to ZCode, or when a task benefits from ZCode's unique capabilities — browser-use / computer-use 自动化、document-skills 文档生成（Word/PPT/Excel/PDF）、定时任务、zcode-guide 插件生态 — or from a parallel autonomous sub-agent. Covers headless invocation (zcode -p / --json), permission modes, session resume, and delegation decision rules.
---

# ZCode 委托

把任务委托给本机安装的 ZCode——智谱 GLM 的编码代理，通过其 headless CLI 以子进程方式运行。你在宿主 agent 中协调，ZCode 作为独立会话执行并返回结果；两者并行协作，互不替代。

## 使用场景

**委托给 ZCode：**

- 用户明确提到 ZCode，或要求"让 ZCode 做 / 交给 ZCode"
- 任务依赖 ZCode 的独有能力：
  - **browser-use / computer-use**：浏览器自动化、GUI 黑盒测试、桌面操作
  - **document-skills**：生成 Word / PPT / Excel / PDF
  - **定时自动化**：创建持久化的 cron / 延迟任务
  - **zcode-guide 插件生态**：ZCode 自身的 skills / hooks / MCP / plugins 配置与诊断
- 需要一条**并行、独立**的长时间子任务（互不阻塞主对话）

**不委托：**

- 简单的文件编辑、搜索、问答——自己做更快
- 需要与用户多轮确认的对话——headless 无法中途追问，一次性给全上下文

## 定位 ZCode CLI

ZCode CLI 随桌面 App（Electron）分发，默认不在 PATH。按顺序定位：

1. **先试 PATH**：`command -v zcode`。装过本项目 `install.sh`（或用户已配好别名/软链）时直接可用，验证：

   ```sh
   zcode version   # 输出版本号即就绪
   zcode doctor    # 诊断安装状态
   ```

2. **按平台搜索默认安装位置**（找到 `<app>` 主程序与 `zcode.cjs` 后用第 3 步范式调用）：

   | 平台 | 常见安装位置 |
   |---|---|
   | macOS | `/Applications/ZCode.app`（主程序 `Contents/MacOS/ZCode`，CLI 入口 `Contents/Resources/*/zcode.cjs`，如 `glm/zcode.cjs`） |
   | Windows | `%LOCALAPPDATA%\Programs\ZCode\` 或 `C:\Program Files\ZCode\`（主程序 `ZCode.exe`，CLI 入口 `resources\*\zcode.cjs`） |
   | Linux | `/opt/ZCode*`、`/usr/lib/zcode*`、`~/opt/ZCode*`（主程序 `zcode`，CLI 入口 `resources/*/zcode.cjs`） |

   实际目录名可能因版本不同，用 glob 探测（如 `ls /Applications/ZCode.app/Contents/Resources/*/zcode.cjs`），取第一个存在的匹配。

3. **调用范式**——`ELECTRON_RUN_AS_NODE=1` 让 Electron 主程序以纯 Node 运行 CLI 入口：

   ```sh
   # macOS
   ELECTRON_RUN_AS_NODE=1 /Applications/ZCode.app/Contents/MacOS/ZCode \
     /Applications/ZCode.app/Contents/Resources/glm/zcode.cjs version
   # Windows (cmd)
   set ELECTRON_RUN_AS_NODE=1 && "%LOCALAPPDATA%\Programs\ZCode\ZCode.exe" resources\glm\zcode.cjs version
   # Linux
   ELECTRON_RUN_AS_NODE=1 /opt/ZCode/zcode /opt/ZCode/resources/glm/zcode.cjs version
   ```

4. **模型配置**：桌面 App 与 headless CLI 的模型配置是两套独立入口（桌面在 `~/.zcode/v2/config.json`，CLI 在 `~/.zcode/cli/config.json`），不会自动同步；且 `zcode login` 的 OAuth 流程存在已知 bug（zai-org/feedback#51）。本项目 `install.sh` 会从桌面配置复用 coding-plan key 自动生成 CLI 配置。若 headless 报 "Model config is missing"，运行 `install.sh` 即可；报 429/1308 是账号 5 小时用量上限，等待重置，不要换 key 重试。

## 单次任务

最小范式——`-p` 进入 headless 模式，跑完即退出：

```sh
zcode -p "修复 src/api.ts 中 parseHeaders 函数的空指针问题，并补充测试" \
  --cwd /path/to/project \
  --json
```

- `--cwd` 指定工作目录；不给则继承当前目录
- `--json` 输出机器可读结果（含会话 id、最终回复），脚本化解析用它；人工查看可省略
- 给 ZCode 看本地文件用 `--attach <path>`（可重复）：

```sh
zcode -p "按这份设计稿实现页面" --attach ./design.png --cwd ./webapp
```

## 后台 / 长任务

Bash 工具默认超时约 2 分钟，而 headless 代理任务常需数分钟以上。两种处理：

1. **调大超时**：在支持 timeout 参数的环境里显式设长（如 600000 ms）。
2. **后台运行**：用宿主 agent 的后台执行能力（如 `run_in_background`）启动，之后轮询输出；用 `--json` 从结果中取 `session id`，需要续接时 `--resume <sess_...>` 或 `-c`（继续最近会话）：

```sh
zcode -p "把整个项目从 Jest 迁移到 Vitest" --cwd . --json --max-turns 80
# 稍后续接同一会话
zcode --resume sess_xxx -p "跑通全部测试后提交" --json
```

`--max-turns <n>` 限制 agent 轮数，长任务适当调高；不设则按默认策略运行。

## 关键标志

| 标志 | 作用 |
|---|---|
| `-p "prompt"` / `--prompt "prompt"` | headless 单次运行，完成后退出 |
| `--json` | 机器可读输出（解析结果、提取 session id） |
| `--cwd <path>` | 指定工作目录 |
| `--attach <path>` | 附带本地文件给 prompt（可重复） |
| `--mode <mode>` | 权限模式 `build` / `edit` / `plan` / `yolo`，见下方规则 |
| `--max-turns <n>` | 限制 agent 轮数 |
| `--resume <sess_...>` / `-c` | 续接指定 / 最近会话 |
| `--allowed-tools` / `--disallowed-tools` | 工具白名单 / 黑名单（逗号分隔） |
| `--locale <en-US\|zh-CN\|auto>` | 输出语言 |
| `--browser-use headless` | 强制浏览器任务使用无头模式 |

注意：**没有 `--model` 标志**，模型由 ZCode settings 或会话内 `/model` 决定，不要尝试传模型参数。

## 典型工作流

**代码审查（只读）**——用 `plan` 模式确保不改文件：

```sh
zcode -p "审查当前未提交的改动，按严重程度列出问题" --mode plan --cwd . --json
```

**临时目录里做试验**——避免污染当前仓库：

```sh
tmp=$(mktemp -d) && zcode -p "写一个 Go 的并发安全 LRU 缓存并配基准测试" --cwd "$tmp" --json
```

**并行子任务**——多个独立任务可同时启动多个 ZCode 进程（各自 `--cwd` 隔离），全部后台运行后统一收集结果；互不共享会话。

**委派文档生成 / 浏览器自动化**——直接在 prompt 中描述产物与路径，ZCode 侧的 skills 会自动触发：

```sh
zcode -p "把 notes.md 整理成一份周报 PPT，输出到 ./weekly.pptx" --cwd . --json
```

## 规则

- **prompt 一次给全**：目标、约束、涉及文件、期望的产出物路径。headless 无法中途追问，缺上下文 = 返工。
- **模式最小化**：审查/分析类任务显式 `--mode plan`；需要改动时 `--mode edit` 或 `build`；仅在隔离环境（临时目录、容器、专用 worktree）才用默认的宽权限模式。
- **超时给足**：headless 任务以分钟计，前台运行必须设长超时，否则用后台运行。
- **不要干预运行中的进程**——用轮询观察输出，结束后读 `--json` 结果；失败可用 `--resume` 续接修正。
- **产出物落盘**：让 ZCode 把结果写文件（报告、代码、文档），你读取文件验收，而不是只依赖终端输出。
- 允许同时运行多个 ZCode 进程，但注意各进程对同一仓库的写冲突——并行任务请用不同 `--cwd` 或 git worktree 隔离。

完整 CLI 速查（全部子命令与 flag）见本 skill 目录下 `references/cli.md`。
