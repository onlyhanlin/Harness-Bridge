# Harness-bridge

**OpenSpec ↔ Superpowers 桥接项目**

---

## 目录结构

```
Harness-bridge/
├── OpenSpec-main/                    # OpenSpec 核心项目
│   ├── bin/openspec.js              # CLI 入口
│   ├── dist/                        # 编译产物
│   ├── docs/                        # 文档
│   ├── openspec/                    # OpenSpec 规范和变更
│   │   ├── specs/                   # 规范定义
│   │   ├── changes/                 # 变更记录
│   │   └── initiatives/             # 计划
│   └── ...
├── superpowers-main/                 # Superpowers AI 技能框架
│   ├── skills/                      # AI 技能集合
│   │   ├── brainstorming/
│   │   ├── test-driven-development/
│   │   ├── systematic-debugging/
│   │   └── ...
│   └── ...
├── openspec-superpowers-bridge/      # 桥接工具
│   ├── bridge.sh                    # 安装和辅助命令
│   ├── bridge.md                    # AI 执行手册
│   ├── workflow.yaml                # 流程定义
│   ├── state.yaml                   # 进度状态（运行时生成）
│   └── AGENTS.md                    # AI 恢复指令
└── AGENTS.md                        # 顶层恢复入口
```

---

## 快速开始

### 安装到项目

```bash
bash openspec-superpowers-bridge/bridge.sh install --tool-path /path/to/tools
```

### 使用流程

```bash
# 头脑风暴 → 生成 config.yaml
bridge new "需求名称描述"

# 开始执行（propose → worktree → execute → verify → archive）
bridge run "需求名称描述"

# 中断后恢复
bridge continue

# 查看进度
bridge status
```

---

## 核心概念

| 概念 | 说明 |
|------|------|
| **OpenSpec** | 规范驱动的变更管理框架 |
| **Superpowers** | AI 代理技能集合（brainstorming、TDD、调试等） |
| **Bridge** | 连接两者的执行引擎，支持断点恢复 |

### 执行阶段

```
Phase 0: new      → 头脑风暴 + config.yaml
Phase 1: propose  → 提案/规格/设计/任务
Phase 2: worktree → Git worktree 隔离
Phase 3: execute  → TDD 执行
Phase 4: verify   → 全量验证
Phase 5: archive  → 归档
```

---

## 关键文件

| 文件 | 用途 |
|------|------|
| `openspec-superpowers-bridge/bridge.md` | AI 执行手册 |
| `openspec-superpowers-bridge/state.yaml` | 断点恢复状态 |
| `openspec/config.yaml` | 项目配置（你只需要编辑这个） |
| `openspec/changes/<name>/tasks.md` | 任务清单 |
