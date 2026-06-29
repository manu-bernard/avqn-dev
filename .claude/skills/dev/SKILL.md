---
name: dev
description: Développement continu autonome — prend une issue VALIDÉE (label ready) d'un repo, l'implémente en TDD avec boucle qualité visuelle locale, gate via la CI sur la branche, puis merge en fast-forward sur main (ce qui déclenche le deploy preview). Orchestrateur des skills superpowers, sans brainstorm (l'issue ready EST la spec). Multi-repos, en boucle horaire.
---

# Dev

Tu prends du travail **validé** (`label=ready`), tu le **codes en TDD**, tu le rends **beau et testé en local**, puis tu le **merges** sur `main` quand la CI est verte. Le merge déclenche tout seul le **deploy preview** (le `ci.yml` du repo). Tu ne déploies **rien** toi-même, **jamais** la prod.

Tu es un **chef d'orchestre** : la discipline vient des skills superpowers (TDD, debugging, review, verification). L'issue `ready` **est** la spec — tu ne brainstormes **jamais**.

## Environnement (routine cloud)
Sources clonées localement : ce repo `avqn-dev` (skills) + les repos d'app. Tu as un vrai env de dev (git, npm/pnpm, tests). Tu travailles dans le clone local du repo cible.

**Opérations GitHub → serveur MCP GitHub** (charge ses tools via ToolSearch). En particulier les **Actions** (dispatch de `ci.yml` + suivi des runs) renvoient 403 avec `gh` dans le sandbox → **obligatoirement via le MCP**. Issues/labels/PR : MCP préféré, `gh api` (REST) en fallback — **jamais** les sous-commandes `gh issue/pr` (GraphQL bloqué). Le git (branche/commit/push/FF) passe par le proxy des clones, sans token.

## Le gate d'entrée : SEULEMENT les issues `ready`
Tu ne touches **que** les issues ouvertes `label=ready`. Une issue sans `ready` = proposition non validée → ignore.

## Boucle (par repo d'app)

1. **Trouver le travail** : la plus ancienne issue ouverte `label=ready`, sans `pull_request`, sans `in-progress`, sans PR ouverte qui la référence. **Une** issue par repo par run.
2. **Claim** : pose `in-progress` sur l'issue.
3. **Brancher** : `cd ~/<repo>`, `git fetch origin`, `git checkout -b dev/issue-<n>-<slug> origin/main`. Lis le **`CLAUDE.md` du repo** (il fait foi : stack, gate, run, UI, versioning, coordonnées).
4. **Planifier + coder en TDD** : déroule `superpowers:writing-plans` à partir de l'issue (= la spec d'intention), puis `superpowers:test-driven-development` (test rouge → code → vert). Changement minimal et ciblé. Bug en cours de route → `superpowers:systematic-debugging`. Issue ambiguë/trop grosse → ne devine pas : commente l'issue (clarification), retire `in-progress`, repo suivant.
5. **Boucle qualité visuelle locale** — applique le skill **`apercu`** SI le repo a une UI (déclaré dans son `CLAUDE.md`) ET que la tâche touche le front. `apercu` boote l'app en local, capture aux breakpoints, juge le rendu (contre l'issue + la charte), et te fait **améliorer jusqu'à un résultat de qualité** (plafond d'itérations). Repo sans front / tâche backend → saute cette étape.
6. **Gate complète locale** : `npm ci` (ou équivalent), puis **la commande de gate du `CLAUDE.md`** (lint/format/typecheck/test/e2e/build — exactement ce que la CI rejoue). **Corrige jusqu'au vert.** N'ouvre pas une PR que la CI rejettera.
7. **Auto-review adversariale** : `superpowers:requesting-code-review` (sous-agent à contexte frais, impitoyable). Applique les corrections réelles.
8. **Commit + rebase + PR** (la PR ne sort QUE si 5→7 sont au vert) :
   - `git commit -am "<msg descriptif 🤖>"` ; bump de version si le repo en a un (cf. son `CLAUDE.md`).
   - `git rebase origin/main`. Conflit non trivial → `git rebase --abort`, commente l'issue, retire `in-progress`, repo suivant.
   - `git push -u origin dev/issue-<n>-<slug>` (`--force-with-lease` si rebasé).
   - Ouvre la PR (MCP GitHub ; `Closes #<n>` ; corps = quoi/pourquoi/comment vérifier).
9. **Gate via la CI sur la branche (MCP GitHub)** : dispatche `ci.yml` sur ta branche via le **MCP** (`actions_run_trigger`/`run_workflow`, `ref=<branche>`), suis le run jusqu'à `completed`.
   - **Rouge** → ne merge pas. Laisse la PR, commente l'issue (CI rouge + lien run), retire `in-progress`. Repo suivant.
   - **Vert** → étape 10.
10. **Merge fast-forward sur `main`** :
    - `git checkout main && git pull --ff-only origin main`.
    - `git merge --ff-only dev/issue-<n>-<slug>` puis `git push origin main`.
    - Push rejeté (la base a bougé) → re-`checkout` la branche, rebase, `push --force-with-lease`, **re-gate** (étape 9), retry. (Rare.)
    - Le push sur `main` déclenche le `ci.yml` du repo : l'image `sha-<commit>` existe déjà (gatée sur la branche) → il **déploie la preview sans rebuild**. Tu ne dispatches rien.
11. **Clôturer** : le `Closes #<n>` ferme l'issue. Vérifie la PR ; si encore `open`, ferme-la avec un commentaire « mergée en fast-forward ». Retire `in-progress` si présent.
12. **Bilan** par repo : issue → PR mergée (main @ sha) + « preview en déploiement », ou « CI rouge » / « rien de ready » / « clarification ».

## Garde-fous
- **Seulement `ready`** ; **une issue par repo par run** ; **changement minimal** ; **jamais deviner** (ambiguïté/conflit → mise de côté + commentaire).
- **Tu merges (FF) sur `main`, jamais plus** : **jamais** de promotion prod, **jamais** d'appel Coolify ni de dispatch de workflow de déploiement (le deploy preview est porté par le `ci.yml` du repo sur push `main`).
- **Jamais merge sur CI rouge** ; **rebase avant le FF** (FF strict).
- **Gate complète locale + qualité visuelle AVANT la PR.**
- **Auto-review obligatoire** ; **Actions via le MCP GitHub** (pas `gh`).
- `superpowers:verification-before-completion` avant de déclarer une issue faite.
