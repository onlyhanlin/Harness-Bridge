# Bridge 执行引擎 — AI 指令

> **这份文件是给你（AI 助手）读的。**
> 用户通过简单的命令触发，你按照此文件中的流程执行。

---

## 用户命令

| 用户说 | 你做什么 |
|--------|---------|
| `bridge new "<需求简述>"` | Phase 0：brainstorming 讨论 → 生成 config.yaml（不生成 state.yaml） |
| `bridge run` | Phase 1 开始：从 state.yaml 读取 change_name → brainstorming 需求讨论 → 生成设计文档 |
| `bridge continue` | 读取 `state.yaml`，从上次中断处继续 |
| `bridge status` | 打印当前进度 |
| `bridge reset` | 清除 `state.yaml`，重新开始 |

---

## 核心规则

### Iron Law
```
NO PHASE SKIPPED. NO CHECKPOINT IGNORED. STATE ALWAYS SYNCED.
```

### 状态文件

`state.yaml` 是你的外部记忆。中断后恢复全靠它。

**每次完成一个 task 或 phase 后，立刻更新 `state.yaml`。**
不更新 = 中断后丢失进度。

---

## Phase 执行流程

你按 `workflow.yaml` 中的 `phases` 顺序执行。每个 phase 执行完毕后：
1. 验证 `completion` 条件
2. 通过 `gates`（如有）
3. 更新 `state.yaml`
4. 进入下一个 phase

> `bridge new "<需求简述>"` 从 Phase 0 开始，输入名称后讨论配置并生成 state.yaml。
> `bridge run` 从 Phase 1 开始（从 state.yaml 读取 change_name），`bridge continue` 从 state.yaml 的 current_phase 继续。

### Phase 0: new — brainstorming 引导 → 生成 config.yaml

`bridge new "<需求简述>"` 触发。**Phase 0 只做一件事：讨论并生成 config.yaml。不生成 state.yaml，不涉及代码。**

**核心原则：AI 主动引导 brainstorming 讨论，讨论结束后将结论写入 config.yaml。**

#### 步骤 0：确认变更名称 + 判断场景

```
1. 确认 change_name = 用户输入的 "<需求简述>"
2. 检查 openspec/config.yaml 是否已存在:

   ┌─ 场景 A：config.yaml 不存在（首次 bridge new）──
   │   → 进入步骤 1-A：完整头脑风暴，从零讨论所有配置
   │
   └─ 场景 B：config.yaml 已存在（再次 bridge new）──
       → 先展示当前 config.yaml 完整内容给用户
       → 询问：「本次变更 "<需求简述>" 需要对 config.yaml 做针对性修改吗？」
       → 用户说不需要 → 跳过步骤 1，直接进入步骤 2（沿用现有 config.yaml）
       → 用户说要改 → 进入步骤 1-B：针对性修改讨论
```

#### 步骤 1-A：首次配置 — 完整头脑风暴（场景 A）

config.yaml 不存在时执行。调用 brainstorming 从头讨论全部配置。

```
调用 use_skill "brainstorming"，参数:
  - 需求简述: {change_name}
  - 当前项目目录结构
  - 无现有 config.yaml
```

**逐段讨论，覆盖以下全部主题。只管讨论，不写文件。**

---

**A. 项目上下文（Context）**

| 子项 | 引导问题 |
|------|---------|
| 技术栈 | 用什么语言？什么编译器/解释器？什么构建系统？ |
| 目标平台 | Linux / Windows / macOS / Web？ |
| 测试 | 用什么测试框架？单元测试命令是什么？ |
| 约定 | 代码注释用什么语言？README 用什么语言？命名规范？ |
| 领域 | 项目类型？（MCP 服务器 / REST API / CLI 工具 / 嵌入式…）协议或规范约束？ |

---

**B. 生成规则（Rules）**

| 子项 | 引导问题 |
|------|---------|
| proposal | proposal.md 有什么特殊要求？格式约束？ |
| specs | specs 需要遵循什么规范或模板？ |
| design | design.md 有什么约束？需要包含架构图或数据流吗？ |
| tasks | 任务拆分规则？（如「每个 task ≤ 30 分钟」「TDD 强制」「集成测试 task 必排」） |

