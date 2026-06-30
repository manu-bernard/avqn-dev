# AVQN — Méthodologie de dev continu & déploiement (conception)

État cible. Décrit le système tel qu'il doit être, pas l'historique.

## 1. Principes

- **Deux gestes humains, le reste autonome.** (1) approuver une issue (label `ready`) ; (2) promouvoir une preview en prod. Tout ce qui est entre les deux est automatique.
- **L'issue GitHub est la colonne vertébrale.** Le brainstorm s'y dépose ; le label `ready` est l'aval ; le dev la consomme.
- **Le commun est partagé sans être cloné.** La méthodo (skills) et la mécanique de déploiement (reusable workflows) vivent une seule fois dans un backbone. Les skills se distribuent via un **plugin user-scope** (`avqn-dev`, marketplace auto-hébergée) ; les workflows par `uses:`. Les repos d'app restent propres.
- **Hétérogénéité dans les repos, simplicité dans le partagé.** Le build/test (Astro/Next/nginx/docker…) vit dans chaque repo. Le partagé ne contient que ce qui est *réellement* identique partout.
- **Qualité avant la PR.** Rien ne part en PR qui ne soit testé ET, pour le front, visuellement validé — en local, jamais en preview.

## 2. Cycle de vie d'une issue

```
issue brute / non validée
        │  PHASE 1 — /brainstorm-issue   (interactif, avec l'humain)
        ▼
issue enrichie d'une SPEC D'INTENTION (le quoi/pourquoi)
        │  l'humain pose le label `ready`            ← GATE 1
        ▼
issue `ready`
        │  PHASE 2 — /dev                (autonome, horaire)
        ▼
PR mergée en FF sur main → deploy preview automatique
        │  l'humain review la preview → promote      ← GATE 2
        ▼
prod
```

## 3. Phase 1 — `/brainstorm-issue` (interactif)

Wrapper mince autour de `superpowers:brainstorming`. Différence unique : la destination du design.

- Prend une issue brute (ou une idée → crée l'issue).
- Déroule le brainstorm superpowers avec l'humain (exploration, options, design).
- À l'étape « écrire le design », **écrit la spec dans le corps de l'issue** (pas dans `docs/specs`) — une **spec d'intention** : le *quoi* et le *pourquoi*, pas le plan d'implémentation.
- **S'arrête là.** Ne passe pas à l'implémentation. Le label `ready`, posé par l'humain (async), est l'aval.

> Évolution future possible (hors périmètre) : un second skill qui produit aussi le *plan* dans l'issue, et un `/dev` qui s'adapte selon que le plan est présent ou non. Pour l'instant : issue = spec d'intention, `/dev` planifie lui-même.

## 4. Phase 2 — `/dev` (autonome, horaire)

Par repo du registre, la plus ancienne issue ouverte `label=ready` sans PR liée ni `in-progress`. Une par repo par run. Wrapper d'orchestration autour de superpowers, **sans re-brainstormer** (l'issue `ready` EST la spec).

```
1. claim (in-progress) ; branche depuis origin/main
2. writing-plans à partir de l'issue, puis TDD (superpowers:test-driven-development)
3. BOUCLE QUALITÉ VISUELLE LOCALE  — si le repo a une UI ET que la tâche touche le front :
     - build + lance l'app en local (comme pour le e2e)
     - captures Playwright (MCP) aux breakpoints déclarés
     - JUGE le rendu contre : la description de l'issue + la charte du projet
     - pas satisfait → améliore le code → re-teste
     - recommence jusqu'à un rendu de qualité, plafond d'itérations (garde-fou)
     - au plafond sans convergence → s'arrête, commente l'issue, met de côté
4. gate complète locale (lint/format/typecheck/test/e2e/build) — exactement ce que la CI rejoue
5. auto-review adversariale (sous-agent à contexte frais) → corrige
6. commit + rebase sur origin/main + PR (Closes #n)   ← la PR ne sort QUE si 2→5 sont verts
7. gate CI sur la branche (dispatch ci.yml via MCP GitHub, suivi jusqu'à completed)
8. vert → FF merge sur main → le ci.yml du repo déploie la PREVIEW (sans rebuild)
```

Garde-fous : seulement `ready` ; une issue par repo par run ; jamais promo prod ni Coolify direct ; jamais merge sur CI rouge ; rebase avant FF ; gate locale complète avant de pousser. Issue floue / conflit / CI rouge → mise de côté + commentaire + retire `in-progress`.

La boucle visuelle est **une couche au-dessus du e2e** : l'app sait déjà se lancer pour ses tests. Repos sans front, ou tâches qui ne touchent pas le front → la boucle est sautée.

## 5. Contrat par repo (déclaré dans le `CLAUDE.md` du repo)

Le `/dev` partagé est générique ; chaque repo déclare ses spécificités :

- **commande de gate** (ex. `npm run gate`) — ce que la CI rejoue.
- **a-t-il une UI ?** + **commande pour lancer l'app en local** + **URL** + **pages/routes à screenshoter** + **breakpoints** (sinon défaut 390/768/1440).
- **services requis** pour tourner en local (Postgres/Redis…).
- **versioning** (bump ou non).
- **coordonnées Coolify** (UUID service preview, UUID service prod, URL de health) — consommées par le `ci.yml`/`promote.yml`, pas par `/dev`.

## 6. deploy & promote

Vocabulaire figé :

| Terme | Cible | Déclenchement | Geste |
|---|---|---|---|
| **deploy** | environnement **preview** | automatique au push `main` (ci.yml du repo) | machine |
| **promote** | environnement **prod** | manuel (`promote.yml`, sur aval) | humain (gate 2) |

