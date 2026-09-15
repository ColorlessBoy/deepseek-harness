# dsh-opencode-go-live

让 dsh 的 OpenCode Go 模型列表跟着 `https://opencode.ai/zen/go/v1/models` 实时更新。

`@deepseek-ai/dsh-llm-pi-ai` 的模型目录是**静态**的:厂商新上的模型(例如 `deepseek-v4.1-flash`)要等 dsh 升级才可见。这个 host 插件每次启动及每 30 分钟拉一次实时列表,并据此改写 `llm-pi-ai` 的 provider route。

## 它做什么

实时列表只给 id,而一条手写 route 只能有一种 `api`,所以插件按协议拆成三条 route:

| route | api | baseURL |
|---|---|---|
| `opencode-go` | `openai-completions` | `https://opencode.ai/zen/go/v1` |
| `opencode-go-anthropic` | `anthropic-messages` | `https://opencode.ai/zen/go` |
| `opencode-go-responses` | `openai-responses` | `https://opencode.ai/zen/go/v1` |

已在内置目录里的模型写成裸 `{ id }`,容量 / compat / 思考档位继续从内置目录继承;目录没有的模型(以及需要换协议的)用 `runtime/catalog.json` 里的完整条目。

写入通过 `ctx.settings.update('llm-pi-ai', …)` 并带 `expectedRevision`,下一次请求生效,不需要重启。三条 route 的 `models` 由插件托管——手改会被下次同步覆盖。

## 凭据与必需请求头

- Key 走 dsh 凭据 seam 的 `OPENCODE_API_KEY`(与 pi-ai 内置目录一致),其次进程环境变量。凭据名写错会解析不到。
- Go 端点**强制要求** `x-opencode-session` 请求头,缺了会返回 `400 MissingSessionID`(社区早期教程未覆盖这一点)。插件给三条 route 都写入 `headers.x-opencode-session`,值为进程内稳定的 `dsh-<uuid>`。llm-pi-ai 的 route headers 是静态的,做不到按会话下发,因此同一进程的所有会话共用一个 affinity id。

## 安装

插件源码在 `my-agent/profile/plugins/`，以 `file:` 依赖被 `my-agent/profile/package.json` 引用，安装行在 `my-agent/profile/cordis.patch.yml`：

```yaml
- insert:
    - id: opencode-go-live
      name: dsh-opencode-go-live
```

`my-agent/setup.sh` 会把 `~/.dsh/profiles/<name>` 软链到本仓库的 profile 目录并 `pnpm install`。`file:` 依赖是拷贝而非软链：改了 `runtime/` 要在 profile 目录重跑 `pnpm install`。

## 工具

- `oc_go_status` — 只读:上次同步时间、模型数、上次错误、刷新间隔。
- `oc_go_sync` — 立即拉取并写入。

## 配置

插件 `config` 目前只有 `refreshMs`(默认 `1800000`,最小 1000):

```yaml
- id: opencode-go-live
  name: dsh-opencode-go-live
  config:
    refreshMs: 900000
```

## 已知局限

- 实时列表不披露协议,也不给容量。目录里没有、`catalog.json` 也没有的新 id 会按 Chat Completions + 保守容量(`contextWindow 262144` / `maxTokens 32768`)写入,需要时手改或重跑生成脚本。
- `runtime/catalog.json` 是快照。模型上新后想立即拿到元数据,用 `scripts/generate-catalog.mjs` 重新生成。
- 内置目录里 `reasoning: true` 但没有 thinking map 的模型(如 `minimax-m3`)在拆分出的 route 上会退化为非推理;models.dev 有 effort 档位的(如 `qwen3.8-flash`)会补上。
- 与 `@deepseek-ai/dsh-llm-pi-ai` 的分工:插件只改 `models`/`api`/`baseURL`/`apiKeyEnv`/`headers`,不实现适配器。
- profile 用 `file:` 依赖安装,pnpm 是**拷贝**而非软链;改完插件源码要在 profile 目录重跑 `pnpm install` 才会生效。

## 生成目录快照

```sh
node scripts/generate-catalog.mjs \
  <pi-ai>/dist/providers/data/opencode-go.json \
  ~/.cache/opencode/models.json \
  <live-ids.json> \
  runtime/catalog.json
```

`<live-ids.json>` 是 `GET https://opencode.ai/zen/go/v1/models` 的响应(或 id 数组)。
