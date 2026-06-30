# Plan 2 — Rollout repos d'app (contrat-only) + Coolify lisible + legacy — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mettre tous les repos d'app au régime « contrat-only » (la méthodo vient du plugin `avqn-dev`), rendre le `mode:` Coolify explicite, et tuer le legacy (render-farm standalone, avqn-deploy, design périmé).

**Architecture:** La méthodo de dev (skills `dev`/`apercu`/`brainstorm-issue` + superpowers) est fournie par le plugin `avqn-dev` (installé en scope user, **auto-enabled**). Les repos d'app suppriment leurs skills/hook/CLAUDE.md de méthodo et ne gardent que leur **contrat** (gate, UI, services, coordonnées Coolify). Les reusable workflows reçoivent un `mode:` explicite (sans changer l'infra). Le render-farm standalone et le clone avqn-deploy sont archivés.

**Tech Stack:** Markdown (CLAUDE.md, hooks bash), GitHub Actions YAML, `gh` CLI, npm.

## Global Constraints

- **Plugin auto-enabled** : une install scope user est auto-enabled. **Ne JAMAIS ajouter `avqn-dev` à `enabledPlugins`** d'un `settings.json` — inutile, et ça peut errorer (marketplace inconnue côté repo). Laisser `superpowers`/`frontend-design` tels quels.
- **Coolify : aucun changement d'infra.** On rend `mode:` explicite, valeurs = type Coolify RÉEL : `service` pour contentos, render-farm (apps/render-farm), **product-site-avqn** ; `application` pour avqn-os, product-barometre-ia. **`product-site-avqn` est un `service`** (image via `${IMAGE_TAG}`) — NE PAS mettre `application` (casserait le déploiement).
- **Ne pas toucher au code applicatif** : uniquement `.claude/`, `CLAUDE.md`/`AGENTS.md`, `docs/`, `.github/workflows/`, `package.json` (champ `private`).
- **Contrat à préserver verbatim** dans chaque `CLAUDE.md` : commande de gate, présence d'UI + commande de lancement local + URL + pages/breakpoints, services requis (Postgres/Redis), versioning, coordonnées Coolify (uuid preview, uuid prod, health url, **mode**), secrets. On retire SEULEMENT la *procédure* de dev (brancher/TDD/PR/merge/brainstorm).
- **Drive-to-main** : commits descriptifs 🤖, fin de message `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Travailler sur une branche par repo puis FF sur main (ou direct main : ce sont des changements config/docs sans risque applicatif). Lancer la gate du repo avant de pousser.
- **Style doc** : état-cible, pas d'« désormais / au lieu de / avant ».
- **Conservatisme legacy** : on ne supprime que les docs PÉRIMÉS ET trompeurs. Les specs/plans datés (records de travail fait) restent.

Repos & clones locaux (workspace `/Users/ManuAVQN/Code/contentos-renderfarm/`) : `avqn-os`, `contentos` (monorepo), `product-site-avqn`, `product-barometre-ia`, `render-farm` (standalone, à archiver), `avqn-deploy` (clone d'un repo déjà archivé).

---

### Task 1: avqn-os — contrat-only + drive-to-main

**Files:**
- Delete: `avqn-os/.claude/skills/apercu/` (le plugin fournit `apercu`)
- Delete: `avqn-os/tools/apercu/`, `avqn-os/bin/apercu` (moteur de capture maison, remplacé par l'apercu MCP du plugin)
- Modify: `avqn-os/.claude/hooks/session-start.sh` (retirer le « stop à la PR » ligne ~31)
- Modify: `avqn-os/CLAUDE.md` (retirer la procédure de dev, garder le contrat)

- [ ] **Step 1: Brancher + fetch**
```bash
cd ~/Code/contentos-renderfarm/avqn-os && git fetch origin && git checkout -b chore/contrat-only origin/main
```

- [ ] **Step 2: Supprimer les skills/outils apercu vendorisés**
```bash
git rm -r .claude/skills/apercu tools/apercu bin/apercu
```
Vérifier qu'aucune autre skill méthodo n'est vendorisée : `ls .claude/skills 2>/dev/null` doit être vide ou ne contenir que des skills MÉTIER spécifiques avqn-os (le cas échéant, les lister et NE PAS les toucher).

- [ ] **Step 3: Réécrire le hook session-start (drive-to-main)**
Ouvrir `.claude/hooks/session-start.sh`. Remplacer la phrase « tu ouvres la PR et tu t'arrêtes là — tu ne merges pas, tu ne déploies pas » (ligne ~31) par :
`# Méthodo (brancher/TDD/PR/CI/FF merge → preview) : fournie par le plugin avqn-dev. L'agent va jusqu'au FF sur main, jamais la prod.`
Garder le reste du hook (neutralisation de signature de commit, install deps).

