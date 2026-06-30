# Plugin `avqn-dev` + refactor `dev` cœur/amorce — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformer `avqn-dev` en plugin Claude Code installable en scope user (méthodo chargée dynamiquement partout, interactif comme routine), et refactorer le skill `dev` pour isoler un cœur d'implémentation commun de ses deux amorces (interactive / routine).

**Architecture:** `avqn-dev` devient à la fois un plugin (`.claude-plugin/plugin.json` + `skills/`) et sa propre marketplace GitHub (`.claude-plugin/marketplace.json`, `source: ./`). Les reusable workflows restent sous `.github/workflows/` (consommés par `uses:`, hors plugin). Le skill `dev` expose un **cœur** (plan→TDD→apercu→gate→PR→CI→FF→preview) appelé par deux amorces : routine (issue `ready`) et interactive (conversation + brainstorming live).

**Tech Stack:** Claude Code plugins/marketplaces, skills Markdown, bash (script d'env cloud), git.

## Global Constraints

- Repo cible : `manu-bernard/avqn-dev` (privé). Branche `main`, drive-to-main (FF), commits descriptifs avec emoji 🤖, fin de message : `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Un plugin Claude Code expose ses skills dans **`skills/<name>/SKILL.md` à la racine du plugin**, pas `.claude/skills/`.
- `plugin.json` minimal : `{ "name", "version", "description", "author", "homepage" }`. `marketplace.json` : `{ "$schema", "name", "owner", "metadata"?, "plugins": [...] }`.
- **Ne rien supprimer dans les repos d'app dans ce plan** : ils sont traités au Plan 2, après le checkpoint. Ici on ne touche QUE `avqn-dev`.
- Doc « instantané, pas historique » : réécrire les sections en état cible, pas de « désormais / au lieu de ».
- Validation à chaque étape par `claude plugin validate` et, pour le chargement, install locale réelle — pas de supposition.

---

### Task 1: Layout plugin — déplacer les skills sous `skills/` + `plugin.json`

**Files:**
- Create: `avqn-dev/.claude-plugin/plugin.json`
- Move: `avqn-dev/.claude/skills/*` → `avqn-dev/skills/*` (tous les dossiers : `dev`, `brainstorm-issue`, `apercu`, + superpowers vendorisées)
- Keep in place: `avqn-dev/.claude/settings.json` (config de session du repo, hors plugin), `avqn-dev/.github/workflows/*`

**Interfaces:**
- Produces: un plugin local valide à la racine `avqn-dev/`, dont les skills sont sous `skills/`.

- [ ] **Step 1: Déplacer les skills vers le layout plugin**

```bash
cd ~/avqn-dev   # ou le clone de travail
git mv .claude/skills skills
ls skills/      # attendu : apercu  brainstorm-issue  dev  brainstorming  test-driven-development ... (toutes les skills)
```

- [ ] **Step 2: Écrire `plugin.json`**

```bash
mkdir -p .claude-plugin
```

`.claude-plugin/plugin.json` :
```json
{
  "name": "avqn-dev",
  "version": "1.0.0",
  "description": "Backbone du dev continu AVQN : skills brainstorm-issue / dev / apercu + superpowers vendorisées. Deux modes (interactif, routine) partageant un cœur d'implémentation jusqu'à la preview.",
  "author": { "name": "AVQN", "email": "manu.avqn@gmail.com" },
  "homepage": "https://github.com/manu-bernard/avqn-dev"
}
```

- [ ] **Step 3: Valider le manifest plugin**

Run: `claude plugin validate ~/avqn-dev`
Expected: validation OK (plugin `avqn-dev` reconnu, skills détectées). Si erreur de chemin de skills → corriger l'emplacement (`skills/` racine).

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "$(printf '%s' '🔌 plugin: layout avqn-dev (skills/ + plugin.json)\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 2: Marketplace auto-hébergée (`marketplace.json`)

**Files:**
- Create: `avqn-dev/.claude-plugin/marketplace.json`

**Interfaces:**
- Consumes: le plugin `avqn-dev` de la Task 1.
- Produces: une marketplace installable via `claude plugin marketplace add manu-bernard/avqn-dev`, exposant un plugin `avqn-dev` dont `source: ./` (le repo lui-même).

- [ ] **Step 1: Écrire `marketplace.json`**

`.claude-plugin/marketplace.json` :
```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "avqn-dev",
  "owner": { "name": "AVQN", "email": "manu.avqn@gmail.com" },
  "metadata": { "description": "Backbone du dev continu AVQN", "version": "1.0.0" },
  "plugins": [
    {
      "name": "avqn-dev",
      "source": "./",
      "description": "Méthodo de dev continu AVQN (brainstorm-issue, dev, apercu + superpowers).",
      "version": "1.0.0",
      "strict": true
    }
  ]
}
```

- [ ] **Step 2: Valider le manifest marketplace**

Run: `claude plugin validate ~/avqn-dev`
Expected: marketplace `avqn-dev` valide + plugin `avqn-dev` résolu via `source: ./`. Si `strict: true` fait échouer (skill mal formée), lister l'erreur et corriger la skill fautive.

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "$(printf '%s' '🏪 plugin: avqn-dev s'\''auto-déclare marketplace (source ./)\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 3: PREUVE — install locale scope user + chargement des skills

But : prouver, sur cette machine, que le plugin s'installe en scope user et que `dev`/`apercu`/`brainstorm-issue` se chargent. C'est le dé-risquage du design avant d'aller plus loin.

**Files:** aucun (vérification).

- [ ] **Step 1: Ajouter la marketplace depuis le clone local**

Run: `claude plugin marketplace add ~/avqn-dev`
Expected: marketplace `avqn-dev` ajoutée (apparaît dans `claude plugin marketplace list`).

- [ ] **Step 2: Installer le plugin en scope user**

Run: `claude plugin install avqn-dev@avqn-dev --scope user`
Expected: install OK ; `claude plugin list` montre `avqn-dev` en scope `user`.

- [ ] **Step 3: Vérifier l'inventaire des skills du plugin**

Run: `claude plugin details avqn-dev`
Expected: l'inventaire liste les skills `dev`, `apercu`, `brainstorm-issue` (+ superpowers vendorisées). Si absentes → l'emplacement `skills/` est mauvais, revenir Task 1.

- [ ] **Step 4: Vérifier le chargement en session réelle (depuis un repo TIERS)**

Run (depuis un repo d'app quelconque, p.ex. `~/product-site-avqn`) :
```bash
cd ~/product-site-avqn
claude -p "Liste les skills disponibles qui viennent du plugin avqn-dev (dev, apercu, brainstorm-issue). Réponds juste par la liste." 2>&1 | tail -20
```
Expected: les trois skills apparaissent — preuve qu'elles se chargent dynamiquement dans un repo qui ne les contient pas. **Si ça marche : le design « un seul repo ouvert » est prouvé en local.**

- [ ] **Step 5: Noter le résultat dans le plan**

Cocher cette task et écrire en une ligne le verdict (OK / échec + cause) sous la task dans ce fichier. Pas de commit de code (vérification seule).

---

### Task 4: Refactor `dev` — isoler le cœur des deux amorces

Réécrit `skills/dev/SKILL.md` pour exposer un **cœur** commun et deux **amorces**. Le cœur est la procédure actuelle (étapes 4→11). L'amorce routine = étapes 1→3 actuelles (issue `ready` + claim). L'amorce interactive = brainstorming live + spec issue-less.

**Files:**
- Modify: `avqn-dev/skills/dev/SKILL.md` (réécriture structurée)

**Interfaces:**
- Consumes: skills superpowers (`brainstorming`, `writing-plans`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`, `verification-before-completion`) + skill `apercu`.
- Produces: un skill `dev` à trois sections — `## Le cœur (commun)`, `## Amorce routine`, `## Amorce interactive` — sans changer les garde-fous.

- [ ] **Step 1: Réécrire la description frontmatter**

Nouveau frontmatter de `skills/dev/SKILL.md` :
```markdown
---
name: dev
description: Développe une tâche jusqu'à la PREVIEW (jamais la prod), via un cœur commun — plan → TDD → qualité visuelle locale (apercu) → gate locale → auto-review → PR → gate CI sur la branche → FF merge main (déclenche le deploy preview). Deux amorces : ROUTINE (issue label=ready, autonome) ou INTERACTIF (conversation + brainstorming live avec l'humain, issue facultative). Orchestrateur des skills superpowers.
---
```

- [ ] **Step 2: Écrire la section cœur**

Insérer après le titre, avant les amorces :
```markdown
# Dev

Tu portes du travail **jusqu'à la preview** : tu le **codes en TDD**, tu le rends **beau et testé en local**, puis tu le **merges en FF** sur `main` quand la CI est verte — ce qui déclenche seul le **deploy preview** (le `ci.yml` du repo). Tu ne déploies **rien** toi-même, **jamais** la prod (le promote prod est un geste humain).

Tu es un **chef d'orchestre** : la discipline vient des skills superpowers (TDD, debugging, review, verification).

## Le cœur (commun aux deux modes)

À partir d'une **spec** (d'où qu'elle vienne — voir les amorces) et d'une **branche** créée depuis `origin/main` :

1. **Planifier + coder en TDD** : `superpowers:writing-plans` à partir de la spec, puis `superpowers:test-driven-development` (rouge → code → vert). Changement minimal. Bug → `superpowers:systematic-debugging`.
2. **Qualité visuelle locale** : applique `apercu` SI le repo a une UI (cf. son `CLAUDE.md`) ET que la tâche touche le front. Sinon saute.
3. **Gate complète locale** : `npm ci` (ou équivalent) puis la **commande de gate du `CLAUDE.md`** du repo. Corrige jusqu'au vert. N'ouvre pas une PR que la CI rejettera.
4. **Auto-review adversariale** : `superpowers:requesting-code-review` (sous-agent frais). Applique les corrections réelles.
5. **Commit + rebase + PR** (la PR ne sort QUE si 1→4 sont verts) : commit descriptif (bump de version si le repo en a un) ; `git rebase origin/main` (conflit non trivial → abort + mise de côté) ; push ; ouvre la PR via MCP GitHub (`Closes #n` si une issue existe ; corps = quoi/pourquoi/comment vérifier).
6. **Gate via la CI sur la branche (MCP GitHub)** : dispatch `ci.yml` sur la branche, suivi jusqu'à `completed`. Rouge → ne merge pas (mise de côté + commentaire). Vert → étape 7.
7. **Merge fast-forward sur `main`** : `git checkout main && git pull --ff-only` ; `git merge --ff-only <branche>` ; `git push origin main`. Push rejeté → rebase + re-gate + retry. Le push déclenche le deploy preview (image `sha-` déjà construite, pas de rebuild).
8. **Clôturer + bilan** : vérifie la PR/issue ; `superpowers:verification-before-completion` avant de déclarer fait.
```

- [ ] **Step 3: Écrire l'amorce routine**

```markdown
## Amorce routine (autonome, horaire)

Sans humain. La spec **est** une issue `label=ready` — tu ne brainstormes jamais.

- **Environnement** : repos d'app clonés en sources ; le plugin `avqn-dev` fournit la méthodo. Opérations GitHub via le **MCP GitHub** (Actions en 403 avec `gh` dans le sandbox) ; git via le proxy des clones.
- **Gate d'entrée** : seulement les issues ouvertes `label=ready`. Pas de `ready` = ignore.
- **Sélection** : la plus ancienne issue `ready`, sans `pull_request`, sans `in-progress`, sans PR liée. **Une** par repo par run.
- **Claim** : pose `in-progress` sur l'issue.
- **Brancher** : `git checkout -b dev/issue-<n>-<slug> origin/main`. Lis le `CLAUDE.md` du repo (contrat).
- **→ Déroule le cœur** (spec = corps de l'issue). Issue ambiguë/trop grosse → ne devine pas : commente, retire `in-progress`, repo suivant.
```

- [ ] **Step 4: Écrire l'amorce interactive**

```markdown
## Amorce interactive (humain au clavier)

Avec l'humain, dans un seul repo. La spec naît de la **conversation**.

- **Cadrage** : `superpowers:brainstorming` en live (questions, options, design validé). Respecte sa discipline : pas de code avant accord sur le design.
- **Issue facultative** : tu peux ouvrir une issue pour tracer (et la `Closes` à la PR), mais ce n'est pas requis — l'humain est l'aval, en continu. Pas de gate `ready`.
- **Brancher** : `git checkout -b <type>/<slug> origin/main`. Lis le `CLAUDE.md` du repo (contrat).
- **→ Déroule le cœur** (spec = le design validé en conversation). Tu vas **jusqu'à la preview** ; tu t'arrêtes avant la prod (promote = geste humain).
```

- [ ] **Step 5: Réécrire les garde-fous (communs)**

```markdown
## Garde-fous
- **Changement minimal** ; **jamais deviner** (ambiguïté/conflit → mise de côté + commentaire en routine ; question à l'humain en interactif).
- **Tu vas jusqu'au FF sur `main`, jamais plus** : jamais de promo prod, jamais d'appel Coolify ni de dispatch de workflow de déploiement.
- **Jamais merge sur CI rouge** ; **rebase avant le FF**.
- **Gate locale complète + qualité visuelle AVANT la PR** ; **auto-review obligatoire** ; **Actions via le MCP GitHub** ; `verification-before-completion` avant de déclarer fait.
- Routine : **seulement `ready`**, **une issue par repo par run**.
```

- [ ] **Step 6: Valider + commit**

Run: `claude plugin validate ~/avqn-dev`
Expected: skill `dev` toujours valide.
```bash
git add skills/dev/SKILL.md
git commit -m "$(printf '%s' '♻️ dev: isole le cœur commun + 2 amorces (routine / interactif)\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 5: Script de config d'env cloud → install du plugin

**Files:**
- Modify: `avqn-dev/env/avqn-dev-env-setup.sh`

**Interfaces:**
- Consumes: la marketplace `avqn-dev` (Task 2).
- Produces: un env cloud où le plugin `avqn-dev` est installé en scope user + Playwright MCP enregistré.

- [ ] **Step 1: Ajouter l'install plugin au script**

Ajouter, avant l'enregistrement Playwright, dans `env/avqn-dev-env-setup.sh` :
```bash
# Plugin méthodo AVQN : marketplace auto-hébergée + install scope user.
# Repo privé → l'env doit être authentifié GitHub (gh/credential). Si l'install
# échoue (auth), c'est le point de validation n°1 du chantier — voir docs.
claude plugin marketplace add manu-bernard/avqn-dev \
  && claude plugin install avqn-dev@avqn-dev --scope user \
  && echo "plugin avqn-dev OK" || echo "plugin avqn-dev KO"
```

- [ ] **Step 2: Commit**

```bash
git add env/avqn-dev-env-setup.sh
git commit -m "$(printf '%s' '⚙️ env: installe le plugin avqn-dev en scope user\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 6: Docs en état cible (conception, README, CLAUDE.md)

**Files:**
- Modify: `avqn-dev/docs/conception.md` (§8 backbone, §9 recette, §10 routine — distribution par plugin ; §6 Coolify — règle mode explicite)
- Modify: `avqn-dev/README.md`
- Modify: `avqn-dev/CLAUDE.md`

**Interfaces:**
- Produces: docs décrivant la distribution par plugin (état cible), sans trace de l'ancien « agrégation multi-source » pour la méthodo.

- [ ] **Step 1: `conception.md` — distribution par plugin**

Dans §8/§9/§10, remplacer la mécanique « agrégation multi-source » de la méthodo par : « `avqn-dev` est un **plugin** installé en scope user (marketplace auto-hébergée `manu-bernard/avqn-dev`) ; ses skills se chargent dans chaque session de chaque repo, interactif comme routine. Les **sources** de la routine = les **repos d'app uniquement** (clones de travail). » Et préciser les **deux modes** (cœur commun + amorces) dans §3/§4.

- [ ] **Step 2: `conception.md` §6 — règle Coolify mode**

Ajouter la règle explicite : « `mode:` est passé explicitement par chaque repo. multi-process → `service` (PATCH `IMAGE_TAG`) ; mono-process → `application` (PATCH `docker_registry_image_tag`). »

- [ ] **Step 3: `README.md` + `CLAUDE.md` — plugin**

Réécrire la section « Ce qui vit ici / deux rôles » : (1) **plugin** (skills, distribué par marketplace user-scope), (2) **reusable workflows** (`uses:`). Retirer « jamais cloné en dev / agrégation multi-source » au profit de « plugin user-scope ». Mentionner le layout `skills/` + `.claude-plugin/`.

- [ ] **Step 4: Commit**

```bash
git add docs/conception.md README.md CLAUDE.md
git commit -m "$(printf '%s' '📝 docs: distribution par plugin (état cible) + règle mode Coolify\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 7: CHECKPOINT humain — validation env cloud

Gate avant le Plan 2 (rollout repos d'app). **Ne pas démarrer le Plan 2 tant que ce checkpoint n'est pas vert.**

**Files:** aucun.

- [ ] **Step 1: Pousser `avqn-dev`**

```bash
cd ~/avqn-dev && git push origin main
```

- [ ] **Step 2: Valider l'install du plugin privé sur l'env cloud**

Faire tourner le script `env/avqn-dev-env-setup.sh` sur l'environnement cloud réel (routine ou env interactif). Vérifier « plugin avqn-dev OK ». **Si KO (auth repo privé)** → appliquer un repli documenté (clone local dans le script + `marketplace add <path>`, ou garder multi-source pour la routine) et le noter.

- [ ] **Step 3: Prouver un cycle INTERACTIF de bout en bout**

Dans une session interactive sur un repo d'app (sans skills méthodo vendorisées retirées — encore présentes, OK), lancer une micro-tâche : brainstorm live → cœur → PR → CI → FF → **preview qui répond 200**. Confirmer que les skills viennent du plugin.

- [ ] **Step 4: Prouver un cycle ROUTINE de bout en bout**

Sur une issue `ready` de test, laisser la routine dérouler `dev` jusqu'à une **preview réelle**. Confirmer.

- [ ] **Step 5: Verdict**

Écrire le verdict du checkpoint (OK/KO + détails) ici. Si OK → écrire le Plan 2 (rollout chantiers 2–5). Si KO → replanifier la distribution.

---

## Self-Review

**Spec coverage :**
- Chantier 1 « Plugin + refactor dev » → Tasks 1–6 + checkpoint Task 7. ✓
- Le MCP Playwright (spec §2) → conservé via script d'env (Task 5), conforme au défaut décidé. ✓
- Règle Coolify mode (spec §5) documentée → Task 6 Step 2 (les éditions de workflows des repos d'app sont au Plan 2). ✓
- Chantiers 2 (repos d'app), 4 (legacy), 6 (routine sources) → explicitement **Plan 2**, après checkpoint. Cohérent avec la spec (« ne supprimer du repo qu'après preuve »). ✓

**Placeholder scan :** aucun TODO/TBD ; chaque step porte un contenu réel (json, markdown, commandes). Les éditions de docs (Task 6) décrivent le contenu cible précis sans copier 200 lignes — acceptable car réécriture de prose existante guidée.

**Type consistency :** noms de skills (`dev`, `apercu`, `brainstorm-issue`), commandes (`claude plugin validate|install|details|marketplace add`), nom de plugin/marketplace (`avqn-dev@avqn-dev`) cohérents d'une task à l'autre. ✓

**Risque porté :** layout `skills/` (Task 1) dé-risqué par la preuve d'install locale (Task 3) avant tout investissement aval ; install repo privé sur cloud dé-risquée au checkpoint (Task 7) avec repli.
