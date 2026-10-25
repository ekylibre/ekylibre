# group-template/tools/

Placeholder. Les outils par tenant copies dans `/data/groups/<id>/tools/` par
`init.sh` et `nanoclaw enroll` doivent vivre ici.

Outils prevus (cf. spec §1.1 et CLAUDE.md template §1, §4) :

- `duke-chat` — relais WS vers Duke. Entree : la phrase utilisateur telle quelle.
  Sortie : la reponse Duke (`kind=assistant_message` | `clarification` | `draft` |
  `out_of_scope`).
- `eky-confirm` — POST vers l'API Ekylibre pour valider un brouillon d'intervention
  apres clic `✓ Valider` cote Telegram. Utilise `EKY_TENANT` + `EKY_TOKEN` du
  `.env` du groupe.
- `render-draft` — formate une carte brouillon en message Telegram + inline keyboard
  `[✓ Valider] [🗑 Annuler]`.

Chaque outil est attendu sous forme de script execute par le Bun agent du tenant
(format upstream NanoClaw `groups/<id>/tools/<name>`). Specification a finaliser
au moment du POC (cf. §10 entree 7).

Ce fichier README est cree pour que `COPY docker/nanoclaw/group-template/ /app/group-template/`
ne saute pas un repertoire vide.
