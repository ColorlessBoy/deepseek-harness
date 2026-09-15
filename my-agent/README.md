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
    pnpm-lock.yaml             # 精确锁定，含 github 依赖的 integrity
    pnpm-workspace.yaml        # hoisted 链接器 + autoInstallPeers: false
    cordis.yml                 # profile 根（空 entry 列表）
    cordis.patch.yml           # 用户 patch 层（装机行写在这里）
    plugins/                   # profile 本地插件（file: 依赖）
      dsh-opencode-go-live/
    node_modules/              # 被根 .gitignore 忽略
  node_modules -> $DSH_HOME/profiles/node_modules   # dsh 依赖回退，setup.sh 建
  setup.sh                     # 建软链 + pnpm install
  dsh.sh                       # setup + 启动 dsh（日常入口）
```

## 已记录的插件

| 包 | 版本/来源 | 作用 |
|---|---|---|
| `dshmarket` | `^1.46.1` | 插件市场（Settings 内一键装/升级） |
| `dsh-find-plugin` | `^0.3.7` | 会话内搜索插件 |
| `dsh-profile-plugin-switch` | `github:cynch18/plugin-switch#3f13f7a7e1c995f38e80f1af8c206ff7bb749329` | GUI 实时开关任意插件 |
| `dsh-opencode-go-live` | 本地 `profile/plugins/`（`file:` 依赖） | 实时同步 OpenCode Go 模型列表，按官方协议拆到 `llm-pi-ai` 三条 route |

完整候选清单见仓库根目录 [MY-AGENT-PLUGINS.md](../MY-AGENT-PLUGINS.md)。

## 另一台电脑

```sh
git clone <this-repo> && cd deepseek-harness
git checkout <branch>
pnpm install && pnpm run build          # 构建 dsh 本体
bash my-agent/setup.sh                  # 建软链 + 按 lockfile 装插件
pnpm dsh web
```

`setup.sh` 只做两件事：把 `$DSH_HOME/profiles/<name>` 软链到 `my-agent/profile`，然后在该目录 `pnpm install`。插件版本一致的原因全在提交进分支的 `pnpm-lock.yaml` + 固定 commit 的 GitHub 依赖 + 分支内的本地插件源码。

若目标机已有同名 profile 真目录，`setup.sh` 会报错让你先移走，不会覆盖。

## 日常

```sh
# 装/删插件：dshmarket 或命令都行，改动直接进 git
pnpm dsh plugin --profile web add <package>
git add my-agent/profile && git commit -m "chore(my-agent): add <package>"
git push

# 启动（自动确保软链 + 按 lock 重新 install）
bash my-agent/dsh.sh web
```

- **切分支 / pull 之后**：manifest 变了，跑一次 `setup.sh` 或直接用 `dsh.sh`（它每次都 `pnpm install`）。
- **拉取端**：`git pull` → `bash my-agent/dsh.sh web`，插件集与分支完全一致。

## 说明

- `dsh.sh` 第一个参数是 profile 名（默认 `web`），其余参数原样透传给 dsh。
- `settings.yaml`、`.credentials.yaml` 在 `$DSH_HOME/` 下，**不在**仓库里，密钥不会进 git。
- profile 在仓库里，Node 从插件向上解析到不了 `$DSH_HOME/profiles/node_modules`，所以 `setup.sh` 会在 `my-agent/node_modules` 建一个指向它的软链（`node_modules` 被 gitignore，不入库）。
- GitHub 来源的插件已固定 commit（如 `plugin-switch`），避免上游推送改变运行内容。
- 装第三方插件会在安装时执行其代码；只装信任来源。
- `DSH_HOME` 默认 `~/.dsh`，可用同名环境变量覆盖；需要 `pnpm`（`corepack enable` 即可）。