---

**C. 执行配置（Execution）**

| 子项 | 引导问题 |
|------|---------|
| workspace | 需要 git worktree 隔离吗？基线测试命令是什么？ |
| tdd | 单元测试命令？构建命令？ |
| checkpoints | 每个 task 后需要跑哪些检查？失败时阻塞还是警告？ |
| pre steps | 执行前需要运行什么？ |
| post steps | 执行后需要运行什么？ |
| pre_archive | 归档前需要运行什么？ |

---

#### 步骤 1-B：针对性修改 — 头脑风暴聚焦讨论（场景 B）

config.yaml 已存在且用户确认需要修改时执行。

```
1. 展示当前 config.yaml 完整内容
2. 询问：「本次变更 "<需求简述>" 需要对 config.yaml 做针对性修改吗？」
   → 用户说不需要 → 跳过步骤 1-B，沿用现有 config.yaml，直接进入步骤 2
   → 用户说要改   → 继续下面
3. 调用 use_skill "brainstorming"，参数:
     - 需求简述: {change_name}
     - 本次变更的特殊需求
     - 当前 config.yaml 完整内容
4. 头脑风暴聚焦讨论（只讨论变化部分）：
     - 本次变更需要新增哪些检查点？
     - 是否有新的构建/测试命令？
     - rules 是否需要调整？
     - context 是否需要补充新领域知识？
5. 讨论结论记录为「差异变更」，只更新变化的部分，其余保留不变
```

**原则：只讨论变化的部分。不改的段直接保留，不重复讨论。**

---

#### 步骤 2：根据头脑风暴结论，写入 config.yaml

```
1. 头脑风暴全部完成后，将讨论结论总结为 config.yaml
2. 写入 openspec/config.yaml，参考格式:
```

```yaml
schema: spec-driven

context: |
  # 项目上下文 — 根据头脑风暴结论填写
  语言: ...
  编译器: ...
  ...

rules:
  proposal: []
  specs: []
  design: []
  tasks: []

execution:
  workspace:
    require: true
    baseline_test: ""
  tdd:
    enabled: true
    unit_command: ""
    build_command: ""
  checkpoints: []
  steps:
    pre: []
    post: []
    pre_archive: []
```

#### 步骤 3：展示完整 config.yaml，获得最终确认

```
1. 将写入后的 openspec/config.yaml 完整展示给用户
2. 明确询问：「以上是根据头脑风暴生成的 config.yaml，确认无误？需要调整？」
3. 用户确认 → 进入步骤 4
4. 用户要调整 → 回到对应主题重新讨论，然后更新 config.yaml
```

#### 步骤 4：完成提示

```
config.yaml 已配置完毕。

下一步: 建议新开会话，输入 bridge run → Phase 1 开始（需求讨论 → brainstorming → 生成设计文档）。
新会话确保上下文干净，避免 Phase 0 的讨论占用 token 影响后续执行。
```

---

#### 禁止行为

- ❌ config.yaml 存在时不展示就直接问「要不要改」（必须先展示完整内容）
- ❌ config.yaml 存在时用户说「不改」还强行逐段重讨论
- ❌ 场景 B 下重新生成整个 config.yaml 而不是针对性修改
- ❌ 头脑风暴未完成就开始写 config.yaml
- ❌ 不调用 brainstorming skill 就自行提问

### Phase 1: propose — 需求讨论 + brainstorming + 生成设计文档

`bridge run` 或 `bridge continue` 从此 phase 开始。