- [ ] **Step 4: Réduire CLAUDE.md au contrat**
Lire `avqn-os/CLAUDE.md`. Retirer toute section « comment on travaille / pipe & méthode / cycle de dev » (brainstorm, plan, TDD, PR, gate, merge). Garder : architecture des tools MCP par domaine, contrat `/healthz`, endpoints OS, schéma Postgres, commandes de gate/test/build, versioning, **coordonnées Coolify** (preview `mg8k0wco0s8w440w0c8w0swk`, prod `dok8gkos8w88888okkcs0808`, health `https://os.preview.avqn.ch/healthz` / `https://os.avqn.ch/healthz`, **mode `application`**). Ajouter une ligne en tête : « Méthodo de dev : plugin `avqn-dev` (auto-chargé). Ce fichier = le contrat du repo. »

- [ ] **Step 5: Vérifier + gate + commit + FF**
```bash
grep -rniE "s'arrête à la pr|tu ne merges pas|stop.{0,3}pr" .claude CLAUDE.md && echo "RESTE DU LEGACY" || echo "clean"
npm ci && npm run check && npm run build && npm test
git add -A && git commit -m "🧹 contrat-only : méthodo via plugin avqn-dev, drive-to-main, apercu retiré 🤖 …trailer"
git checkout main && git pull --ff-only origin main && git merge --ff-only chore/contrat-only && git push origin main
```
Expected : grep « clean » ; gate verte. (avqn-os `mode` déjà `application` dans ses workflows — rien à changer côté CI.)

---

### Task 2: contentos (monorepo) — contrat-only ×3 + mode explicite + purge design périmé

