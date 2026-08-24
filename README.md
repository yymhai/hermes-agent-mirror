# 🤖 hermes-agent 中转镜像仓库

> ⏰ **这是一个中转仓，不是代码本身。**
>
> 真实代码在 Gitee 镜像：👉 https://gitee.com/qianchilang/hermes-agent
>
> 上游原仓库：👉 https://github.com/NousResearch/hermes-agent

---

## 📌 这是什么？

这是一个**自动化中转仓库**，用途是把 [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) 的代码定时镜像到 Gitee，方便国内访问。

里面**只有**一个 GitHub Actions workflow 文件（`.github/workflows/sync-fork.yml`），每 6 小时自动跑一次同步任务。

```
NousResearch/hermes-agent  ──(定时/手动)──>  本仓 Actions  ──>  qianchilang/hermes-agent (Gitee)
                                       （中转站）
```

## 🚀 我想看代码，去哪儿？

### ✅ 推荐：直接看 Gitee 镜像

👉 https://gitee.com/qianchilang/hermes-agent

- 国内访问快、稳定
- 自动每 6 小时同步上游最新代码
- 支持完整 Git 操作（clone / push / PR / Issue 等）

```bash
git clone https://gitee.com/qianchilang/hermes-agent.git
```

### 想看上游原版？

👉 https://github.com/NousResearch/hermes-agent

官方仓库，问题、PR、Release 都在这里。

### 只想看本仓的同步配置？

直接看 [`.github/workflows/sync-fork.yml`](.github/workflows/sync-fork.yml) —— 整个 workflow 就这一个文件。

---

## ⚙️ 同步机制是怎么工作的？

| 项目 | 说明 |
|------|------|
| 同步源 | https://github.com/NousResearch/hermes-agent |
| 同步频率 | 每 6 小时（cron: `0 */6 * * *`） |
| 同步方式 | GitHub Actions 自动执行 |
| 同步内容 | 所有分支 + 所有 tag |
| 强制覆盖 | 是（与上游完全一致） |

工作流会：

1. 用 `actions/checkout@v4` 拉取上游**完整历史**（`fetch-depth: 0`）
2. 添加 Gitee 远端（凭据从 Secrets 读）
3. `git push --all --force` 推送所有分支
4. `git push --tags --force` 推送所有 tag
5. 清理 remote URL 里的 token

详细配置见 [`sync-fork.yml`](.github/workflows/sync-fork.yml)。

---

## ❓ 常见问题

### Q：这个仓和 Gitee 镜像代码一样吗？
A：**完全一样**。新内容延迟 **0~6 小时**到达 Gitee。

### Q：为什么需要这个"中转仓"？
A：因为 **GitHub Actions 是免费的**（public 仓库每月 2000 分钟额度），而 Gitee Go 等服务要么收费、要么不支持 GitHub Actions YAML。GitHub 跑 → 推 Gitee 是最省钱的方案。

### Q：为什么不直接 fork 上游仓到自己账户？
A：fork 关系会和上游双向同步（pull request 等），不适合做单向镜像。中转仓是一个**独立的空仓**，只跑 Actions。

### Q：同步停了/失败怎么办？
看 [Actions 页面](https://github.com/360PB/hermes-agent-mirror/actions)：
- ✅ 绿色 = 同步正常
- ❌ 红色 = 看 Run 日志，通常是 Secrets 过期或网络问题

### Q：我能修改这个仓的 workflow 吗？
A：技术上可以，但**不建议**——会破坏同步。改 workflow 等于改镜像规则。

### Q：怎么手动触发同步？
进 [Actions 页面](https://github.com/360PB/hermes-agent-mirror/actions) → 选 **Sync Upstream to Gitee** → 右侧 **Run workflow**。

---

## 🔐 安全说明

- 本仓**不包含**任何明文 token
- 所有凭据（`GITEE_USERNAME` / `GITEE_TOKEN`）都存在 GitHub Secrets，Actions 运行时解引用
- Push 后 workflow 立即清掉 remote URL 里的 token
- 凭据泄漏时请去 https://github.com/settings/tokens 撤销

---

## 📞 联系

| 类型 | 去处 |
|------|------|
| 上游项目问题 | https://github.com/NousResearch/hermes-agent/issues |
| 镜像同步问题 | 本仓 [Issues](https://github.com/360PB/hermes-agent-mirror/issues) |

---

<sub>🤖 本 README 由 [git-mirror-sync](https://github.com/360PB/InfiniteTalk-mirror) skill 生成 · 最后更新：2026-08-24</sub>