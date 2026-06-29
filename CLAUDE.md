# avqn-dev — backbone du dev continu AVQN

Ce repo porte la **méthodologie partagée** (skills) et la **mécanique de déploiement** (reusable workflows). Il n'est **jamais cloné en dev** : ses skills se distribuent par agrégation multi-source, ses workflows par `uses:`.

## Ce qui vit ici
- `.claude/skills/` — `brainstorm-issue` (phase 1), `dev` (phase 2), `apercu` (qualité visuelle) + superpowers vendorisées. **Les wrappers sont les points d'entrée** ; ils orchestrent superpowers.
- `.github/workflows/deploy.yml` + `promote.yml` — grammaire Coolify partagée, **fine** : seulement des coordonnées (`service_uuid`, `health_url`, `image_tag`), zéro logique de typologie de projet.
- `projects.txt` — registre des repos d'app.
- `env/avqn-dev-env-setup.sh` — script de config de l'env cloud (1 ligne utile : `claude mcp add` Playwright).
- `docs/conception.md` — l'état cible complet.

## Règles d'édition
- Les skills sont la source de vérité de la méthodo : tiens-les fidèles au cycle réel (2 phases, 2 gates).
- Les reusable workflows restent **fins** : si tu es tenté d'y ajouter un `if` de typologie projet, c'est que ça doit vivre dans le `ci.yml` du repo concerné, pas ici.
- Onboarder un repo au dev continu = +1 ligne dans `projects.txt` **et** +1 source de la routine dev.