```
1. 读 state.yaml → 获取 change_name

2. 提示用户进行需求讨论，说明当前变更的目标

3. use_skill "brainstorming" → 执行完整头脑风暴流程:
   - 探索项目上下文（读 config.yaml context 字段）
   - 逐问题澄清需求
   - 提出 2-3 种方案
   - 展示设计
   - 用户审批

4. 根据头脑风暴结论，更新 config.yaml（如 context 需要补充）

5. 读 openspec/config.yaml → 提取 schema, rules, context

6. 生成 OpenSpec 变更文件（设计文档）:
   openspec/changes/{change_name}/
   ├── proposal.md
   ├── specs/
   ├── design.md
   └── tasks.md

7. 展示生成结果给用户
8. 用户审批 → 更新 state.yaml (current_phase: worktree, completed_phases: [propose])
```

**如何生成变更文件：**

按照 OpenSpec config.yaml 中 `rules` 块的每个 artifact 规则生成文件。
如果 OpenSpec CLI 可用，调用 `openspec instructions <artifact> --change <name>` 获取指令。
否则，按照 `openspec/schemas/<schema>/schema.yaml` 中的 instruction + template 手动生成。

**state.yaml 更新：**
```yaml
current_phase: worktree
change_name: <name>
change_dir: openspec/changes/<name>/
completed_phases: [propose]
```

### Phase 2: worktree — 隔离工作空间

```
1. 调用 Superpowers skill: using-git-worktrees
2. 创建隔离的 git worktree
3. 运行基线测试（来自 config.yaml execution.workspace.baseline_test）
4. 测试通过 → 更新 state.yaml
```

**state.yaml 更新：**
```yaml
current_phase: execute
completed_phases: [propose, worktree]
worktree_path: <path>
```

### Phase 3: execute — TDD 执行循环（最核心）

**config.yaml 是 Phase 3 的唯一规则源。每个 task 必须严格遵守 config.yaml 中定义的所有约束。**

```
前置 — 读取规则:
  1. 读 openspec/config.yaml:
     a) execution 块 → tdd 命令、检查点、steps
     b) rules.tasks → 任务拆分规则（如时间限制、TDD 强制等）
     c) context → 技术栈信息
  2. 读 openspec/changes/{change_name}/tasks.md → 提取所有 checkbox
  3. 构建检查点注册表（从 execution.checkpoints）
  4. 运行 execution.steps.pre 中的命令
  5. 调用 use_skill "test-driven-development"，将 config.yaml 的 rules.tasks 和 execution.tdd 作为参数传入

循环（对每个未勾选的 task）:
  ┌─ RED:   写失败测试
  │         ─ 严格遵守 rules.tasks 规定的 TDD 流程
  │         ─ 运行 {execution.tdd.unit_command} → 必须确认 FAIL
  │
  ├─ GREEN: 最少实现代码
  │         ─ 只写让测试通过的最少代码
  │         ─ 运行 {execution.tdd.unit_command} → 必须确认 PASS
  │
  ├─ BUILD: 运行 {execution.tdd.build_command}（如配置）
  │
  ├─ REFACTOR: 清理代码，重跑测试确保仍然 PASS
  │
  ├─ [检查点 — 强制，不可跳过]
  │   遍历 execution.checkpoints:
  │   ─ trigger: after_each_task → 每个 task 后运行
  │   ─ trigger: on_file_pattern  → 匹配文件模式时运行
  │   ─ trigger: after_batch      → 累积 N 个 task 后运行
  │   ─ on_failure: block → 立即停止，等待用户介入
  │   ─ on_failure: warn  → 记录警告，继续执行
  │
  ├─ checkoff: 在 tasks.md 中将此 task 勾选为 - [x]
  │
  └─ 更新 state.yaml.task_progress + checkpoint_results
```

**检查点注册表构建：**

从 `execution.checkpoints` 构建三类触发器：
```
after_each:     [检查点列表]        ← 每个 task 后强制执行
file_pattern:   [{pattern, command, on_failure}, ...]  ← 匹配文件时触发
after_batch:    [{batch_size, command, on_failure, counter}, ...]  ← 每 N 个 task
```

**关键强制规则：**
- ❌ 禁止跳过检查点（哪怕全部通过也要跑）
- ❌ 禁止先写实现再补测试（config.yaml rules.tasks 说了 TDD 就是 TDD）
- ❌ 禁止修改 tasks.md 的 checkbox 而不更新 state.yaml
- ✅ 每个 task 必须经历完整的 RED → GREEN → BUILD → REFACTOR → CHECKPOINT 循环

