#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# bridge.sh — OpenSpec ↔ Superpowers 桥接
# ═══════════════════════════════════════════════════════════════
#
# 用法:
#   bridge install --tool-path <dir>
#   bridge new "<change-name>"
#   bridge status
#   bridge reset
#
# bridge run / bridge continue 由 AI 执行（见 bridge.md）。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$SCRIPT_DIR/state.yaml"
WORKFLOW_FILE="$SCRIPT_DIR/workflow.yaml"

die() { echo "ERROR: $*" >&2; exit 1; }

# ── 检测 openspec init 后哪个 agent 目录被创建了 openspec-* skills ──
detect_agent_skills_dir() {
    local target="$1"
    local found=""
    # 遍历项目中所有可能的 agent 目录，找刚被 openspec init 创建的 skills
    for agent_dir in "$target"/.*/skills; do
        [ -d "$agent_dir" ] || continue
        if ls "$agent_dir"/openspec-* >/dev/null 2>&1; then
            found="${agent_dir#$target/}"
            break
        fi
    done
    echo "$found"
}

# ── 安装 / 更新 openspec ──
ensure_openspec() {
    # 已全局安装 → 直接用
    if command -v openspec &>/dev/null; then
        echo "  [OK] openspec 已安装 ($(openspec --version 2>&1 | head -1))"
        return 0
    fi

    # 检查 node
    if ! command -v node &>/dev/null; then
        die "需要 Node.js (>=20.19.0)。请先安装: https://nodejs.org"
    fi
    if ! command -v npm &>/dev/null; then
        die "npm 不可用"
    fi

    echo "  >>> npm install -g @fission-ai/openspec"
    npm install -g @fission-ai/openspec 2>&1

    if ! command -v openspec &>/dev/null; then
        die "安装后仍找不到 openspec 命令。检查 npm 全局 bin 是否在 PATH 中。"
    fi
    echo "  [OK] openspec 安装成功 ($(openspec --version 2>&1 | head -1))"
}

