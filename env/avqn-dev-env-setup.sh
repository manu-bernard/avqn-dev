#!/usr/bin/env bash
# Script de configuration de l'environnement cloud AVQN : méthodo `avqn-dev` (skills) + Playwright.
#
# Contrainte du sandbox : le proxy sortant laisse passer LIBREMENT npm/npx et curl/HTTPS, mais bride
# `git clone` aux seuls dépôts déclarés en SOURCE de l'env — et on n'en déclare AUCUN en plus des
# repos d'app (règle : pas de repo lié parasite). D'où deux voies « sans git clone », une par besoin :
#
#   1) Playwright n'est PAS un plugin : c'est un serveur MCP tiré de npm (`npx @playwright/mcp`).
#      → `claude mcp add` : aucune marketplace, aucun repo, aucune source. npm sort librement.
#
#   2) La méthodo, ce sont des SKILLS (des fichiers) → il FAUT une marketplace/plugin. Le seul canal
#      libre pour rapatrier ses fichiers sans git clone ni source = un TARBALL curl du repo PUBLIC
#      avqn-dev, ajouté ensuite comme marketplace depuis un chemin LOCAL.
#
#   Pistes écartées (vérifiées) : `marketplace add <owner/repo>` fait un git clone → 403 sans source ;
#   `marketplace add <url>` ajoute bien le catalogue en HTTPS, mais installer un plugin à source `./x`
#   exige un clone local des fichiers → échoue aussi. Le jour où on voudra une install 100 % « propre »
#   comme Playwright (une commande, zéro fichier), on publiera la méthodo en PACKAGE npm. En attendant,
#   le tarball est la voie assumée. (La marketplace git `a-v-q-n/avqn-dev` sert claude.ai et
#   Claude Code en usage interactif, où `git clone` n'est pas bridé — pas cet env.)
set -uo pipefail
exec >>/tmp/avqn-env-setup.log 2>&1
echo "== setup avqn @ $(date -u +%FT%TZ) =="

PLAYWRIGHT_ARGS=(--headless --isolated --no-sandbox --browser chromium --executable-path /opt/pw-browsers/chromium)

# 1) Méthodo avqn-dev — tarball du repo PUBLIC (sans token, sans source), marketplace en chemin local.
rm -rf /root/.avqn && mkdir -p /root/.avqn
curl -fsSL https://github.com/a-v-q-n/avqn-dev/archive/refs/heads/main.tar.gz | tar xz -C /root/.avqn
claude plugin marketplace add /root/.avqn/avqn-dev-main \
  && claude plugin install avqn-dev@avqn-dev --scope user \
  && echo "méthodo avqn-dev OK" || echo "méthodo avqn-dev KO"

# 2) Playwright — serveur MCP direct (npx = libre), Chromium pré-installé de l'env à /opt/pw-browsers.
claude mcp add playwright --scope user -- \
  npx -y @playwright/mcp@latest "${PLAYWRIGHT_ARGS[@]}" \
  && echo "playwright OK" || echo "playwright KO"

# 3) Fluidité MAXIMALE : bypass total des permissions au SCOPE USER (une place → tous les repos,
#    toutes les sessions). `defaultMode: bypassPermissions` = plus AUCUN pop-up, jamais — indispensable
#    aussi pour les workers AUTONOMES (un run unattended ne peut pas répondre à un prompt). Légitime
#    ici : l'env cloud est un sandbox jetable et isolé (egress bridé). À NE PAS reproduire en local.
#    On garde aussi l'allow ciblé Playwright (redondant mais explicite). Merge NON destructif via jq.
SETTINGS="$HOME/.claude/settings.json"
mkdir -p "$(dirname "$SETTINGS")"
[ -s "$SETTINGS" ] || echo '{}' > "$SETTINGS"
tmp=$(mktemp)
jq '.permissions.defaultMode = "bypassPermissions"
    | .permissions.allow = ((.permissions.allow // []) + ["mcp__playwright"] | unique)' "$SETTINGS" > "$tmp" \
  && mv "$tmp" "$SETTINGS" && echo "permissions bypass OK" || { rm -f "$tmp"; echo "permissions bypass KO"; }

claude mcp list || true
echo "== fin setup avqn =="
