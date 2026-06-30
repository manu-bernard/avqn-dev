#!/usr/bin/env bash
# Script de configuration de l'environnement cloud AVQN.
# Job : installer le plugin méthodo `avqn-dev` (scope user) + l'outillage Playwright (`avqn-tooling`).
#
# CIBLE (storefront unifié) : tout passe par la marketplace UNIQUE `avqn` (manu-bernard/avqn-plugins).
#   claude plugin marketplace add manu-bernard/avqn-plugins
#   claude plugin install avqn-dev@avqn      # méthodo (source github → avqn-dev)
#   claude plugin install avqn-tooling@avqn  # embarque le MCP Playwright
# PRÉ-REQUIS : `avqn-plugins` ET `avqn-dev` déclarés en SOURCES de l'env (le proxy git n'autorise
# le clone que des sources ; curl/HTTP sort librement). Voir docs/conception.md.
#
# FALLBACK : si la voie native échoue (sources non déclarées, etc.), on retombe sur le tarball
# curl du repo public avqn-dev (marche sans source) + `claude mcp add playwright`. Ainsi ce script
# ne peut JAMAIS laisser une session sans méthodo.
set -uo pipefail
exec >>/tmp/avqn-env-setup.log 2>&1
echo "== setup avqn @ $(date -u +%FT%TZ) =="

PLAYWRIGHT_ARGS=(--headless --isolated --no-sandbox --browser chromium --executable-path /opt/pw-browsers/chromium)

if claude plugin marketplace add manu-bernard/avqn-plugins \
   && claude plugin install avqn-dev@avqn --scope user; then
  echo "méthodo avqn-dev via la marketplace avqn OK"
  # Outillage Playwright : via le plugin si possible, sinon enregistrement MCP direct.
  claude plugin install avqn-tooling@avqn --scope user \
    && echo "avqn-tooling (playwright) OK" \
    || { echo "avqn-tooling KO → mcp add direct"; claude mcp add playwright --scope user -- \
         npx -y @playwright/mcp@latest "${PLAYWRIGHT_ARGS[@]}"; }
else
  echo "voie native KO (avqn-plugins/avqn-dev pas en source ?) → fallback tarball"
  URL=https://github.com/manu-bernard/avqn-dev/archive/refs/heads/main.tar.gz
  rm -rf /root/.avqn && mkdir -p /root/.avqn
  curl -fsSL -o /root/.avqn/src.tar.gz "$URL"
  tar xzf /root/.avqn/src.tar.gz -C /root/.avqn
  claude plugin marketplace add /root/.avqn/avqn-dev-main \
    && claude plugin install avqn-dev@avqn-dev --scope user \
    && echo "plugin avqn-dev (fallback) OK" || echo "plugin avqn-dev KO"
  claude mcp add playwright --scope user -- npx -y @playwright/mcp@latest "${PLAYWRIGHT_ARGS[@]}" \
    && echo "mcp add OK" || echo "mcp add KO"
fi
claude mcp list || true
echo "== fin setup avqn =="
