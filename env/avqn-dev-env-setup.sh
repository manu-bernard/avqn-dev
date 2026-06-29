#!/usr/bin/env bash
# Script de configuration de l'environnement cloud « avqn-dev ».
# SEUL job : enregistrer le MCP Playwright au scope user. En routine multi-source, les
# .mcp.json par-repo ne sont PAS chargés (seulement les .claude/skills le sont) — d'où
# cette ligne. Les SKILLS et les PERMISSIONS vivent dans les repos (.claude/skills/ +
# .claude/settings.json), versionnés, rien à faire ici.
# Logging robuste : redirection simple (pas de process substitution >(tee), qui peut
# faire avorter le parsing du script et le rendre muet).
set -uo pipefail
exec >>/tmp/avqn-env-setup.log 2>&1
echo "== setup avqn-dev @ $(date -u +%FT%TZ) =="

# Chromium est déjà fourni par l'image (PLAYWRIGHT_BROWSERS_PATH). --no-sandbox (root),
# --executable-path (sinon le MCP veut télécharger chrome-for-testing).
claude mcp add playwright --scope user -- \
  npx -y @playwright/mcp@latest --headless --isolated --no-sandbox \
  --browser chromium --executable-path /opt/pw-browsers/chromium \
  && echo "mcp add OK" || echo "mcp add KO"
claude mcp list || true

echo "== fin setup avqn-dev =="
