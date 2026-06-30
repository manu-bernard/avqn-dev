# Homogénéisation de l'écosystème de dev AVQN — design

État cible. Décrit le système tel qu'il doit être après ce chantier.

## Problème

Le backbone `avqn-dev` (skills + reusable workflows) est mûr, mais l'écosystème autour est hétérogène :

- La méthodologie partagée se distribue par **agrégation multi-source** — un mécanisme propre à la **routine** cloud. En **interactif** (un seul repo ouvert), les skills d'`avqn-dev` ne se chargent pas : les repos qui « marchent seuls » ont **vendorisé** une copie locale, et ces copies ont **divergé** (`/apercu` existe en deux versions incompatibles dans `contentos` et `avqn-os`).
- Le modèle de dev n'est pas le même partout : la plupart des repos sont au **drive-to-main** (FF merge → preview), mais `avqn-os` porte encore « tu ouvres la PR et tu t'arrêtes là », et un design doc périmé de `contentos` décrit un schéma « agent recette » abandonné.
- Des reliquats traînent : repo `render-farm` standalone (doublon mort, **collision d'UUID Coolify** avec `apps/render-farm` du monorepo), clone local `avqn-deploy` (archivé sur GitHub), `publishConfig` GH Packages orphelin sur `video-spec`.
- La modélisation Coolify (`application` vs `service`) est correcte mais le paramètre `mode` est passé de façon **implicite** par endroits — illisible.

## Principe directeur

**Un seul repo ouvert quand on travaille.** Le commun (méthodo) se charge **dynamiquement** comme un package, jamais provisionné à la main session par session. Les deux modes de dev — interactif (humain) et routine (autonome) — partagent **le même cœur** et ne diffèrent que par leur **amorce**.

## 1. Deux modes, un cœur commun

Le **cœur d'implémentation** (identique aux deux modes), porté par le skill `dev` du plugin :

```
plan → TDD → apercu (si UI) → gate locale → auto-review →
commit + rebase → PR → gate CI sur la branche → FF merge main → deploy preview
```

Jamais la prod. Le promote prod reste le **geste humain 2**, inchangé.

Deux **amorces** fines au-dessus du cœur :

| | Interactif (humain au clavier) | Routine (autonome, horaire) |
|---|---|---|
| **Départ** | une conversation | une issue `label=ready` |
| **Cadrage** | `superpowers:brainstorming` en live avec l'humain | aucun — l'issue **est** la spec |
| **Gate `ready`** | non (l'humain est dans la boucle en continu) | oui (geste humain 1, posé async) |
| **Issue** | facultative (peut être ouverte pour tracer) | obligatoire (le travail vient d'elle) |
| **Cœur → preview** | identique | identique |
| **Périmètre/run** | la tâche en cours | une issue par repo par run |

**Refactor :** le skill `dev` isole le **cœur** (réutilisable) de l'**amorce routine** (sélection de l'issue `ready` + claim `in-progress`). L'amorce interactive est : `superpowers:brainstorming` → puis le cœur, avec la spec = le design validé en conversation. `brainstorm-issue` reste l'amorce du cas « je prépare une issue `ready` que la routine prendra plus tard » (il s'arrête à la spec dans l'issue).

Garde-fous inchangés : changement minimal, jamais deviner, jamais merge sur CI rouge, rebase avant FF, jamais de promo prod ni d'appel Coolify direct, `verification-before-completion` avant de déclarer fait.

## 2. Distribution : `avqn-dev` devient un plugin

`avqn-dev` est un **plugin Claude Code**, installé en **scope user** dans l'environnement cloud — chargé dynamiquement dans **chaque** session de **chaque** repo, comme `superpowers` et `frontend-design`. Fin de l'agrégation multi-source pour la méthodo, fin du vendoring par repo.

- `avqn-dev` gagne `.claude-plugin/plugin.json` (le plugin : skills `dev`/`brainstorm-issue`/`apercu` + superpowers vendorisées) **et** `.claude-plugin/marketplace.json` (le repo s'auto-déclare marketplace GitHub — un seul repo, zéro repo supplémentaire).
- Installation (env cloud, script de config) : `claude plugin marketplace add manu-bernard/avqn-dev` puis `claude plugin install avqn-dev --scope user`. Repo privé → l'auth GitHub de l'env doit permettre l'install ; **à valider sur l'env réel** avant rollout (point de risque n°1).
- Les **reusable workflows** (`.github/workflows/deploy.yml`, `promote.yml`) **restent** dans le repo, consommés par `uses:` — indépendants du plugin.
- Les **repos d'app** : suppriment leurs skills méthodo vendorisées ; leur `.claude/settings.json` active le plugin `avqn-dev` (+ `superpowers`, `frontend-design`) ; ils ne gardent que **leur contrat** (`CLAUDE.md`) + le hook `session-start`.

### Le MCP Playwright
Décision à l'implémentation : soit le plugin embarque un `.mcp.json` (déclaration Playwright), soit l'`executable-path` étant spécifique à l'env cloud (`/opt/pw-browsers/chromium`), on garde la ligne `claude mcp add --scope user` dans le script de config de l'env. Par défaut : **script de config de l'env** (l'`executable-path` est une coordonnée d'environnement, pas de méthodo).

## 3. Nettoyage méthodo dans les repos d'app

- `avqn-os/.claude/hooks/session-start.sh` : retirer « tu ouvres la PR et tu t'arrêtes là — tu ne merges pas, tu ne déploies pas » → texte drive-to-main aligné sur les autres repos.
- `contentos/docs/superpowers/specs/2026-06-28-nettoyage-harness-contentos-design.md` : **supprimer** (design périmé décrivant l'« agent recette » abandonné, contredit la conception).
- Supprimer `contentos/.claude/skills/apercu` et `avqn-os/.claude/skills/apercu` (+ `avqn-os/tools/apercu`, `bin/apercu` si rendus inutiles par le plugin) → source unique dans le plugin.
- **Template `session-start` unique** : même structure dans tous les repos (neutralise la signature de commit cassée du harness, annonce le contexte repo, note les services requis) ; aucune méthodo dedans.
- Chaque `CLAUDE.md` de repo d'app ne contient que **le contrat** : commande de gate, présence d'UI + commande de lancement local + URL + pages/breakpoints, services requis, versioning, coordonnées Coolify (uuid preview, uuid prod, health url, mode). Zéro procédure de dev (elle est dans le plugin).

## 4. Legacy & monorepo

- **Repo `render-farm` standalone** : archiver sur GitHub (il pointe les **mêmes UUID Coolify** que `apps/render-farm` → risque de collision de déploiement) ; retirer le clone local ; retirer sa ligne de `projects.txt`. Le monorepo `contentos` est la source de vérité unique de render-farm.
- **Clone local `avqn-deploy`** : supprimer (déjà archivé sur GitHub). `projects.txt`, le skill `dev` et le playbook ne vivent que dans `avqn-dev`.
- **`packages/video-spec`** : `"private": true` (lève l'ambiguïté « publié un jour ? ») ; aucun workflow de publish (résolu en workspace local, GH Packages mort). Retirer tout `publishConfig` résiduel.

## 5. Coolify : mûrir, pas casser

L'inventaire confirme : modélisation **correcte et fonctionnelle**, aucun bug.

- `application` (mono-process) : `avqn-os`, `product-barometre-ia`.
- `service` (compose, multi-process ou choix existant) : `contentos`, `render-farm`, `product-site-avqn`.
- Chaque app a une ressource **preview** ET **prod** distinctes (UUID séparés) — à préserver tel quel.

Actions (sans toucher l'infra) :

- Rendre `mode:` **explicite** dans **tous** les `ci.yml` (job `deploy`) et `promote.yml` — fin de l'implicite. Valeurs : `service` pour contentos/render-farm/site-avqn, `application` pour avqn-os/baromètre.
- **Documenter la règle** dans `docs/conception.md` : multi-process → `service` (PATCH `IMAGE_TAG`) ; mono-process → `application` (PATCH `docker_registry_image_tag`).

**Hors-scope** (maturation future, explicitement non fait ici, car preview **et** prod sont en jeu et le gain serait esthétique) :
- Unifier tout-en-`service` (supprimer le `mode` du reusable).
- Fixer les healthchecks `unknown` (baromètre, contentos, render-farm).
- Renommer `contentos-integration` → cohérence preview.

## 6. Routine de dev continu

- **Sources** de la routine = **repos d'app uniquement** (`avqn-dev` n'est plus une source : c'est un plugin user-scope).
- `projects.txt` (dans `avqn-dev`) : registre des repos d'app, sans le `render-farm` standalone.
- Prompt minimal inchangé : « déroule `/dev` sur les repos d'app sources ».

## Découpage en chantiers (pour le plan)

1. **Plugin** : `plugin.json` + `marketplace.json` dans `avqn-dev` ; refactor `dev` (cœur/amorce) ; valider l'install scope user depuis un repo privé sur l'env cloud. **Checkpoint humain** : l'install plugin marche en interactif ET en routine avant de toucher les repos d'app.
2. **Repos d'app** : retirer skills vendorisées ; activer le plugin ; homogénéiser `session-start` ; réduire `CLAUDE.md` au contrat ; nettoyer le « stop à la PR » (`avqn-os`) et le design périmé (`contentos`).
3. **Coolify lisible** : `mode:` explicite partout + règle documentée.
4. **Legacy** : archiver `render-farm` standalone, supprimer clones `avqn-deploy`/standalone, `video-spec` private, `projects.txt` à jour.
5. **Routine** : sources = repos d'app ; vérifier un cycle interactif **et** un cycle routine de bout en bout (jusqu'à une preview réelle).

## Risques

- **Install d'un plugin privé en scope user dans l'env cloud** (auth GitHub) — non prouvé, à valider en premier (chantier 1). Repli si bloquant : marketplace via clone local dans le script de config, ou rester sur multi-source pour la routine et plugin pour l'interactif.
- **Régression méthodo** en retirant les skills vendorisées : ne supprimer du repo qu'après avoir prouvé que le plugin fournit l'équivalent dans une session interactive de ce repo.
