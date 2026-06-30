---
name: dev
description: Développe une tâche jusqu'à la PREVIEW (jamais la prod), via un cœur commun — plan → TDD → qualité visuelle locale (apercu) → gate locale → auto-review → PR → gate CI sur la branche → FF merge main (déclenche le deploy preview). Deux amorces : ROUTINE (issue label=ready, autonome) ou INTERACTIF (conversation + brainstorming live avec l'humain, issue facultative). Orchestrateur des skills superpowers.
---

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

## Amorce routine (autonome, horaire)

Sans humain. La spec **est** une issue `label=ready` — tu ne brainstormes jamais.

- **Environnement** : repos d'app clonés en sources ; le plugin `avqn-dev` fournit la méthodo. Opérations GitHub via le **MCP GitHub** (Actions en 403 avec `gh` dans le sandbox) ; git via le proxy des clones.
- **Gate d'entrée** : seulement les issues ouvertes `label=ready`. Pas de `ready` = ignore.
- **Sélection** : la plus ancienne issue `ready`, sans `pull_request`, sans `in-progress`, sans PR liée. **Une** par repo par run.
- **Claim** : pose `in-progress` sur l'issue.
- **Brancher** : `git fetch origin && git checkout -b dev/issue-<n>-<slug> origin/main`. Lis le `CLAUDE.md` du repo (contrat).
- **→ Déroule le cœur** (spec = corps de l'issue). Issue ambiguë/trop grosse → ne devine pas : commente, retire `in-progress`, repo suivant.

## Amorce interactive (humain au clavier)

Avec l'humain, dans un seul repo. La spec naît de la **conversation**.

- **Cadrage** : `superpowers:brainstorming` en live (questions, options, design validé). Respecte sa discipline : pas de code avant accord sur le design.
- **Issue facultative** : tu peux ouvrir une issue pour tracer (et la `Closes` à la PR), mais ce n'est pas requis — l'humain est l'aval, en continu. Pas de gate `ready`.
- **Brancher** : `git fetch origin && git checkout -b <type>/<slug> origin/main`. Lis le `CLAUDE.md` du repo (contrat).
- **→ Déroule le cœur** (spec = le design validé en conversation). Tu vas **jusqu'à la preview** ; tu t'arrêtes avant la prod (promote = geste humain).

## Garde-fous
- **Changement minimal** ; **jamais deviner** (ambiguïté/conflit → mise de côté + commentaire en routine ; question à l'humain en interactif).
- **Tu vas jusqu'au FF sur `main`, jamais plus** : jamais de promo prod, jamais d'appel Coolify ni de dispatch de workflow de déploiement.
- **Jamais merge sur CI rouge** ; **rebase avant le FF**.
- **Gate locale complète + qualité visuelle AVANT la PR** ; **auto-review obligatoire** ; **Actions via le MCP GitHub** ; `verification-before-completion` avant de déclarer fait.
- Routine : **seulement `ready`**, **une issue par repo par run**.