cmd_install() {
    local tool_path=""
    local target="."

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tool-path) tool_path="$2"; shift 2 ;;
            *)           target="$1"; shift ;;
        esac
    done

    target="$(cd "$target" 2>/dev/null && pwd || echo "$target")"
    [ -d "$target" ] || die "目标目录不存在: $target"

    # ── tool_path 自动发现 ──
    if [ -z "$tool_path" ]; then
        local search="$SCRIPT_DIR"
        for _ in 1 2 3; do search="$(dirname "$search")"; done
        if [ -d "$search/OpenSpec-main" ] && [ -d "$search/superpowers-main" ]; then
            tool_path="$search"
        fi
    fi
    [ -n "$tool_path" ] || die "无法自动发现。请指定: bridge install --tool-path <path>"
    [ -d "$tool_path/superpowers-main/skills" ] || die "superpowers-main/skills 未找到: $tool_path"

    local sup_skills_src="$tool_path/superpowers-main/skills"

    # ── 路线图 ──
    echo ""
    echo "  OpenSpec <-> Superpowers Bridge"
    echo "  目标: ${target}"
    echo ""
    echo "  1/5  openspec init（交互选择 agent）"
    echo "  2/5  删除 config.yaml"
    echo "  3/5  Superpowers 全部 skills -> 跟随 agent"
    echo "  4/5  openspec-superpowers-bridge/"
    echo "  5/5  AGENTS.md + README.md"
    echo ""
    echo "  -------------------------------------"
    echo ""

    # ── 1/5: 安装 openspec + openspec init（交互选 agent）──
    ensure_openspec
    echo ""
    echo "  >>> openspec init $target"
    cd "$target" && openspec init .
    echo ""
    echo "  [OK] 1/5 OpenSpec 初始化完成"

    # ── 2/5: 删除 config.yaml ──
    local config_yaml="$target/openspec/config.yaml"
    local config_yml="$target/openspec/config.yml"
    if [ -f "$config_yaml" ]; then
        rm "$config_yaml"
        echo "  [OK] 2/5 config.yaml -- 已删除"
    elif [ -f "$config_yml" ]; then
        rm "$config_yml"
        echo "  [OK] 2/5 config.yml -- 已删除"
    else
        echo "  [OK] 2/5 config.yaml -- 未生成，跳过"
    fi

    # ── 3/5: Superpowers 全部 skills → 跟随 openspec init 选的 agent ──
    local agent_skills_dir
    agent_skills_dir="$(detect_agent_skills_dir "$target")"

    if [ -z "$agent_skills_dir" ]; then
        echo "  [WARN] 3/5 Superpowers -- 未检测到 openspec agent 目录，跳过"
    else
        local copied=0
        local skipped=0
        local skill_name
        local dest
        for skill_src in "$sup_skills_src"/*/; do
            [ -d "$skill_src" ] || continue
            skill_name="$(basename "$skill_src")"
            [ -f "$skill_src/SKILL.md" ] || continue
            dest="$target/$agent_skills_dir/$skill_name"
            if [ -d "$dest" ]; then
                ((skipped++)) || true
                continue
            fi
            cp -r "$skill_src" "$dest"
            ((copied++)) || true
        done
        echo "  [OK] 3/5 Superpowers -> ${agent_skills_dir} (${copied} copied, ${skipped} skipped)"
    fi

    # ── 4/5: openspec-superpowers-bridge/ ──
    local bridge_dir="$target/openspec-superpowers-bridge"
    mkdir -p "$bridge_dir"
    for f in workflow.yaml bridge.md bridge.sh; do
        [ -f "$SCRIPT_DIR/$f" ] && cp "$SCRIPT_DIR/$f" "$bridge_dir/$f"
    done
    # 复制 README.md（如果 bridge 源目录有）
    [ -f "$SCRIPT_DIR/README.md" ] && cp "$SCRIPT_DIR/README.md" "$bridge_dir/README.md"
    echo "  [OK] 4/5 openspec-superpowers-bridge/"

    # ── 5/5: AGENTS.md + README.md ──
    [ -f "$SCRIPT_DIR/AGENTS.md" ] && cp "$SCRIPT_DIR/AGENTS.md" "$target/AGENTS.md"
    [ -f "$SCRIPT_DIR/README.md" ] && cp "$SCRIPT_DIR/README.md" "$target/README.md"
    echo "  [OK] 5/5 AGENTS.md + README.md"

    # ── .gitignore ──
    if [ -f "$target/.gitignore" ]; then
        grep -q "openspec-superpowers-bridge/state.yaml" "$target/.gitignore" 2>/dev/null || \
            echo "openspec-superpowers-bridge/state.yaml" >> "$target/.gitignore"
    else
        echo "openspec-superpowers-bridge/state.yaml" > "$target/.gitignore"
    fi

    echo ""
    echo "  -------------------------------------"
    echo "  [OK] 安装完成"
    echo "  -------------------------------------"
    echo ""
    echo "  下一步: bridge new \"描述\" -> bridge run \"描述\""
    echo ""
}

cmd_new() {
    local change_name="$1"
    [ -z "$change_name" ] && die "用法: bridge new \"变更描述\""
    echo "  [OK] bridge new -> ${change_name}"
    echo "  告诉 AI: bridge new \"${change_name}\"（Phase 0：brainstorming -> config.yaml）"
}

cmd_status() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "无进行中的变更。bridge new \"描述\" 开始。"
        return
    fi
    echo ""
echo "=== Bridge 状态 ==="
echo ""
    grep -E "change_name|current_phase|total|completed|current|checkpoint" "$STATE_FILE" | sed 's/^/  /'
    echo ""
}

cmd_reset() {
    if [ -f "$STATE_FILE" ]; then
        rm "$STATE_FILE"
        echo "  [OK] state.yaml 已清除"
    else
        echo "无状态可清除"
    fi
}

case "${1:-}" in
    install) shift; cmd_install "$@" ;;
    new)     cmd_new "${2:-}" ;;
    status|st) cmd_status ;;
    reset)   cmd_reset ;;
    *)
        echo "用法: bridge {install|new|status|reset} [选项]"
        echo ""
        echo "  install     安装 OpenSpec + Superpowers + Bridge"
        echo "    --tool-path <dir>   工具根目录"
        echo ""
        echo "  new \"描述\"   创建新变更"
        echo "  status       查看进度"
        echo "  reset        清除状态"
        echo ""
        echo "  run/continue 由 AI 执行（见 bridge.md）"
        exit 1
        ;;
esac
