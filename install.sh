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
SKILLS_DIR="${HOME}/.claude/skills/inspect"

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
  ln -sf "${REPO_DIR}/hooks/inspector-subagent-start.sh" "${HOOKS_DIR}/inspector-subagent-start.sh"
  ln -sf "${REPO_DIR}/hooks/inspector-lsp-gate.sh"       "${HOOKS_DIR}/inspector-lsp-gate.sh"
  ln -sf "${REPO_DIR}/hooks/inspector-lsp-set.sh"        "${HOOKS_DIR}/inspector-lsp-set.sh"
  ln -sf "${REPO_DIR}/hooks/inspector-lsp-fallback.sh"   "${HOOKS_DIR}/inspector-lsp-fallback.sh"
  chmod +x "${REPO_DIR}/hooks/inspector-subagent-start.sh" "${REPO_DIR}/hooks/inspector-lsp-gate.sh" "${REPO_DIR}/hooks/inspector-lsp-set.sh" "${REPO_DIR}/hooks/inspector-lsp-fallback.sh"
  echo "   ${HOOKS_DIR}/inspector-subagent-start.sh"
  echo "   ${HOOKS_DIR}/inspector-lsp-gate.sh"
  echo "   ${HOOKS_DIR}/inspector-lsp-set.sh"
  echo "   ${HOOKS_DIR}/inspector-lsp-fallback.sh"
  echo ""

  # 3. Skill files
  echo "3. Linking skill files..."
  mkdir -p "${SKILLS_DIR}"
  ln -sf "${REPO_DIR}/inspect/SKILL.md" "${SKILLS_DIR}/SKILL.md"
  # Remove existing entries (symlink or real dir) before re-linking — ensures idempotency
  for d in assets scripts references; do
    rm -rf "${SKILLS_DIR:?}/${d}"
    ln -s "${REPO_DIR}/inspect/${d}" "${SKILLS_DIR}/${d}"
  done
  chmod +x "${REPO_DIR}/inspect/scripts/validate-report"
  echo "   ${SKILLS_DIR}/SKILL.md"
  echo "   ${SKILLS_DIR}/assets -> ${REPO_DIR}/inspect/assets"
  echo "   ${SKILLS_DIR}/scripts -> ${REPO_DIR}/inspect/scripts"
  echo "   ${SKILLS_DIR}/references -> ${REPO_DIR}/inspect/references"
  echo ""

  # 4. Verify
  echo "4. Verifying..."
  local errors=0
  for f in "${AGENTS_DIR}/inspector.md" "${HOOKS_DIR}/inspector-subagent-start.sh" "${HOOKS_DIR}/inspector-lsp-gate.sh" "${HOOKS_DIR}/inspector-lsp-set.sh" "${HOOKS_DIR}/inspector-lsp-fallback.sh" "${SKILLS_DIR}/SKILL.md" "${SKILLS_DIR}/assets" "${SKILLS_DIR}/scripts" "${SKILLS_DIR}/references"; do
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
  echo "  Skill:  ~/.claude/skills/inspect/  (/inspect)"
  echo ""
  echo "Hooks are wired in inspector.md frontmatter — no settings.json changes needed."
}

do_uninstall() {
  echo "Uninstalling inspector agent..."
  echo ""

  for f in "${AGENTS_DIR}/inspector.md" "${HOOKS_DIR}/inspector-subagent-start.sh" "${HOOKS_DIR}/inspector-lsp-gate.sh" "${HOOKS_DIR}/inspector-lsp-set.sh" "${HOOKS_DIR}/inspector-lsp-fallback.sh" "${SKILLS_DIR}/SKILL.md" "${SKILLS_DIR}/assets" "${SKILLS_DIR}/scripts" "${SKILLS_DIR}/references"; do
    if [ -L "$f" ]; then
      rm "$f"
      echo "  Removed $f"
    fi
  done

  [ -d "${SKILLS_DIR}/references" ] && rmdir "${SKILLS_DIR}/references" 2>/dev/null || true
  [ -d "${SKILLS_DIR}/scripts" ]    && rmdir "${SKILLS_DIR}/scripts"    2>/dev/null || true
  [ -d "${SKILLS_DIR}/assets" ]     && rmdir "${SKILLS_DIR}/assets"     2>/dev/null || true
  [ -d "${SKILLS_DIR}" ]            && rmdir "${SKILLS_DIR}"            2>/dev/null || true

  echo ""
  echo "Uninstall complete."
}

case "${1:-}" in
  --uninstall) do_uninstall ;;
  "")          do_install   ;;
  *) echo "Usage: install.sh [--uninstall]" >&2; exit 1 ;;
esac