**state.yaml 更新（每个 task 完成后）：**
```yaml
task_progress:
  total: 8
  completed: [1.1, 1.2]
  current: 1.3
checkpoint_results:
  build: pass
  unit: pass
last_git_sha: <HEAD SHA>
```

### Phase 4: verify — 全量验证

**config.yaml 决定验证范围。所有检查点必须通过，所有测试必须绿色。**

```
1. 读 openspec/config.yaml → execution 块（steps、checkpoints、tdd）
2. 运行 execution.steps.pre_archive 中的命令（如配置）
3. 运行 execution.tdd.unit_command → 全量单元测试，必须全部 PASS
4. 运行 execution.tdd.build_command → 全量构建，必须成功
5. 遍历 execution.checkpoints 中所有检查点，逐一运行:
   ─ 任何 block 检查点失败 → 停止，修复后重跑 Phase 4
   ─ 任何 warn 检查点失败 → 记录，继续
6. 运行 execution.steps.post 中的命令（如配置）
7. 调用 use_skill "verification-before-completion" → 最终确认
8. 全部通过 → 更新 state.yaml (current_phase: archive, completed_phases: [..., verify])
```

**强制规则：**
- ❌ 禁止跳过任何检查点
- ❌ 禁止「这个检查点之前通过了可以跳过」
- ✅ 全量 = 全量，不是增量测试

### Phase 5: archive — 归档

```
1. 执行 /opsx:archive {change_name}
2. 变更合并到 openspec/specs/，移动到 archive/
3. 展示归档后选项（合并/PR/保留）
4. 根据用户选择调用 finishing-a-development-branch skill
```

---

## 中断恢复流程

用户说 `bridge continue` 时：

```
1. 读 state.yaml
2. 如果 state.yaml 不存在或损坏:
   → 报错：没有可恢复的状态。请用 bridge run 开始新流程。

3. 读 current_phase:
   → 跳转到对应 phase

4. 如果是 execute phase:
   → 读 task_progress，跳过 completed 中的 task
   → 从 current task 继续 TDD 循环
   → 检查 last_git_sha — 如果 HEAD 已变，说明有未提交的变更
   → 检查 checkpoint_results — 跳过已通过的检查点

5. 如果是其他 phase:
   → 重新执行该 phase（phase 级别的检查天然幂等）
```

**state.yaml 损坏时的恢复：**

如果 state.yaml 不可读，尝试自动重建：
```bash
# 1. 找到最近修改的 openspec/changes/ 目录
ls -t openspec/changes/ | head -1

# 2. 检查 tasks.md 中哪些已勾选
grep -c '\[x\]' openspec/changes/<name>/tasks.md

# 3. 用 bridge status 展示推断的状态，让用户确认
```

---

## 检查点失败处理

| on_failure | 行为 |
|-----------|------|
| `block` | **立即停止**。报告失败的命令 + 输出。等待用户介入。更新 state.yaml 记录失败。 |
| `warn` | **记录警告，继续执行**。在最终报告中汇总所有警告。 |

---

## 配置引用语法

workflow.yaml 中 `{config:execution.tdd.unit_command}` 表示：
→ 从 `openspec/config.yaml` 的 `execution.tdd.unit_command` 取值

`{change_name}` 表示：
→ 当前变更名称（由用户提供或从 state.yaml 读取）

---

## 快速参考：state.yaml 完整结构

```yaml
bridge_version: 1
change_name: virtio-blk-dma
change_dir: openspec/changes/virtio-blk-dma/
current_phase: execute
completed_phases: [propose, worktree]
worktree_path: /path/to/worktree
task_progress:
  total: 8
  completed: [1.1, 1.2]
  current: 1.3
checkpoint_results:
  build: pass
  unit: pass
  qtest: warn
batch_counters:
  after_batch: 2
last_git_sha: abc1234
started_at: 2026-06-05T10:00:00Z
```
