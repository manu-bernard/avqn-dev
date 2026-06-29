# avqn-dev — backbone du dev continu AVQN

Repo **jamais cloné en dev**, deux rôles :

1. **Skills partagées** (`.claude/skills/`) — la méthodologie de dev, distribuée par **agrégation multi-source** (ce repo est une source de la routine de dev ; ses skills se chargent dans chaque session, quel que soit le repo d'app travaillé) :
   - `brainstorm-issue` — phase 1, interactif : brainstorme une issue → spec d'intention dans l'issue.
   - `dev` — phase 2, autonome : issue `ready` → TDD → qualité visuelle → PR → CI → FF merge → deploy preview.
   - `apercu` — boucle qualité visuelle locale (Playwright) avant la PR.
   - superpowers vendorisées (TDD, debugging, plans, review, verification…).

2. **Reusable workflows** (`.github/workflows/`) — la mécanique Coolify partagée, appelée par chaque repo via `uses: manu-bernard/avqn-dev/.github/workflows/deploy.yml@v1` (résolu au CI, jamais cloné) :
   - `deploy.yml` — repointe le service **preview** sur un sha, déclenche, health-check.
   - `promote.yml` — reporte le sha **preview → prod**.

## Deux gestes humains, le reste autonome
(1) approuver une issue (label `ready`) ; (2) promouvoir une preview en prod.

## Cycle
`issue brute → /brainstorm-issue → spec dans l'issue → [ready] → /dev → PR → main → deploy preview → [promote] → prod`

## Pièces
- `projects.txt` — registre des repos d'app du dev continu.
- `env/avqn-dev-env-setup.sh` — script de config de l'environnement cloud (enregistre le MCP Playwright).
- `docs/conception.md` — la conception complète (état cible).

Conception et recette détaillées : voir `docs/conception.md`.
