# avqn-dev — backbone du dev continu AVQN

Ce repo porte la **méthodologie partagée** (plugin user-scope) et la **mécanique de déploiement** (reusable workflows). Il n'est **jamais cloné en dev** : ses skills se distribuent via le plugin, ses workflows par `uses:`.

## Ce qui vit ici
- `skills/` + `.claude-plugin/` — plugin `avqn-dev`, marketplace unique de la méthodo (`/plugin marketplace add a-v-q-n/avqn-dev`). Installé en scope user → auto-enabled dans chaque session, sans config par repo. Contient `brainstorm-issue` (prépare une issue `ready`), `dev` (cœur commun + deux amorces : interactive, routine), `apercu` (qualité visuelle) + superpowers vendorisées. **Les wrappers sont les points d'entrée** ; ils orchestrent superpowers.
- `.github/workflows/deploy.yml` + `promote.yml` — grammaire Coolify partagée, **fine** : seulement des coordonnées (`uuid`, `health_url`, `image_tag`, `mode`), zéro logique de typologie de projet.
- `projects.txt` — registre des repos d'app.
- `env/avqn-dev-env-setup.sh` — script de config de l'env cloud, **sans aucune source déclarée** (le proxy sandbox bride `git clone`, pas curl/npm) : la méthodo `avqn-dev` s'installe par **tarball** du repo public (marketplace en chemin local) et Playwright par **`claude mcp add`** (serveur MCP npm, pas un plugin). C'est **le canal env cloud** — l'ajout direct de la marketplace `a-v-q-n/avqn-dev` sert claude.ai et Claude Code en usage interactif, où `git clone` n'est pas bridé. Install 100 % « sans fichiers » (comme Playwright) = à terme un **package npm** de la méthodo.
- `docs/conception.md` — l'état cible complet.

## Règles d'édition
- Les skills (dans `skills/`) sont la source de vérité de la méthodo : tiens-les fidèles au cycle réel (2 amorces sur un cœur ; palier mono/double, §6 de la conception).
- Les reusable workflows restent **fins** : si tu es tenté d'y ajouter un `if` de typologie projet, c'est que ça doit vivre dans le `ci.yml` du repo concerné, pas ici.
- Onboarder un repo au dev continu = +1 ligne dans `projects.txt` **et** +1 source dans la routine cloud (clone de travail).
