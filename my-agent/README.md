# my-agent — 以 git 分支为同步机制的 dsh profile

`my-agent/profile/` **就是** dsh 的 `web` profile。本机通过软链把它挂到 `$DSH_HOME/profiles/web`：

```
~/.dsh/profiles/web -> <repo>/my-agent/profile
```

因此装插件、改 patch 都直接落在仓库工作区，`git status`/`git diff` 就是要提交的内容；换电脑就是 clone + 一条 setup。不再有"抄回仓库"这一步。

## 目录

```
my-agent/
  profile/                     # 真实 profile（软链目标）
    package.json               # 插件依赖（版本/commit 已固定）+ dsh.profile.bundles
    pnpm-lock.yaml             # 精确锁定，含 github 依赖的 tarball 与 commit
    pnpm-workspace.yaml        # hoisted 链接器 + autoInstallPeers + allowBuilds
    cordis.yml                 # profile 根（空 entry 列表）
    cordis.patch.yml           # 用户 patch 层（插件行的 config 覆盖写在这里）
    node_modules/              # 被 gitignore
  node_modules -> $DSH_HOME/profiles/node_modules   # dsh 依赖回退，setup.sh 建
  setup.sh                     # 建软链 + pnpm install
  dsh.sh                       # setup + 启动 dsh（日常入口）
  use-key.sh                   # 命令行切换 OpenCode Go 生效 key
  fixes/                       # 一次性修复脚本（apply + rollback，带快照）
  .gitignore                   # node_modules / .dsh-market / apply 快照
```

本地 `file:` 插件已不再需要：所有插件都来自 registry 或固定的 GitHub 仓库。

## 已记录的插件

| 包 | 版本/来源 | 作用 |
|---|---|---|
| `dsh-opencode-go` | `github:ColorlessBoy/dsh-opencode-go#c630ad2`（[仓库](https://github.com/ColorlessBoy/dsh-opencode-go)，MIT） | OpenCode Go 全套：实时模型/协议路由 + key 池用量卡片与点击切换 |
| `dshmarket` | `^1.47.0` | 插件市场（Settings 内一键装/升级） |
| `dsh-find-plugin` | `^0.3.7` | 会话内搜索插件 |
| `dsh-profile-plugin-switch` | `github:cynch18/plugin-switch#3f13f7a7e1c995f38e80f1af8c206ff7bb749329` | GUI 实时开关任意插件 |
| `dsh-better-sidebar` | `^0.19.1` | VSCode 式右侧工作台（文件/终端/浏览器等） |
| `@yolk_vat-y/dsh-project-memory` | `^0.5.4` | 项目记忆 |

`dsh-opencode-go` 由早期的 `dsh-opencode-go-live`（模型同步）与 `@xiaweiliang060035/dsh-opencode-go-usage` 的 fork（用量面板）合并而来，上游用量组件（MIT）的署名保留在其仓库内。依赖按 **commit 固定**，升级时改 pin 再 `pnpm install`。

完整候选清单见仓库根目录 [MY-AGENT-PLUGINS.md](../MY-AGENT-PLUGINS.md)。

## 另一台电脑拉取

```sh
git clone <this-repo> && cd deepseek-harness
git checkout my-agent
pnpm install && pnpm run build          # 构建 dsh 本体
bash my-agent/setup.sh                  # 建软链 + 按 lockfile 装插件
bash my-agent/dsh.sh web                # 启动（会自动再确认软链 + install）
```

`setup.sh` 只做两件事：把 `$DSH_HOME/profiles/<name>` 软链到 `my-agent/profile`，然后在该目录 `pnpm install`。插件一致的原因全在提交进分支的 `pnpm-lock.yaml` + 固定的 GitHub commit + registry 版本。若目标机已有同名 profile 真目录，`setup.sh` 会报错让你先移走，不会覆盖。

### 密钥要手动配一次（不在 git 里）

`$DSH_HOME/settings.yaml`（模型/插件设置）与 `$DSH_HOME/.credentials.yaml`（密钥）是本机数据，**不进仓库**。新机器至少写：

```yaml
# ~/.dsh/.credentials.yaml
version: 1
refs:
  OPENCODE_API_KEY: sk-…            # 模型请求实际使用；缺了会报 MISSING_CREDENTIAL
  OPENCODE_GO_KEY_qq: sk-…          # 池成员（用量面板用）
  OPENCODE_GO_KEY_gmail: sk-…
  OPENCODE_GO_KEY_ACTIVE: gmail     # 面板高亮，切换时自动更新
records: {}
```

`keyNames` 写在 `cordis.patch.yml` 里随分支走；`settings.yaml` 里的 `llm-pi-ai` 路由由插件启动时自动生成，无需手工准备。

## 日常

```sh
# 装/删插件：dshmarket 或命令都行，改动直接进 git
pnpm dsh plugin --profile web add <package>
git add my-agent/profile && git commit -m "chore(my-agent): add <package>"
git push

# 启动（自动确保软链 + 按 lock 重新 install）
bash my-agent/dsh.sh web

# 切换 OpenCode Go 生效 key（等价于点用量卡片）
bash my-agent/use-key.sh qq
```

- **切分支 / pull 之后**：manifest 变了，跑一次 `setup.sh` 或直接用 `dsh.sh`（它每次都 `pnpm install`）。
- **拉取端**：`git pull` → `bash my-agent/dsh.sh web`，插件集与分支完全一致。

## 说明

- `dsh.sh` 第一个参数是 profile 名（默认 `web`），其余参数原样透传给 dsh。
- profile 在仓库里，Node 从插件向上解析到不了 `$DSH_HOME/profiles/node_modules`，所以 `setup.sh` 会在 `my-agent/node_modules` 建一个指向它的软链（被 gitignore，不入库）。
- GitHub 来源的插件都固定 commit，避免上游推送改变运行内容；装第三方插件会在安装时执行其代码，只装信任来源。
- `fixes/` 下是带快照的一次性修复脚本（例：`fixes/opencode-go-duplicate/`），apply 幂等、rollback 从快照恢复。
- `DSH_HOME` 默认 `~/.dsh`，可用同名环境变量覆盖；需要 `pnpm`（`corepack enable` 即可）。
