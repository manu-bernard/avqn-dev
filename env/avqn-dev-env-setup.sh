#!/usr/bin/env bash
# Script de configuration de l'environnement cloud « avqn-dev ».
# Deux jobs : (1) installer le plugin avqn-dev en scope user (skills méthodo) ;
# (2) enregistrer le MCP Playwright au scope user.
# Les .mcp.json par-repo ne sont PAS chargés dans une routine — d'où ces lignes.
# Les PERMISSIONS vivent dans les repos (.claude/settings.json), versionnées, rien à
# faire ici.
# Logging robuste : redirection simple (pas de process substitution >(tee), qui peut
# faire avorter le parsing du script et le rendre muet).
set -uo pipefail
exec >>/tmp/avqn-env-setup.log 2>&1
echo "== setup avqn-dev @ $(date -u +%FT%TZ) =="

# Plugin méthodo AVQN : marketplace auto-hébergée + install scope user (auto-enabled partout).
# Repo privé → l'env doit être authentifié GitHub. Si l'install échoue (auth), c'est le point
# de validation n°1 du chantier — voir docs/conception.md.
claude plugin marketplace add manu-bernard/avqn-dev \
  && claude plugin install avqn-dev@avqn-dev --scope user \
  && echo "plugin avqn-dev OK" || echo "plugin avqn-dev KO"

# Chromium est déjà fourni par l'image (PLAYWRIGHT_BROWSERS_PATH). --no-sandbox (root),
# --executable-path (sinon le MCP veut télécharger chrome-for-testing).
claude mcp add playwright --scope user -- \
  npx -y @playwright/mcp@latest --headless --isolated --no-sandbox \
  --browser chromium --executable-path /opt/pw-browsers/chromium \
  && echo "mcp add OK" || echo "mcp add KO"
claude mcp list || true

echo "== fin setup avqn-dev =="
