#!/usr/bin/env bash
# install.sh — Installs the inspector agent, skill, and hooks.
#
# Usage:
#   ./install.sh             # install
#   ./install.sh --uninstall # remove
#
# Safe to run multiple times (idempotent).
#
# Prerequisites: jq (for --claude-code settings.json wiring)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="${HOME}/.claude/agents"
HOOKS_DIR="${HOME}/.claude/agents/hooks"
SKILLS_DIR="${HOME}/.claude/skills/inspector"

do_install() {
  echo "Installing inspector agent..."
  echo ""

  # 1. Agent definition
  echo "1. Linking agent definition..."
  mkdir -p "${AGENTS_DIR}"
  ln -sf "${REPO_DIR}/inspector.md" "${AGENTS_DIR}/inspector.md"
  echo "   ${AGENTS_DIR}/inspector.md -> ${REPO_DIR}/inspector.md"
  echo ""

  # 2. Hook scripts
  echo "2. Linking hook scripts..."
  mkdir -p "${HOOKS_DIR}"
  ln -sf "${REPO_DIR}/hooks/inspector-lsp-gate.sh" "${HOOKS_DIR}/inspector-lsp-gate.sh"
  ln -sf "${REPO_DIR}/hooks/inspector-lsp-set.sh"  "${HOOKS_DIR}/inspector-lsp-set.sh"
  chmod +x "${REPO_DIR}/hooks/inspector-lsp-gate.sh" "${REPO_DIR}/hooks/inspector-lsp-set.sh"
  echo "   ${HOOKS_DIR}/inspector-lsp-gate.sh"
  echo "   ${HOOKS_DIR}/inspector-lsp-set.sh"
  echo ""

  # 3. Skill files
  echo "3. Linking skill files..."
  mkdir -p "${SKILLS_DIR}"
  ln -sf "${REPO_DIR}/inspector/SKILL.md" "${SKILLS_DIR}/SKILL.md"
  echo "   ${SKILLS_DIR}/SKILL.md"
  echo ""

  # 4. Verify
  echo "4. Verifying..."
  local errors=0
  for f in "${AGENTS_DIR}/inspector.md" "${HOOKS_DIR}/inspector-lsp-gate.sh" "${HOOKS_DIR}/inspector-lsp-set.sh" "${SKILLS_DIR}/SKILL.md"; do
    if [ -L "$f" ] && [ -e "$f" ]; then
      echo "   OK  $f"
    else
      echo "   FAIL  $f" >&2
      errors=$((errors + 1))
    fi
  done

  if [ "$errors" -gt 0 ]; then
    echo ""
    echo "Installation failed with ${errors} error(s)." >&2
    exit 1
  fi

  echo ""
  echo "Installation complete."
  echo ""
  echo "  Agent:  ~/.claude/agents/inspector.md"
  echo "  Hooks:  ~/.claude/agents/hooks/inspector-lsp-{gate,set}.sh"
  echo "  Skill:  ~/.claude/skills/inspector/SKILL.md  (/inspect)"
  echo ""
  echo "Hooks are wired in inspector.md frontmatter — no settings.json changes needed."
}

do_uninstall() {
  echo "Uninstalling inspector agent..."
  echo ""

  for f in "${AGENTS_DIR}/inspector.md" "${HOOKS_DIR}/inspector-lsp-gate.sh" "${HOOKS_DIR}/inspector-lsp-set.sh" "${SKILLS_DIR}/SKILL.md"; do
    if [ -L "$f" ]; then
      rm "$f"
      echo "  Removed $f"
    fi
  done

  [ -d "${SKILLS_DIR}" ] && rmdir --ignore-fail-on-non-empty "${SKILLS_DIR}" 2>/dev/null || true

  echo ""
  echo "Uninstall complete."
}

case "${1:-}" in
  --uninstall) do_uninstall ;;
  "")          do_install   ;;
  *) echo "Usage: install.sh [--uninstall]" >&2; exit 1 ;;
esac
