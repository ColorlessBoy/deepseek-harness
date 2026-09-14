# 自建 Agent 插件清单（my-agent 分支）

本文基于社区 [awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin) 精选列表整理，供你挑选组合成自己的 agent。当前分支：`my-agent`。

> 安装任何插件都会以你的权限在本机运行第三方代码，可能读写文件、使用凭证、访问网络；工具审批不隔离插件代码。请先看源码，不熟悉的插件先放到没有密钥的环境里试。

## 安装方式

所有插件都通过 profile 安装，装完重启该 profile 生效：

```sh
# 官方市场（推荐第一个装，之后可在 Settings 里一键装其他插件）
dsh plugin --profile web add dshmarket

# 从 GitHub 或 npm 安装
dsh plugin --profile web add github:owner/repo
dsh plugin --profile web add <npm-package-name>

# 查看组合结果、移除
dsh --profile web --dump-config
dsh plugin --profile web remove <package>
```

如果你想做的是一个独立于 `web` 的自有 profile，见 [docs/user/develop/basic/publish.md](docs/user/develop/basic/publish.md)。

## A. 起步必装（发现与管理）

- [dsh-market/dsh-market](https://github.com/dsh-market/dsh-market) — DSH 内置插件市场，Settings 里浏览、搜索、一键安装/升级/备份。
- [awesome-dsh-plugin/dsh-find-plugin](https://github.com/awesome-dsh-plugin/dsh-find-plugin) — 让 agent 在会话内按关键词/分类找插件并给出安装命令。
- [cynch18/plugin-switch](https://github.com/cynch18/plugin-switch) — Settings 里开关任意插件、即时生效、可分组与撤销。

## B. 模型接入与路由

- [NOirBRight/dsh-llm-ollama](https://github.com/NOirBRight/dsh-llm-ollama) — Ollama Cloud 适配器，含模型发现、上下文窗口、web 搜索/抓取。
- [NOirBRight/dsh-llm-codex](https://github.com/NOirBRight/dsh-llm-codex) — 用官方 OAuth 走 ChatGPT Codex 订阅，含实时限额。
- [lujianjun19/dsh-llm-github-copilot](https://github.com/lujianjun19/dsh-llm-github-copilot) — GitHub Copilot 适配器（OAuth device flow、模型发现、视觉、双协议）。
- [welsione/dsh-model-router](https://github.com/welsione/dsh-model-router) — 多 provider 统一路由，首 token 失败切换、冷却、按档位自动选择。
- [btspoony/dsh-llm-fallbacks](https://github.com/btspoony/dsh-llm-fallbacks) — 基于角色的 LLM 重试与降级策略。
- [drscrewdriver/dsh-llm-openai-completions](https://github.com/drscrewdriver/dsh-llm-openai-completions) — 兼容 OpenAI completions 的自托管后端（vLLM / LM Studio / 代理），支持视觉。
- [PerryLink/dsh-local-ai](https://github.com/PerryLink/dsh-local-ai) — Ollama 本地 provider，含模型管理、健康检查、本地路由与云端回退。

## C. 记忆（跨会话）

- [00080000/dsh-project-memory](https://github.com/00080000/dsh-project-memory) — 项目记忆，与原生任务系统集成，会话待办和文件读取沉淀为可引用的跨会话任务记录。
- [PerryLink/dsh-memento](https://github.com/PerryLink/dsh-memento) — 有界、分层、审批门控的跨会话记忆，提供 `ctx.memory` seam 与 SQLite provider。
- [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight) — 长期项目记忆，自动 recall/retain、知识页、深度反思、按 repo 分记忆库。
- [Asher-2000/dsh-memory-connect](https://github.com/Asher-2000/dsh-memory-connect) — 自动抽取 + SQLite FTS5 + RRF 语义召回 + 时序上下文图，零配置。
- [modusensus/dsh-mneme](https://github.com/modusensus/dsh-mneme) — 跨会话记忆，含 autoDream 归纳、冲突冻结、可回放审计与实体图。
- [agentscope-ai/ReMe](https://github.com/agentscope-ai/ReMe) — 接入 ReMe 本地优先的自演化知识库，Markdown 记忆 + BM25 检索。

## D. 工具与 MCP

- [Chhlafiu4312/dsh-mcp-bridge](https://github.com/Chhlafiu4312/dsh-mcp-bridge) — 零依赖 MCP 客户端桥，把 stdio/HTTP MCP 工具注册为 `mcp_<server>_<tool>`。
- [leaforbook/dsh-mcp-lazy](https://github.com/leaforbook/dsh-mcp-lazy) — 懒加载 MCP 路由，只保留共享 router，按需展开 schema，保护缓存前缀。
- [Rianico/dsh-better-edit](https://github.com/Rianico/dsh-better-edit) — 基于内容哈希的 read/edit/batch_edit/undo，替代行号定位。
- [everclear077/dsh-progressive-tools](https://github.com/everclear077/dsh-progressive-tools) — 缓存稳定的渐进式工具发现，固定 `tool_search`/`tool_dispatch` 接口。
- [JohnXu22786/apply-patch](https://github.com/JohnXu22786/apply-patch) — 将结构化 unified diff 应用到真实文件系统，模糊定位、可反向撤销。
- [988hj7tczd-oss/dsh-computer-use](https://github.com/988hj7tczd-oss/dsh-computer-use) — 跨平台 Computer Use，11 个工具、AX 树零视觉模式、带安全护栏。

## E. 安全与权限

- [940842546/dsh-permissions](https://github.com/940842546/dsh-permissions) — Claude Code 风格权限规则引擎，hard/deny/ask/allow 分级 + 可视化编辑器。
- [PerryLink/dsh-permission-rules](https://github.com/PerryLink/dsh-permission-rules) — 声明式有序 YAML 规则，按工具名、参数、工作区路径、agent 身份匹配。
- [PerryLink/dsh-defend](https://github.com/PerryLink/dsh-defend) — 在 pre-step / pre/post-execute 检测 prompt 注入、越狱、泄密模式，分 allow/ask/block。
- [JohnXu22786/safety-net](https://github.com/JohnXu22786/safety-net) — 危险命令拦截门，按 41 条内置规则判断 shell 语义。
- [JohnXu22786/secret-guard](https://github.com/JohnXu22786/secret-guard) — 阻止读写敏感文件、掩码泄漏的密钥样式值，保留审计日志。
- [tancheng33/dsh-egress-guard](https://github.com/tancheng33/dsh-egress-guard) — 运行时出网门，拒绝非白名单主机、脱敏凭证、追加 JSONL 审计。
- [863683348/dsh-plugin-gate](https://github.com/863683348/dsh-plugin-gate) — 安装期扫描插件的脚本/权限/密钥/网络回调，给出 BLOCK/WARN/PASS。

## F. Git 与代码审查

- [988hj7tczd-oss/harness-github](https://github.com/988hj7tczd-oss/harness-github) — GitHub 连接器，18 个工具覆盖 PR 审查、issue 分诊、CI 调试（写入需审批）。
- [JohnXu22786/github-mcp](https://github.com/JohnXu22786/github-mcp) — GitHub workbench MCP，23 个工具覆盖 repo/issue/PR/review/search。
- [JohnXu22786/worktree-mgr](https://github.com/JohnXu22786/worktree-mgr) — 按任务隔离 git worktree，自动分支 create/sync/finish 与批量清理。
- [Viger1/dsh-review](https://github.com/Viger1/dsh-review) — 对抗式代码审查：并行发现 + 独立验证者负责反驳每条发现。
- [luomeii/dsh-review-squad](https://github.com/luomeii/dsh-review-squad) — 并行只读审查子 agent（安全/正确性/测试/风格），汇总为按严重度分组的报告。
- [9087/dsh-diff-approval](https://github.com/9087/dsh-diff-approval) — 收集 edit/write 改动，按块或整文件 keep/revert 审批，diff 数据持久化。

## G. 工作流与自动化

- [Ceelog/dsh-plugin-scheduled-tasks](https://github.com/Ceelog/dsh-plugins) — 按项目定时 prompt，以全新 headless 会话运行，支持一次性/间隔/cron。
- [JohnXu22786/file-planning](https://github.com/JohnXu22786/file-planning) — 落盘执行计划，里程碑/步骤状态机、依赖门控与完成门。
- [huxint/dsh-team](https://github.com/huxint/dsh-team) — 命名长生命周期队友 agent，共享任务列表、邮箱与虚拟工作区。
- [linkbag/dsh-swarm-orchestrator](https://github.com/linkbag/dsh-swarm-orchestrator) — 角色化 AI 集群，按角色固定模型、审查循环、证据契约与实时看板。
- [GM-HZ/agent-dag-workflow](https://github.com/GM-HZ/agent-dag-workflow) — 宿主中立的持久 DAG 工作流，含 CLI/MCP/skills/触发器/回放/可视化 Canvas。
- [jiezeng2004-design/dsh-requirements-alignment](https://github.com/jiezeng2004-design/dsh-requirements-alignment) — 运行时需求漂移守卫，让长任务不偏离已批准的目标与约束。

## H. Skills（技能）

- [cheshireez/dsh-skill-hub](https://github.com/cheshireez/dsh-skill-hub) — GUI 内技能中心，浏览/搜索/开关/诊断/脚手架本地技能。
- [988hj7tczd-oss/dsh-skill-creator](https://github.com/988hj7tczd-oss/dsh-skill-creator) — 会话内一次性生成 SKILL.md：捕获意图、起草、校验、打包、分发。
- [fuxin123z/dsh-skill-manage](https://github.com/fuxin123z/dsh-skill-manage) — agent 自管的程序性记忆，用 `skill_manage` 创建/修改/停用/删除自己的技能。
- [LayneChai/superpowers-dsh](https://github.com/LayneChai/superpowers-dsh) — 把 obra/superpowers 移植为 14 个原生 DSH 技能（TDD、调试、计划、协作）。
- [JohnXu22786/skill-framework](https://github.com/JohnXu22786/skill-framework) — 14 个 Agent Skills（计划、测试、调试、审查、交付）打包为一个 Cordis 插件。

## I. 会话与消息

- [23swccp/dsh-undo](https://github.com/23swccp/dsh-undo) — 用 Shadow Git 快照做会话与工作区撤销，被撤销的轮次不再进入模型上下文。
- [po-et/dsh-session-snapshot](https://github.com/po-et/dsh-session-snapshot) — 轮次边界滚动备份，完整性校验，DSH 起不来时也能一键恢复。
- [LeslieWylie/dsh-session-search-pro](https://github.com/LeslieWylie/dsh-session-search-pro) — 通过 `sessionQuery` 服务搜索/列出/读取历史会话（FTS5 或扫描回退）。
- [Nwflower/dsh-chat-import](https://github.com/Nwflower/dsh-chat-import) — 从 13 个 coding agent 导入聊天历史为可续跑会话，并支持反向导出到 Claude Code。
- [MingoZhou/dsh-replay](https://github.com/MingoZhou/dsh-replay) — 在可播放时间线上回放会话，含每步 token、fork 谱系与独立 HTML 导出。
- [po-et/dsh-session-guard](https://github.com/po-et/dsh-session-guard) — 每会话建议锁，防止并发写损坏，死主自动接管。

## J. 浏览器与 Web

- [JohnXu22786/browser-automation](https://github.com/JohnXu22786/browser-automation) — 经 MCP（Playwright 内核）做真实浏览器自动化，22 个 `web_*` 工具基于可访问性快照。
- [Tencent/BrowserSkill](https://github.com/Tencent/BrowserSkill) — 控制可见 Chrome/Edge Agent Window，支持可访问性与 VOM 观测。
- [240xu/dsh-websearch](https://github.com/240xu/dsh-websearch) — 聚合搜索，一次查询并发打到 11 个引擎，URL 去重合并。
- [chendefine/dsh-web-search-aggregation](https://github.com/chendefine/dsh-web-search-aggregation) — 9 provider 优先级队列的搜索 provider，多 key 轮换与有序回退。
- [2672243194/dsh-read-url](https://github.com/2672243194/dsh-read-url) — 抓取任意页面为干净正文，字符集探测、噪声剥离、SPA 渲染与爬取。

## K. 开发与运行时可观测

- [asdf17128/dsh-doctor](https://github.com/asdf17128/dsh-doctor) — `config_doctor` 工具，检查 patch/entry/tool 名配置问题（这些问题默认会静默启动）。
- [ayahunter/dsh-plugin-clinic](https://github.com/ayahunter/dsh-plugin-clinic) — 只读的插件健康门诊：loader 健康、依赖完整性、版本兼容、patch 完整性。
- [loongsuite/dsh-plugin](https://github.com/loongsuite/dsh-plugin) — 把会话/agent-loop/LLM/工具生命周期事件转成 OpenTelemetry GenAI traces/metrics（OTLP/HTTP）。
- [PerryLink/dsh-test-drive](https://github.com/PerryLink/dsh-test-drive) — 在一次性 profile 中做插件隔离安装与冒烟测试，产出结构化 pass/fail 记录。
- [BiBoyang/dsh-eval-harness](https://github.com/BiBoyang/dsh-eval-harness) — 评测 harness，YAML 用例驱动真实 headless 运行并断言工具调用、参数与 token。
- [JohnXu22786/headless-json](https://github.com/JohnXu22786/headless-json) — 面向 CI 的结构化输出：JSON/NDJSON 会话报告、JUnit XML、语义退出码、脱敏。
- [strukto-ai/mirage](https://github.com/strukto-ai/mirage) — 把文件系统/bash provider 换成 RAM、S3、Redis、Slack、Gmail、Notion、Postgres 之上的虚拟工作区。

## L. 文档与多模态

- [liustack/modlens](https://github.com/liustack/modlens) — 视觉桥，为粘贴的图片返回结构化 JSON 证据（OCR、版面、语义）。
- [Anionex/dsh-vision-toolkit](https://github.com/Anionex/dsh-vision-toolkit) — 给纯文本模型加视觉：图片问答、多图对比、长截图 OCR、元素定位、像素 diff。
- [zhtx2024/dsh-pdf](https://github.com/zhtx2024/dsh-pdf) — PDF 解析工具（`pdf_info`、`pdf_extract_text`、`pdf_render_page`），双渲染引擎含 CJK 字体。
- [linkingoscar/dsh-attachment-formats](https://github.com/linkingoscar/dsh-attachment-formats) — PDF 文本层与扫描 OCR、Office docx/xlsx/pptx 转 Markdown、长文档索引卡。
- [didclawapp-ai/DSH-Office](https://github.com/didclawapp-ai/DSH-Office) — 通过本地 `office_*` 工具创建/读取/编辑 PPTX、DOCX、XLSX、PDF。
- [AKS1st/dsh-mermaid](https://github.com/AKS1st/dsh-mermaid) — 将聊天中的 Mermaid 代码块渲染为懒加载 SVG，带净化与主题跟随。

## M. 通知、集成与远程

- [THEWOLFWALKER/dsh-notifier](https://github.com/THEWOLFWALKER/dsh-notifier) — 一个 `notify()` API 覆盖 27 个通道，并支持手机审批。
- [534119219/dsh-messaging](https://github.com/534119219/dsh-messaging) — 27 个 IM 平台统一网关，扫码授权、按平台隔离工作区。
- [openma-ai/deepseek-harness-acp](https://github.com/openma-ai/deepseek-harness-acp) — ACP profile 插件与独立 stdio server，让 Zed 等 ACP 客户端使用 DSH agent。
- [icodesign/orbis](https://github.com/icodesign/orbis) — 原生 iOS/Android 远程控制 App，端到端加密、工作区浏览与实时更新。
- [dsh-ssh/dsh-ssh](https://github.com/dsh-ssh/dsh-ssh) — SSH 远程工作区，bash/文件/glob/grep 在远端执行，远端零安装。
- [mingzeng21/dsh-notion](https://github.com/mingzeng21/dsh-notion) — 经官方 Notion MCP（OAuth + PKCE）连接页面、数据库与评论。

## N. 用量与成本

- [Jannchie/dsh-bill](https://github.com/Jannchie/dsh-bill) — 按 models.dev + OpenRouter（8000+ 模型）计价，含每轮成本行、成本归因与 `bill_stats`。
- [PerryLink/dsh-budget](https://github.com/PerryLink/dsh-budget) — 在 `llm/stream` waterfall 上做按插件用量预算与成本上限，warn/block 分级。
- [tma1-ai/dsh-otel](https://github.com/tma1-ai/dsh-otel) — 把 agent loop 导出到 GreptimeDB 的 OTel traces/metrics/logs，附 7 个 Grafana 面板。
- [vitas/dsh-model-pricing](https://github.com/vitas/dsh-model-pricing) — Settings 展示约 7250 个模型 / 213 个 provider 的定价，按实际路由计价。

## 建议的起步组合（最小可用）

先只装这几类，确认稳定后再加：

```sh
dsh plugin --profile web add dshmarket
dsh plugin --profile web add dsh-find-plugin
dsh plugin --profile web add 940842546/dsh-permissions      # 或 PerryLink/dsh-permission-rules
dsh plugin --profile web add 00080000/dsh-project-memory
dsh plugin --profile web add Chhlafiu4312/dsh-mcp-bridge
dsh plugin --profile web add 23swccp/dsh-undo
```

> 仓库地址给的是 `owner/repo` 形式时，`dsh plugin add` 前通常需要加 `github:` 前缀，或直接使用 npm 包名。以上命令按你的实际情况调整。

## 下一步

- 想改 agent 的身份/工具集/技能，走 **agent preset**：把 `agent.cordis.yml` 放到 `<dshHome>/.agent-presets`，见 [packages/preset/agent-presets/README.md](packages/preset/agent-presets/README.md)。
- 想做成独立发行版，写一个 **bundle** 再组进自己的 **profile**，见 [docs/user/develop/basic/publish.md](docs/user/develop/basic/publish.md)。
- 完整清单见 [awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)，插件仓库可加 `dsh-plugin` topic 便于被发现。
