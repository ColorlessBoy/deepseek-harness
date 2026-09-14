# my-agent — 可同步的 dsh profile

这个目录把 `web` profile 的插件组合**记录进 git**，换电脑时一条命令即可还原同样的 agent。

dsh 的 profile 本体在 `$DSH_HOME/profiles/<name>`（仓库外），git 天然不跟踪。这里保存它的**种子**：固定版本的清单 + lockfile + 用户 patch 层，配合脚本做双向同步。

## 目录

```
my-agent/
  profile/
    package.json         # 插件依赖（版本/commit 已固定）+ dsh.profile.bundles
    pnpm-lock.yaml       # 精确锁定，含 github 依赖的 integrity
    pnpm-workspace.yaml  # hoisted 链接器 + autoInstallPeers: false
    cordis.yml           # profile 根（空 entry 列表）
    cordis.patch.yml     # 你自己的 patch 层（覆盖 bundle 用）
  setup.sh               # 仓库 -> 本机：还原并安装
  capture.sh             # 本机 -> 仓库：把新装的插件记录回来
```

## 已记录的插件

| 包 | 版本/来源 | 作用 |
|---|---|---|
| `dshmarket` | `^1.46.1` | 插件市场（Settings 内一键装/升级） |
| `dsh-find-plugin` | `^0.3.7` | 会话内搜索插件 |
| `dsh-profile-plugin-switch` | `github:cynch18/plugin-switch#3f13f7a7e1c995f38e80f1af8c206ff7bb749329` | GUI 实时开关任意插件 |

完整候选清单见仓库根目录 [MY-AGENT-PLUGINS.md](../MY-AGENT-PLUGINS.md)。

## 新电脑同步

```sh
git clone <this-repo> && cd deepseek-harness
pnpm install && pnpm run build      # 构建 dsh 本体
pnpm exec bash my-agent/setup.sh    # 还原 web profile 并安装插件
pnpm dsh web
```

`setup.sh` 会把种子拷进 `$DSH_HOME/profiles/web` 并跑 `pnpm install`。若目标机已有自己的 `cordis.patch.yml`，默认保留；加 `--force` 覆盖。

> 装 GitHub 来源的插件会在安装时执行该仓库的代码（本清单里 `plugin-switch` 无 install 脚本，仅下载预构建的 `index.js`）。已把 commit 固定，避免上游后续推送改变运行内容。

## 本机新增插件后写回仓库

```sh
pnpm dsh plugin --profile web add <package>
bash my-agent/capture.sh              # 更新 my-agent/profile/*
git add my-agent/profile && git commit -m "chore(my-agent): add <package>"
```

## 说明

- `setup.sh` 只处理一个 profile；换名字用 `bash my-agent/setup.sh <profile-name>`。
- `DSH_HOME` 默认 `~/.dsh`，可用同名环境变量覆盖。
- 需要 `pnpm`（`corepack enable` 即可）；`dsh` 从本仓库源码运行用 `pnpm dsh ...`。