Mécanique commune (identique partout, donc factorisée) : image immuable `sha-<commit>` déjà construite+testée sur la branche ; Coolify ne build jamais ; on repointe `IMAGE_TAG` du service + on déclenche + health-check.
- **deploy** = repointer le service *preview* sur le sha mergé.
- **promote** = lire le sha en *preview* (vérité validée) → repointer le service *prod*.

`mode:` est passé explicitement par chaque repo. Multi-process → `service` (PATCH `IMAGE_TAG`) ; mono-process → `application` (PATCH `docker_registry_image_tag`).

## 7. Reusable workflows (la factorisation)

Un workflow partagé **fin**, qui ne contient que la grammaire Coolify (réellement identique). La typologie de projet (build/test) n'y est jamais — elle reste dans le `ci.yml` de chaque repo. Entrées = **coordonnées** (où déployer), pas options de comportement.

- `avqn-dev/.github/workflows/deploy.yml@v1` — inputs : `service_uuid`, `health_url`, `image_tag` ; secret : `COOLIFY_TOKEN`. → repointe le service preview, déclenche, health-check.
- `avqn-dev/.github/workflows/promote.yml@v1` — inputs : `preview_uuid`, `prod_uuid`, `health_url`. → lit le sha preview, repointe prod, health-check.

Dans chaque repo :
- `ci.yml` : `prep` + `build` + `test` (hétérogènes, locaux) + un job final `deploy: uses: manu-bernard/avqn-dev/.github/workflows/deploy.yml@v1` avec ses 3 coordonnées.
- `promote.yml` : une ligne `uses: …/promote.yml@v1` avec ses coordonnées.

Le reusable workflow est **résolu par GitHub au CI, jamais cloné** — donc rien à ajouter aux environnements/routines. **Brancher un nouveau projet** = écrire son `ci.yml` (build/test) + le job `deploy` (3 coordonnées) + `promote.yml`. Zéro modif du partagé.

Config requise (une fois) : `avqn-dev` étant privé, autoriser ses workflows à être appelés par les autres repos du compte (Settings → Actions).

## 8. Le backbone `avqn-dev`

Un repo, deux rôles, **jamais cloné en dev** :

1. **Plugin user-scope** (`skills/` + `.claude-plugin/{plugin.json,marketplace.json}`) : superpowers vendorisées (TDD, systematic-debugging, verification, code-review…) + les wrappers `brainstorm-issue`, `dev`, `apercu` (l'œil visuel Playwright). Installé via la marketplace auto-hébergée (`manu-bernard/avqn-dev`) en scope user → **auto-enabled dans chaque session de chaque repo**, interactif comme routine. Les repos d'app ne portent **aucune** méthodo.
2. **Reusable workflows** `deploy.yml` / `promote.yml` (§7), référencés par `uses:`.

## 9. Recette de l'environnement cloud

Prouvée (voir mémoire `recette-routine-cloud-superpowers-playwright`).

- **Plugin avqn-dev** : installé via `env/avqn-dev-env-setup.sh` (marketplace add + `claude plugin install avqn-dev@avqn-dev --scope user`). Scope user = auto-enabled sans aucune config par repo. Repo privé → l'env doit être authentifié GitHub.
- **Permissions** : `.claude/settings.json` dans les repos d'app → `{"permissions":{"defaultMode":"bypassPermissions"}}`. Aucun prompt.
- **MCP Playwright** : enregistré par le même script de config : `claude mcp add playwright --scope user -- npx -y @playwright/mcp@latest --headless --isolated --no-sandbox --browser chromium --executable-path /opt/pw-browsers/chromium`. Chromium est déjà dans l'image. `file://` bloqué → servir en `localhost`.

## 10. La routine de dev (cloud, horaire)

- **Sources** : les repos d'app uniquement (clones de travail). `avqn-dev` n'est **pas** une source — ses skills sont disponibles via le plugin user-scope installé par le script de config.
- **Env** : `avqn-dev` avec `env/avqn-dev-env-setup.sh` (plugin avqn-dev + MCP Playwright).
- **Prompt minimal** (~3 lignes) : « déroule `/dev` sur les repos d'app sources ». La procédure vit dans le skill `/dev` du plugin, pas dans le prompt.

## 11. Legacy à tuer

- Routine **« Recette quotidienne »** (modèle centralisé `projects/*.json` + `build.yml`/`deploy.yml` dispatché — subsumé par `/dev`).
- Routine **« Multi-source probe »** (debug).
- Repo `avqn-deploy` : pièces utiles migrées vers `avqn-dev`, le reste archivé/supprimé (`projects.txt`, modèle recette centralisé).
- Reliquats `avqn-workspace`.

## 12. Phases d'implémentation

1. **Backbone** : créer `avqn-dev` ; vendoriser les skills superpowers ; écrire `brainstorm-issue`, `dev`, `apercu` ; `settings.json`.
2. **Reusable workflows** : `deploy.yml` + `promote.yml` dans `avqn-dev` ; autoriser l'appel inter-repos.
3. **Repo pilote** : migrer UN repo (ci.yml → `uses:` deploy ; promote.yml ; contrat CLAUDE.md). **Valider un deploy + un promote réels** avant d'aller plus loin.
4. **Rollout** : appliquer aux 4 autres repos.
5. **Routine** : recréer la routine de dev (sources, env 1-ligne, prompt minimal) ; brancher la boucle visuelle.
6. **Cleanup** : tuer le legacy (§11).

Checkpoint humain après la phase 3 (premier deploy/promote réels) avant le rollout.
