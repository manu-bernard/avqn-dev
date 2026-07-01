# avqn-dev — backbone du dev continu AVQN

Repo **jamais cloné en dev**, deux rôles :

1. **Plugin user-scope** (`skills/` + `.claude-plugin/`) — la méthodologie de dev, distribuée via la marketplace auto-hébergée `manu-bernard/avqn-dev`. Installé en scope user → **auto-enabled dans chaque session de chaque repo** (interactif et routine), sans aucune config par repo :
   - `brainstorm-issue` — interactif : brainstorme une idée → spec d'intention dans l'issue, pour préparer une issue `ready` que la routine prendra.
   - `dev` — un cœur commun (plan → TDD → qualité visuelle → gate → PR → CI → FF merge `main` → deploy preview) avec deux amorces : **interactive** (conversation + brainstorm live → preview, issue facultative) et **routine** (issue `label=ready` → preview, autonome).
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
- `env/avqn-dev-env-setup.sh` — script de config de l'environnement cloud (installe le plugin avqn-dev en scope user + enregistre le MCP Playwright).
- `docs/conception.md` — la conception complète (état cible).

Conception et recette détaillées : voir `docs/conception.md`.
