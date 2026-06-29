---
name: apercu
description: Boucle qualité visuelle LOCALE avant la PR — boote l'app en local, capture le rendu aux breakpoints via le MCP Playwright, juge la qualité contre la spec de l'issue + la charte du projet, et fait améliorer le code jusqu'à un résultat de qualité (plafond d'itérations). À utiliser dans /dev pour toute tâche qui touche le front d'un repo à UI. Teste en LOCAL, jamais en preview.
---

# Aperçu — l'œil sur le front

Une couche au-dessus du e2e : l'app sait déjà se lancer pour ses tests. Ici on **regarde** ce qu'on a produit et on **améliore jusqu'à ce que ce soit beau**, en local, avant que la PR existe.

## Quand l'appliquer
- **OUI** : repo avec UI (déclaré dans son `CLAUDE.md`) ET tâche qui touche le front.
- **NON, saute** : repo sans front (worker, backend, lib) OU tâche sans impact visuel. Dis-le et passe.

## Pré-requis (depuis le `CLAUDE.md` du repo)
Commande pour lancer l'app en local, URL, pages/routes à inspecter, breakpoints (défaut **390 / 768 / 1440**), services requis (Postgres/Redis…).

## Le MCP Playwright
Outils `mcp__playwright__browser_*` (charge via ToolSearch si besoin). **`file://` est bloqué** → sers la page en localhost (le dev-server du repo, ou `python3 -m http.server` pour du statique) et navigue vers `http://127.0.0.1:<port>/…`.

## La boucle
```
1. build + lance l'app en local (commande du CLAUDE.md ; démarre les services requis)
2. pour chaque page/route × chaque breakpoint :
     browser_navigate → browser_resize(w,h) → browser_take_screenshot
     LIS la capture (tu peux voir les PNG)
3. JUGE le rendu contre DEUX références :
     - la SPEC de l'issue (le « quoi » / le rendu visé)
     - la CHARTE du projet (design system, tokens, conventions — cf. CLAUDE.md / charte)
   Critères : hiérarchie & lisibilité, alignement & espacements, cohérence avec la charte,
   responsive sans débordement/casse, états (vide/erreur/chargement) si pertinents.
4. PAS satisfait → identifie les défauts concrets → AMÉLIORE le code → retourne en 1.
5. Satisfait → termine : le rendu est de qualité, on peut continuer vers la gate + la PR.
```

## Garde-fous
- **Plafond d'itérations** (≈ 3-4 passes). Pas de convergence au plafond → **arrête**, commente l'issue avec les captures + ce qui bloque, mets de côté (pas de PR sur un rendu non abouti, mais pas de boucle infinie non plus).
- **Local uniquement** : jamais de test sur la preview/prod (URLs live). On valide AVANT la PR.
- **Améliore le code, pas la capture** : la boucle modifie le front réel jusqu'à ce qu'il soit juste.
- Juge **contre des références** (issue + charte), pas « à l'instinct » — sinon on sous-livre ou on sur-polit.
