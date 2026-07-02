# AVQN — Méthodologie de dev continu & déploiement (conception)

État cible. Décrit le système tel qu'il doit être, pas l'historique.

## 1. Principes

- **Le minimum de gestes humains, le reste autonome.** Deux points de contrôle humains possibles, selon le contexte : approuver une issue (label `ready`) — l'aval qui alimente la **routine** autonome ; et **promouvoir** une preview en prod — le geste 2, **présent uniquement en double-palier** (§6). En mono-palier, le push `main` va droit en prod : il n'y a pas de geste 2. Tout ce qui n'est pas un de ces points est automatique.
- **Le palier est un choix par repo, facile à faire évoluer.** Un projet démarre souvent en **mono-palier** (droit en prod, pour itérer vite sans clients) et passe **double-palier** (preview + promote) quand il gagne des clients. Le partagé ne bouge pas ; seul le `ci.yml` du repo et ses coordonnées changent (§6).
- **L'issue GitHub est la colonne vertébrale du dev autonome.** En routine, le brainstorm s'y dépose, le label `ready` est l'aval, le dev la consomme. En interactif, le travail peut partir d'une simple conversation (issue facultative).
- **Deux modes, un cœur.** Le même cœur d'implémentation (jusqu'au FF merge `main`) est partagé par le mode **interactif** (l'humain au clavier) et le mode **routine** (autonome) ; ils ne diffèrent que par leur amorce.
- **Le commun est partagé sans être cloné.** La méthodo (skills) et la mécanique de déploiement (reusable workflows) vivent une seule fois dans un backbone. Les skills se distribuent via un **plugin user-scope** (`avqn-dev`, marketplace auto-hébergée) ; les workflows par `uses:`. Les repos d'app restent propres.
- **Hétérogénéité dans les repos, simplicité dans le partagé.** Le build/test (Astro/Next/nginx/docker…) vit dans chaque repo. Le partagé ne contient que ce qui est *réellement* identique partout.
- **Qualité avant la PR.** Rien ne part en PR qui ne soit testé ET, pour le front, visuellement validé — en local, jamais en preview.

## 2. Deux modes, un cœur

Le même **cœur d'implémentation** est porté par deux amorces. Les deux s'arrêtent au **FF merge `main`** ; ce merge déclenche le deploy du repo, dont la cible dépend du **palier** (§6).

```
INTERACTIF (humain au clavier)            ROUTINE (autonome, horaire)
conversation                              issue `label=ready`          ← GATE 1
   │ brainstorm live (superpowers)           │  (l'humain a posé `ready`)
   ▼                                          ▼
   └────────────────►  CŒUR  ◄────────────────┘
   plan → TDD → apercu → gate → auto-review → PR → CI → FF merge `main`
                            │
                            ▼
            le ci.yml du repo déploie — selon le PALIER (§6) :
             • mono-palier   → prod directement (pas de gate 2)
             • double-palier → preview, puis l'humain promote → prod  ← GATE 2
```

L'issue est **facultative** en interactif (l'humain est l'aval, en continu) et **obligatoire** en routine (elle EST la spec). Une voie interactive distincte — `/brainstorm-issue` — sert à *préparer* une issue `ready` que la routine prendra plus tard.

## 3. Préparer une issue `ready` — `/brainstorm-issue` (interactif)

Pour alimenter la routine en travail validé. Wrapper mince autour de `superpowers:brainstorming` ; seule différence : la destination du design.

- Prend une issue brute (ou une idée → crée l'issue).
- Déroule le brainstorm superpowers avec l'humain (exploration, options, design).
- À l'étape « écrire le design », **écrit la spec dans le corps de l'issue** (pas dans `docs/specs`) — une **spec d'intention** : le *quoi* et le *pourquoi*, pas le plan d'implémentation.
- **S'arrête là** (ne code pas). Le label `ready`, posé par l'humain (async), est l'aval ; la routine implémente ensuite.

> À ne pas confondre avec le **mode interactif de `/dev`** (§4), où l'humain reste au clavier et va jusqu'au FF merge `main` dans la même session.

## 4. Le cœur + les deux amorces — `/dev`

Wrapper d'orchestration autour de superpowers. Un **cœur** commun, deux **amorces** :

- **Amorce interactive** (humain au clavier) : part d'une **conversation**, brainstorme en live (`superpowers:brainstorming`), puis déroule le cœur jusqu'au FF merge `main`. Issue facultative ; pas de gate `ready` (l'humain est l'aval, en continu).
- **Amorce routine** (autonome, horaire) : par repo, la plus ancienne issue ouverte `label=ready` sans PR liée ni `in-progress` — une par repo par run. **Sans re-brainstormer** (l'issue `ready` EST la spec).

Le **cœur** (identique aux deux) :

```
1. branche depuis `origin/main` (en routine : claim `in-progress` sur l'issue d'abord)
2. writing-plans à partir de la **spec** (issue `ready` en routine ; design validé en conversation en interactif), puis TDD (superpowers:test-driven-development)
3. BOUCLE QUALITÉ VISUELLE LOCALE  — si le repo a une UI ET que la tâche touche le front :
     - build + lance l'app en local (comme pour le e2e)
     - captures Playwright (MCP) aux breakpoints déclarés
     - JUGE le rendu contre : la spec + la charte du projet
     - pas satisfait → améliore le code → re-teste
     - recommence jusqu'à un rendu de qualité, plafond d'itérations (garde-fou)
     - au plafond sans convergence → s'arrête, met de côté (commente l'issue en routine ; questionne l'humain en interactif)
4. gate complète locale (lint/format/typecheck/test/e2e/build) — exactement ce que la CI rejoue
5. auto-review adversariale (sous-agent à contexte frais) → corrige
6. commit + rebase sur origin/main + PR (`Closes #n` si une issue existe)   ← la PR ne sort QUE si 2→5 sont verts
7. gate CI sur la branche (dispatch ci.yml via MCP GitHub, suivi jusqu'à completed)
8. vert → FF merge sur main → le ci.yml du repo déploie (sans rebuild) : PREVIEW en double-palier, PROD en mono-palier (§6)
```

Garde-fous communs : jamais de promote ni d'appel Coolify direct par `/dev` (le deploy est fait par le `ci.yml` du repo au push `main`) ; jamais merge sur CI rouge ; rebase avant FF ; gate locale complète + qualité visuelle avant de pousser. Conflit / CI rouge → mise de côté. **Routine seulement** : uniquement `ready` ; une issue par repo par run ; ambiguïté → commente l'issue + retire `in-progress`.

La boucle visuelle est **une couche au-dessus du e2e** : l'app sait déjà se lancer pour ses tests. Repos sans front, ou tâches qui ne touchent pas le front → la boucle est sautée.

## 5. Contrat par repo (déclaré dans le `CLAUDE.md` du repo)

Le `/dev` partagé est générique ; chaque repo déclare ses spécificités :

- **commande de gate** (ex. `npm run gate`) — ce que la CI rejoue.
- **a-t-il une UI ?** + **commande pour lancer l'app en local** + **URL** + **pages/routes à screenshoter** + **breakpoints** (sinon défaut 390/768/1440).
- **services requis** pour tourner en local (Postgres/Redis…).
- **versioning** (bump ou non).
- **palier** : `mono` (deploy → prod, pas de `promote.yml`) ou `double` (deploy → preview + `promote.yml` → prod) — cf. §6.
- **mode Coolify** : `service` (compose) ou `application` (image docker) — orthogonal au palier, passé au reusable workflow.
- **coordonnées Coolify** — selon le palier : mono → **un** UUID (prod) + son URL de health ; double → **deux** UUID (preview, prod) + health. Consommées par `ci.yml`/`promote.yml`, pas par `/dev`.

## 6. Palier, deploy & promote

Chaque repo choisit sa **topologie de palier**. C'est un choix par repo, **fait pour évoluer facilement** (§6.3).

### 6.1 Deux paliers

- **Mono-palier** — un seul environnement (prod). Le push `main` déploie **la prod** directement ; pas de preview, pas de `promote.yml`. Pour un projet jeune, sans clients : on itère vite, droit en prod. En routine autonome, ce déploiement prod est **assumé sans supervision** (le contrôle est le registre `projects.txt` : on n'y met un repo que quand on l'assume). C'est le cas d'`avqn-infra`.
- **Double-palier** — deux environnements. Le push `main` déploie la **preview** ; un **promote** manuel reporte le sha validé preview → prod (le geste humain 2). Pour un projet avec des clients, où la prod se protège derrière une preview.

Vocabulaire figé (`deploy` existe dans les deux paliers, seule sa cible change) :

| Terme | Cible | Déclenchement | Geste | Palier |
|---|---|---|---|---|
| **deploy** | mono → **prod** ; double → **preview** | automatique au push `main` (`ci.yml` du repo) | machine | les deux |
| **promote** | **prod** | manuel (`promote.yml`, sur aval) | humain (gate 2) | double seulement |

### 6.2 Mécanique commune

Identique partout, donc factorisée : image immuable `sha-<commit>` déjà construite+testée sur la branche ; Coolify ne build jamais ; on repointe le tag d'image de la cible + on déclenche + health-check.
- **deploy** = repointer le service **cible du push** (prod en mono, preview en double) sur le sha mergé.
- **promote** (double seulement) = lire le sha en preview (vérité validée) → repointer le service prod.

`mode:` (ressource Coolify) est **orthogonal au palier**, passé explicitement par chaque repo : `service` (compose, PATCH `IMAGE_TAG`) ou `application` (image docker, PATCH `docker_registry_image_tag`).

### 6.3 Changer un repo de palier

Un repo commence souvent **mono** (droit en prod) et passe **double** quand il gagne des clients. Le partagé ne bouge pas ; seuls le `ci.yml` du repo, ses coordonnées et son contrat (§5) changent.

**Mono → double** (insérer une preview devant la prod) :
1. Créer le **service preview** dans Coolify (même image GHCR, domaine + base dédiés preview) → noter son UUID + son URL de health.
2. Dans le job `deploy` du `ci.yml` : pointer `uuid`/`health_url` sur le **preview** neuf (la prod existante n'est plus la cible du push `main`).
3. Ajouter `promote.yml` : `preview_uuid` = le preview neuf, `prod_uuid` = la prod existante.
4. Mettre à jour le contrat §5 du `CLAUDE.md` (palier `double`, les deux UUID).

**Double → mono** (retirer la preview) : pointer le job `deploy` sur la **prod**, supprimer `promote.yml`, mettre à jour le contrat (le service preview peut être supprimé). Le push `main` déploie alors la prod.

## 7. Reusable workflows (la factorisation)

Un workflow partagé **fin**, qui ne contient que la grammaire Coolify (réellement identique). La typologie de projet (build/test) n'y est jamais — elle reste dans le `ci.yml` de chaque repo. Entrées = **coordonnées** (où déployer), pas options de comportement.

- `avqn-dev/.github/workflows/deploy.yml@v1` — inputs : `uuid`, `health_url`, `image_tag`, `mode` (`service`|`application`, défaut `service`) ; secret : `coolify_token`. → repointe le service/application cible sur le sha, déclenche, health-check.
- `avqn-dev/.github/workflows/promote.yml@v1` — inputs : `preview_uuid`, `prod_uuid`, `health_url`, `mode` ; secret : `coolify_token`. → lit le sha preview, repointe prod, health-check.

Dans chaque repo :
- `ci.yml` : `prep` + `build` + `test` (hétérogènes, locaux) + un job final `deploy: uses: manu-bernard/avqn-dev/.github/workflows/deploy.yml@v1` avec ses coordonnées (`uuid` = la cible du push `main` : prod en mono-palier, preview en double-palier).
- `promote.yml` : une ligne `uses: …/promote.yml@v1` avec ses coordonnées — **double-palier seulement**.

Le reusable workflow est **résolu par GitHub au CI, jamais cloné** — donc rien à ajouter aux environnements/routines. **Brancher un nouveau projet** = écrire son `ci.yml` (build/test) + le job `deploy` (coordonnées) ; en double-palier, ajouter `promote.yml`. Zéro modif du partagé.

`avqn-dev` est **public** : ses reusable workflows sont appelables par les autres repos sans réglage d'autorisation.

## 8. Le backbone `avqn-dev`

Repo **public**, deux rôles, **jamais attaché en source** :

1. **Plugin user-scope** (`skills/` + `.claude-plugin/{plugin.json,marketplace.json}`) : superpowers vendorisées (TDD, systematic-debugging, verification, code-review…) + les wrappers `brainstorm-issue`, `dev`, `apercu` (l'œil visuel Playwright). Installé en scope user par le script de config de l'env → **auto-enabled dans chaque session de chaque repo**, interactif comme routine. Les repos d'app ne portent **aucune** méthodo.
2. **Reusable workflows** `deploy.yml` / `promote.yml` (§7), référencés par `uses:`.

## 9. Recette de l'environnement cloud

Prouvée (voir mémoire `recette-routine-cloud-superpowers-playwright`).

- **Plugin avqn-dev** : installé par le **script de config de l'env** `env/avqn-dev-env-setup.sh`, **avant la session** (un plugin se charge au démarrage de session, pas en cours de run). Scope user = auto-enabled sans aucune config par repo.
- **Fetch du plugin (via tarball, pas git)** : dans le sandbox, git est proxifié aux sources — tout `git clone` hors-source renvoie 403, **public ou privé**. Le proxy ne touche que git ; HTTP sort librement. On récupère donc le repo **public** `avqn-dev` en **tarball curl** (`…/archive/refs/heads/main.tar.gz`), on extrait, puis `claude plugin marketplace add <dossier local>` + `install --scope user`. Marche **sans qu'avqn-dev soit une source** → un seul repo ouvert. Le repo **doit être public** (curl sans auth). Script blindé au paste : pas de commentaire, pas de pipe, URL en variable.
- **Permissions** : `.claude/settings.json` dans les repos d'app → `{"permissions":{"defaultMode":"bypassPermissions"}}`. Aucun prompt.
- **MCP Playwright** : enregistré par le même script de config : `claude mcp add playwright --scope user -- npx -y @playwright/mcp@latest --headless --isolated --no-sandbox --browser chromium --executable-path /opt/pw-browsers/chromium`. Chromium est déjà dans l'image. `file://` bloqué → servir en `localhost`.

## 10. La routine de dev (cloud, horaire)

- **Sources** : les repos d'app uniquement (clones de travail). `avqn-dev` n'est **pas** une source — le plugin est récupéré en tarball par le script de config (cf. §9), donc rien à attacher.
- **Env** : `env/avqn-dev-env-setup.sh` (installe le plugin avqn-dev avant la session + MCP Playwright).
- **Prompt minimal** : « déroule `/dev` sur les repos d'app sources ». La procédure vit dans le skill `/dev` du plugin, pas dans le prompt. Itère les repos d'app du registre `projects.txt`.

## 11. Legacy à tuer

- Routine **« Recette quotidienne »** (modèle centralisé `projects/*.json` + `build.yml`/`deploy.yml` dispatché — subsumé par `/dev`).
- Routine **« Multi-source probe »** (debug).
- Repo `avqn-deploy` : pièces utiles migrées vers `avqn-dev`, le reste archivé/supprimé (`projects.txt`, modèle recette centralisé).
- Reliquats `avqn-workspace`.
