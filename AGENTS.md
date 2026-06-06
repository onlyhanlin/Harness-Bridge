## Bridge Resume

If you have lost context, the user may say **"bridge continue"**.

1. Read `openspec-superpowers-bridge/state.yaml`
2. Read `openspec-superpowers-bridge/bridge.md`
3. Read `openspec/config.yaml`
4. Jump to the `current_phase` from state.yaml and continue

If state.yaml doesn't exist → tell the user: "No bridge state. Start with: bridge new 'description'"

## Bridge Commands

| User says | Action |
|-----------|--------|
| `bridge install --tool-path <path>` | Install into project |
| `bridge new "<desc>"` | Read bridge.md → Phase 0: brainstorming → config.yaml only |
| `bridge run "<desc>"` | Read bridge.md → Phase 1: brainstorm → generate files → ... |
| `bridge continue` | Resume from state.yaml |
| `bridge status` | Show progress from state.yaml |

## Pipeline Phases

```
Phase 0: new      → Brainstorming → config.yaml
Phase 1: propose  → Brainstorm + generate proposal / specs / design / tasks
Phase 2: worktree → Git worktree isolation
Phase 3: execute  → TDD per task + checkpoints
Phase 4: verify   → Full test suite
Phase 5: archive  → OpenSpec archive
```

After EVERY task in Phase 3:
1. Verify against `openspec/changes/<name>/tasks.md`
2. Mark complete: `- [ ]` → `- [x]` in tasks.md
3. Update `openspec-superpowers-bridge/state.yaml`

This is the only way to survive context loss.

## Files

```
openspec-superpowers-bridge/bridge.md    ← Full instructions
openspec-superpowers-bridge/state.yaml   ← Progress
openspec/config.yaml                     ← Rules + execution
openspec/changes/<name>/tasks.md         ← Task list
<agent-skills-dir>/                      ← All skills
```
