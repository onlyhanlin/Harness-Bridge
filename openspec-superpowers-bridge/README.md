# OpenSpec ↔ Superpowers Bridge

**一条命令安装，一条指令启动，中断后一条指令继续。**

---

## 安装

```bash
bash openspec-superpowers-bridge/bridge.sh install \
  --tool-path /path/to/tools
```

| 参数 | 必填 | 说明 |
|------|:---:|------|
| `--tool-path` | 是 | 包含 `OpenSpec-main/` 和 `superpowers-main/` 的目录 |

安装过程先打印路线图，然后 OpenSpec 交互选 agent，Superpowers 全部技能自动跟随。

```
  OpenSpec ↔ Superpowers Bridge
  目标: /path/to/project

  1/5  openspec init（交互选择 agent）
  2/5  删除 config.yaml
  3/5  Superpowers 全部 skills → 跟随 agent
  4/5  openspec-superpowers-bridge/
  5/5  AGENTS.md + README.md

  ─────────────────────────────────────

  （OpenSpec 交互界面 — 用户选 Cline/Claude/...）

  1/5 OpenSpec 初始化完成
  2/5 config.yaml — 已删除
  3/5 Superpowers → .cline/skills (14 skills)
  4/5 openspec-superpowers-bridge/
  5/5 AGENTS.md + README.md

  ─────────────────────────────────────
  安装完成
  ─────────────────────────────────────

   下一步: bridge new "描述" → bridge run "描述"
```

安装后结构：

```
项目/
├── AGENTS.md                     ← 防丢恢复
├── README.md                     ← 说明文档
├── .cline/skills/                 ← OpenSpec + Superpowers 全部 skill
│   ├── openspec-propose/SKILL.md
│   ├── openspec-apply/SKILL.md
│   ├── brainstorming/SKILL.md
│   ├── test-driven-development/SKILL.md
│   └── ...
├── openspec/
│   ├── specs/
│   └── changes/
└── openspec-superpowers-bridge/
```

---

## 使用

```bash
# 头脑风暴 → config.yaml → state.yaml（phase: prepare）
bridge new "add virtio-blk DMA check"

# 告诉 AI 开始（propose → worktree → execute → ...）
bridge run "add virtio-blk DMA check"

# 中断后恢复
bridge continue

# 查看进度
bridge status
```

---

## config.yaml

你只需要写这一个文件。`rules` 给 OpenSpec 生成文档，`execution` 给 Superpowers 控制执行。

AI 执行流程：

```
bridge new → bridge.md Phase 0 → 头脑风暴 → config.yaml → state.yaml (phase: prepare)

bridge run:
  Phase 0   new         头脑风暴 + 配置 + 初始化状态
  Phase 1   propose     生成提案/规格/设计/任务
  Phase 2   worktree    隔离工作空间
  Phase 3   execute     TDD 执行
  Phase 4   verify      全量验证
  Phase 5   archive     归档
```

`bridge new` 触发 bridge.md Phase 0，引导你填写 config.yaml 中的关键配置：

| 字段 | 作用 | 示例 |
|------|------|------|
| `context` | 项目技术栈、约定、领域知识 | `Go 1.21, PostgreSQL, gRPC` |
| `rules.tasks` | 任务拆分规则 | `每个 task ≤ 30 分钟` |
| `execution.tdd.unit_command` | 单元测试命令 | `go test ./...` |
| `execution.tdd.build_command` | 构建命令 | `go build ./...` |
| `execution.checkpoints` | 检查点，每个 task 后触发 | 构建检查、集成测试 |
| `execution.steps.pre` | 执行前命令 | 安装依赖 |
| `execution.steps.post` | 执行后命令 | 代码格式化 |

完整模板：

```yaml
schema: spec-driven

context: |
  # 项目上下文 — 技术栈、约定、领域知识

rules:
  proposal: []
  specs: []
  design: []
  tasks:
    - "每个 task ≤ 30 分钟"
    - "hw/ 变更必须安排集成测试 task"

execution:
  workspace:
    require: true
    baseline_test: ""
  tdd:
    enabled: true
    unit_command: ""
    build_command: ""
  checkpoints:
    - id: build
      trigger: after_each_task
      command: ""
      on_failure: block
  steps:
    pre: []
    post: []
    pre_archive: []
```

---

## 文件角色

| 文件 | 谁写 | 用途 |
|------|:---:|------|
| `openspec/config.yaml` | 你 / `bridge new`（bridge.md Phase 0）| 唯一配置源 |
| `bridge.md` | boilerplate | AI 执行手册 |
| `workflow.yaml` | boilerplate | 流程定义 |
| `bridge.sh` | boilerplate | 安装 + 辅助命令 |
| `state.yaml` | AI 自动生成 | 断点恢复 |
| `AGENTS.md` | boilerplate | 压缩恢复指令 |