**Files:**
- Delete: `contentos/.claude/skills/apercu/` (plugin fournit apercu)
- Delete: `contentos/docs/superpowers/specs/2026-06-28-nettoyage-harness-contentos-design.md` (design périmé : modèle « agent recette / stop à la PR », contredit l'état cible)
- Modify: `contentos/CLAUDE.md`, `contentos/apps/contentos/CLAUDE.md`, `contentos/apps/render-farm/CLAUDE.md` (contrat-only)
- Modify: `contentos/.github/workflows/{ci-contentos.yml, promote-contentos.yml, ci-render-farm.yml, promote-render-farm.yml}` (ajouter `mode: service`)

- [ ] **Step 1: Brancher**
```bash
cd ~/Code/contentos-renderfarm/contentos && git fetch origin && git checkout -b chore/contrat-only origin/main
```

- [ ] **Step 2: Supprimer apercu vendorisé + design périmé**
```bash
git rm -r .claude/skills/apercu
git rm docs/superpowers/specs/2026-06-28-nettoyage-harness-contentos-design.md
```
(Le hook `contentos/.claude/hooks/session-start.sh` est déjà au modèle drive-to-main — NE PAS toucher. Le `.mcp.json` Playwright reste.)

- [ ] **Step 3: `mode: service` explicite — 4 workflows**
Dans chaque fichier, sous le bloc `with:` de l'appel `uses: manu-bernard/avqn-dev/.github/workflows/{deploy|promote}.yml@v1`, ajouter la ligne `mode: service` (même indentation que `uuid:`/`health_url:`).
- `ci-contentos.yml` (~l.153–159, deploy, uuid `w44gkskcw0swk4ckc88ccsg0`) → `mode: service`
- `promote-contentos.yml` (~l.6–12, promote) → `mode: service`
- `ci-render-farm.yml` (~l.114–120, deploy, uuid `cc8k0wossswcwco8wsckks48`) → `mode: service`
- `promote-render-farm.yml` (~l.6–12, promote) → `mode: service`

- [ ] **Step 4: Réduire les 3 CLAUDE.md au contrat**
Pour chacun, retirer la section « comment on travaille » (brainstorm → plan → TDD → PR → gate → FF), garder le contrat :
- `contentos/CLAUDE.md` (racine) : structure monorepo, apps, contrat video-spec, workspace, gate par app (`npm run gate -w <app>`), secrets Bitwarden, **coordonnées Coolify des 2 apps** (contentos service preview `w44gkskcw0swk4ckc88ccsg0`/prod `oo0scscwwk8os4wogkkokccg` health `…preview.contentos.ch/api/health` ; render-farm service preview `cc8k0wossswcwco8wsckks48`/prod `xk8owk0wk00oww4owwoso48w` health `…renderfarm.preview.contentos.ch/healthz`), **mode `service`** pour les deux.
- `apps/contentos/CLAUDE.md` : rôle, MCP endpoint `/api/mcp`, modules, auth BetterAuth, stack, services (Postgres, Redis), commands, test pitfalls, secrets.
- `apps/render-farm/CLAUDE.md` : rôle `/v1`, architecture api/worker/engine, contrat `VideoSpec` (`packages/video-spec`), services (Redis), commands.
Ajouter en tête de chacun : « Méthodo de dev : plugin `avqn-dev`. Ce fichier = le contrat. »

- [ ] **Step 5: Vérifier + gate + commit + FF**
```bash
grep -rniE "brainstorm|tu n'arrêtes plus|TDD|fast-forward" CLAUDE.md apps/*/CLAUDE.md | grep -viE "plugin avqn-dev" && echo "VERIFIER" || echo "clean-ish"
npm ci && npm run gate
git add -A && git commit -m "🧹 contrat-only ×3 + mode: service explicite + purge design périmé 🤖 …trailer"
git checkout main && git pull --ff-only origin main && git merge --ff-only chore/contrat-only && git push origin main
```
Expected : gate verte ; YAML toujours valide (les 4 workflows parsent). Note : le grep peut matcher des mentions légitimes du contrat — relire à la main, l'objectif est qu'il ne reste pas de *procédure* de dev.

---

### Task 3: product-site-avqn — contrat-only + purge avqn-dx + mode: service

**Files:**
- Modify: `product-site-avqn/.claude/hooks/session-start.sh` (l.14–16 : retirer « lus depuis avqn-dx »)
- Modify: `product-site-avqn/scripts/cloud-setup.sh` (l.2 : retirer « TEMPLATE avqn-dx »)
- Modify: `product-site-avqn/CLAUDE.md` (contrat-only)
- Modify: `product-site-avqn/.github/workflows/{ci.yml, promote.yml}` (ajouter `mode: service`)

- [ ] **Step 1: Brancher**
```bash
cd ~/Code/contentos-renderfarm/product-site-avqn && git fetch origin && git checkout -b chore/contrat-only origin/main
```

- [ ] **Step 2: Purger les références avqn-dx (substrat legacy)**
- `.claude/hooks/session-start.sh` l.14–16 : remplacer « Release = /recetter · /deployer · /promouvoir (lus depuis avqn-dx) » par « Méthodo & release : plugin `avqn-dev` (auto-chargé). »
- `scripts/cloud-setup.sh` l.2 : retirer « TEMPLATE avqn-dx » du commentaire. Garder les fonctions utiles (install plugins, wstunnel, bws, npmrc). Vérifier qu'aucun `git clone`/fetch d'`avqn-dx` ne subsiste : `grep -rn avqn-dx .claude scripts` → doit être vide après édition.

- [ ] **Step 3: `mode: service` explicite**
- `ci.yml` (~l.110–116, deploy, uuid `mkocss0s8oc4o4w80w0kkggg`) → ajouter `mode: service`
- `promote.yml` (~l.9–15, promote, prod `gk8kg0gwkwss4cgc0wwsocog`) → ajouter `mode: service`
**ATTENTION** : `service`, PAS `application` (site-avqn est un service Coolify, image via `${IMAGE_TAG}`).

- [ ] **Step 4: Réduire CLAUDE.md au contrat**
Retirer le § « Pipe & méthode / comment on développe ». Garder : rôle (vitrine avqn.ch), architecture hybride (statique + Node runtime), stack Astro, gate (`pnpm run check:all && pnpm run test:unit`), build, services (aucune DB), formulaire contact, redirections 301, charte, **Coolify** (preview `mkocss0s8oc4o4w80w0kkggg`/prod `gk8kg0gwkwss4cgc0wwsocog`, health `…/healthz.json`, **mode `service`**), env vars runtime. Tête : « Méthodo : plugin `avqn-dev`. »

- [ ] **Step 5: Vérifier + gate + commit + FF**
```bash
grep -rn "avqn-dx" .claude scripts CLAUDE.md && echo "RESTE AVQN-DX" || echo "clean"
corepack enable && pnpm install && pnpm run check:all && pnpm run test:unit
git add -A && git commit -m "🧹 contrat-only + purge avqn-dx + mode: service explicite 🤖 …trailer"
git checkout main && git pull --ff-only origin main && git merge --ff-only chore/contrat-only && git push origin main
```
Expected : grep « clean » ; gate verte.

---

### Task 4: product-barometre-ia — contrat-only

**Files:**
- Modify: `product-barometre-ia/CLAUDE.md` (retirer le cycle de livraison, garder le contrat)

(Pas de `.claude/` dans ce repo ; `mode: application` déjà explicite dans ses workflows — rien à changer côté CI.)

- [ ] **Step 1: Brancher**
```bash
cd ~/Code/contentos-renderfarm/product-barometre-ia && git fetch origin && git checkout -b chore/contrat-only origin/main
```

- [ ] **Step 2: Réduire CLAUDE.md au contrat**
Retirer la section « cycle de livraison » (gate locale → PR → CI → FF merge). Garder : règles non négociables, archéologie, stack, gate (`npm run typecheck && npm test && npm run build`), services (Postgres centralisé), **Coolify** (preview `b0o4wss4o0s4skc0wsoo4s40`/prod `dgg4gk8w4ooc0ogoc0g4owgs`, health `…/api/healthz`, **mode `application`**), contrat `/v1`, secrets. Tête : « Méthodo : plugin `avqn-dev`. »

- [ ] **Step 3: Vérifier + gate + commit + FF**
```bash
grep -niE "fast-forward|cycle de livraison|ouvre une PR" CLAUDE.md | grep -vi "plugin" && echo "VERIFIER" || echo "clean-ish"
npm ci && npm run typecheck && npm test && npm run build
git add -A && git commit -m "🧹 contrat-only : méthodo via plugin avqn-dev 🤖 …trailer"
git checkout main && git pull --ff-only origin main && git merge --ff-only chore/contrat-only && git push origin main
```

---

### Task 5: video-spec — `private: true`

**Files:**
- Modify: `contentos/packages/video-spec/package.json` (`"private": true`, retirer `publishConfig` s'il existe)

- [ ] **Step 1: Vérifier l'état + éditer**
```bash
cd ~/Code/contentos-renderfarm/contentos
node -e "const p=require('./packages/video-spec/package.json'); console.log(JSON.stringify({private:p.private,publishConfig:p.publishConfig},null,2))"
```
Mettre `"private": true` dans `packages/video-spec/package.json`. Si une clé `publishConfig` existe, la retirer. Confirmer qu'il n'existe **pas** de `contentos/.github/workflows/publish-spec.yml` (le publish vit dans le standalone, qui est archivé en Task 6) : `ls .github/workflows/publish-spec.yml 2>/dev/null || echo "pas de publish (ok)"`.

- [ ] **Step 2: Gate workspace + commit + FF**
(Peut être groupé avec Task 2 si même branche ; sinon branche dédiée.)
```bash
git checkout -b chore/video-spec-private origin/main
git add packages/video-spec/package.json
git commit -m "🔒 video-spec : private true (workspace local, jamais publié) 🤖 …trailer"
npm ci && npm run gate -w @manu-bernard/video-spec --if-present
git checkout main && git pull --ff-only origin main && git merge --ff-only chore/video-spec-private && git push origin main
```

---

### Task 6: Archiver le render-farm standalone

Le repo `manu-bernard/render-farm` pointe les MÊMES UUID Coolify que `contentos/apps/render-farm` (collision). Le monorepo est la source de vérité.

**Files:** aucun (opération GitHub + nettoyage local).

- [ ] **Step 1: Confirmer qu'il n'est plus référencé**
```bash
grep -rn "manu-bernard/render-farm" ~/Code/contentos-renderfarm/avqn-deploy/projects.txt
gh api repos/manu-bernard/avqn-dev/contents/projects.txt --jq '.content' | base64 -d   # doit NE PAS contenir render-farm
```
`avqn-dev/projects.txt` ne doit pas lister render-farm (déjà retiré). Vérifier aussi que la routine « Dev continu AVQN » n'a pas render-farm en source (action UI de Manu — voir § Manuel).

- [ ] **Step 2: Archiver le repo GitHub**
```bash
gh repo edit manu-bernard/render-farm --archived
gh repo view manu-bernard/render-farm --json isArchived
```
Expected : `isArchived: true`. (Réversible : `--archived=false`.)

- [ ] **Step 3: Retirer le clone local**
```bash
rm -rf ~/Code/contentos-renderfarm/render-farm
```
(Hygiène workspace ; le repo distant archivé reste consultable.)

---

### Task 7: Retirer le clone local avqn-deploy

`manu-bernard/avqn-deploy` est déjà archivé sur GitHub ; son playbook/`projects.txt`/skill `dev` vivent maintenant dans `avqn-dev`.

**Files:** aucun.

- [ ] **Step 1: Confirmer l'archivage distant + retirer le clone**
```bash
gh repo view manu-bernard/avqn-deploy --json isArchived   # attendu isArchived: true
rm -rf ~/Code/contentos-renderfarm/avqn-deploy
```

---

## Étapes manuelles (Manu — config routine, hors agent)

- **Routine « Dev continu AVQN »** : retirer `manu-bernard/avqn-dev` des **sources** (plus nécessaire — plugin par tarball) ; retirer aussi `manu-bernard/render-farm` s'il y figure ; mettre à jour la phrase du prompt « la skill `dev`… agrégée depuis avqn-dev » → « …fournie par le plugin `avqn-dev` ». Garder les 4 repos d'app en sources + le script de config tarball.
- **Nettoyage workspace local (optionnel)** : `rm ~/Code/contentos-renderfarm/avqn-dev-conception.md ~/Code/contentos-renderfarm/avqn-dev-env-setup.sh` (copies obsolètes ; les versions canoniques vivent dans le repo `avqn-dev`).

---

## Self-Review

**Spec coverage** (vs design d'homogénéisation §2/§3/§4/§5/§6) :
- §3 nettoyage méthodo (stop-à-la-PR avqn-os, design périmé contentos, apercu vendorisés, template session-start) → Tasks 1,2,3. ✓
- §3 repos = contrat-only → Tasks 1–4. ✓
- §4 render-farm standalone archivé → Task 6 ; avqn-deploy clone supprimé → Task 7 ; video-spec private → Task 5. ✓
- §5 Coolify `mode:` explicite → Tasks 1(déjà),2,3,4(déjà). ✓ (infra inchangée ; site-avqn = service confirmé)
- §6 routine sources = repos d'app → § Manuel (config trigger, hors agent). ✓

**Placeholder scan** : pas de TBD. Les réductions de CLAUDE.md décrivent quoi retirer / quoi garder (contrat listé avec valeurs) sans recopier chaque fichier (réécriture de prose existante) — acceptable.

**Type/cohérence** : UUID Coolify et modes cohérents avec l'inventaire (service: contentos/render-farm/site-avqn ; application: avqn-os/barometre). `mode` jamais inversé (site-avqn = service, garde-fou répété).

**Risque** : retirer un apercu vendorisé bascule la boucle visuelle sur l'apercu MCP du plugin — vérifier au 1er usage qu'il boote bien dans chaque repo à UI (avqn-os, contentos, site-avqn). Si un repo a une raison spécifique de garder un apercu maison, le signaler avant suppression (Task 1/2 Step 2).
