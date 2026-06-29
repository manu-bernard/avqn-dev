---
name: brainstorm-issue
description: Phase 1 du dev continu — brainstorme INTERACTIVEMENT une idée ou une issue brute avec l'humain, et dépose la SPEC D'INTENTION résultante dans le corps de l'issue GitHub. S'arrête là ; l'humain pose le label `ready` (l'aval). Ne code rien, ne planifie pas l'implémentation.
---

# Brainstorm Issue

Wrapper de `superpowers:brainstorming`. **Seule différence** : le design validé est écrit **dans l'issue GitHub**, pas dans `docs/specs`. C'est la **phase 1** du cycle : on transforme une intention floue en une **spec d'intention** claire, persistée dans l'issue.

Interactif par nature : le brainstorm a besoin de l'humain.

## Procédure

1. **Cible** : une issue brute existante (numéro fourni) ou une idée → crée d'abord l'issue (titre court, corps = l'idée brute).
2. **Brainstorm** : déroule **`superpowers:brainstorming`** normalement (contexte projet, questions une par une, 2-3 approches, design par sections, validation). Respecte sa discipline : **ne propose pas, ne code pas** avant que l'humain ait approuvé le design.
3. **Dépose la spec dans l'issue** : quand `superpowers:brainstorming` atteint l'étape « écrire le design », **écris-le dans le corps de l'issue** (édite l'issue via MCP GitHub ou `gh api`). Format = **spec d'intention** :
   - **Quoi** : ce qu'on veut obtenir (comportement, résultat attendu, pour le front : le rendu visé).
   - **Pourquoi** : le besoin / la valeur.
   - **Critères d'acceptation** : comment on saura que c'est fait (cases à cocher).
   - **Hors-périmètre** : ce qu'on ne fait pas.
   - **PAS de plan d'implémentation** (fichiers, étapes techniques) — ça, c'est le travail de `/dev`.
4. **Arrête-toi.** Ne passe **pas** à `writing-plans` ni au code. Dis à l'humain que l'issue est prête à être validée : **« pose le label `ready` quand tu valides »** (c'est le gate humain, posé async).

## Garde-fous
- **Interactif uniquement** : on ne pré-brainstorme pas une issue en autonome.
- **Spec d'intention, pas plan** : l'issue reste lisible et stable ; `/dev` planifiera.
- **Tu ne poses jamais `ready` toi-même** — c'est le geste de l'humain.
- Une idée trop grosse pour une seule issue → aide à la **découper** en plusieurs issues, chacune brainstormée à son tour.
