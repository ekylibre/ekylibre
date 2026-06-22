# Déploiement NanoClaw sur ekylibre-dev.com — Procédure pas à pas

> Procédure opérationnelle pour le **premier déploiement** de NanoClaw (canal Telegram, multi-tenant) sur l'environnement `ekylibre-dev.com`. Suit la spec [`workflow_nanoclaw_telegram_prod.md`](./workflow_nanoclaw_telegram_prod.md).
>
> Hypothèse : `ekylibre-dev.com` tourne sur **Dokploy** (variante `docker-compose.dokploy.yml`). Les écarts pour la variante Caddy native (`docker-compose.yml`) sont signalés `→ variante Caddy :` en ligne.

| | |
|---|---|
| **Statut spec** | v1.0 — 2026-06-22 |
| **Statut image** | Build local OK avec workaround branche `channels` (cf. §2.4) |
| **Cible** | ekylibre-dev.com (pilote interne, pas d'utilisateurs externes) |
| **Tenant pilote** | À définir — proposer `ekylibre-dev` ou `closeriedesterres` |

---

## 0. Pré-requis à valider AVANT de commencer

- [X] Accès SSH `root` (ou `docker` group) à la VM ekylibre-dev.com
- [X] Accès à la console Dokploy
- [X] Compte Anthropic actif avec un `ANTHROPIC_AUTH_TOKEN` valide (peut être le même que `ANTHROPIC_API_KEY` côté Duke)
- [X] Accès au compte GHCR `ghcr.io/ekylibre/*` (push) ou possibilité de builder directement sur la VM
- [X] Compte Telegram pour parler à `@BotFather`
- [X] Au moins 1 chat_id Telegram identifié (= ton compte personnel pour le test pilote)
- [X] Service Duke déjà UP et joignable depuis `app` sur `ws://duke-api:8000/ws` (à vérifier : `docker compose ps duke-api`)

---

## 1. Construire et publier l'image NanoClaw

### 1.1 Build local (pour validation)

Déjà fait — l'image build proprement avec les patches §2.4. Sanity check :

```bash
cd ~/projects/ekylibre
docker build -f docker/nanoclaw/Dockerfile -t ghcr.io/ekylibre/nanoclaw-ekylibre:latest .
docker images ghcr.io/ekylibre/nanoclaw-ekylibre
```

### 1.2 Push vers GHCR

```bash
# Authentification GHCR (PAT avec scopes `write:packages, read:packages`)
export GHCR_TOKEN='XXXXXXX'
echo "$GHCR_TOKEN" | docker login ghcr.io -u ionosphere --password-stdin

# Tag + push
docker push ghcr.io/ekylibre/nanoclaw-ekylibre:latest

# Rendre l'image publique sur GHCR (UI : packages/nanoclaw-ekylibre → Package settings)
# Sinon la VM aura besoin d'un docker login GHCR aussi.
```

> **Alternative bare-metal** : si pas d'accès GHCR push, builder directement sur la VM ekylibre-dev.com en clonant le repo et en faisant le `docker build` sur place. Plus simple pour un pilote.

---

## 2. Préparer la VM ekylibre-dev.com

SSH dans la VM, puis :

### 2.1 Pull du repo Ekylibre à jour

```bash
cd /opt/ekylibre   # ou le chemin de déploiement réel
git pull origin 5.0-beta
```

S'assurer que `docker/nanoclaw/` et le bloc `nanoclaw:` du compose sont présents.

### 2.2 Créer le fichier `nanoclaw-tenants.yml` (secret)

```bash
# Doit exister avant `docker compose up` (sinon Docker le crée comme un dossier).
sudo touch /opt/ekylibre/nanoclaw-tenants.yml
sudo chmod 0600 /opt/ekylibre/nanoclaw-tenants.yml
sudo chown root:root /opt/ekylibre/nanoclaw-tenants.yml
```

Le remplir vient en §3 après création du bot.

### 2.3 Étendre `.env` avec les variables NanoClaw

À ajouter au `.env` de production (ne pas committer) :

```bash
# Image
NANOCLAW_IMAGE_TAG=v0.1.0

# Anthropic — peut réutiliser la même clé que Duke
ANTHROPIC_AUTH_TOKEN=sk-ant-...
ANTHROPIC_BASE_URL=

# Provider LLM par défaut
NANOCLAW_LLM_PROVIDER=claude
NANOCLAW_LOG_LEVEL=info

# Chemin host vers le fichier tenants.yml
NANOCLAW_TENANTS_PATH=/opt/ekylibre/nanoclaw-tenants.yml
```

Validation immédiate :

```bash
docker compose -f docker/prod/docker-compose.dokploy.yml config 2>&1 | grep -A 3 "^  nanoclaw:"
# → variante Caddy : remplacer `docker-compose.dokploy.yml` par `docker-compose.yml`
```

Doit afficher le service `nanoclaw` sans warning sur `NANOCLAW_*` ni `ANTHROPIC_AUTH_TOKEN`.

### 2.4 ⚠️ Workaround branche `channels` upstream

L'image est buildée depuis la branche feature `channels` de `nanocoai/nanoclaw` au SHA `8137440698f8972bb17948dd54e6e2bc0019b060`. Cette branche est **WIP, pas une release**. Le Dockerfile applique 3 patches au build (cf. commentaire dans `docker/nanoclaw/Dockerfile`) :
1. Suppression de `src/channels/deltachat.ts` (import manquant)
2. Suppression de `src/channels/slack.ts` (idem)
3. Ajout de `resolveChannelName?` à l'interface `ChannelAdapter`

**À surveiller** : dès que la branche `channels` est mergée proprement dans `main` upstream (ou qu'une release tag inclut Telegram), on doit :
- repointer `NANOCLAW_BRANCH=main` dans le Dockerfile
- retirer le bloc de patches
- rebuild

Tracking : ouvrir une issue interne `NanoClaw / dégeler le pin upstream` avec watch sur la branche `channels` du dépôt `nanocoai/nanoclaw`.

---

## 3. Provisionner le bot Telegram + le tenant pilote

### 3.1 Créer un bot Telegram via BotFather

Depuis ton compte Telegram :

1. Ouvrir un chat avec `@BotFather`
2. `/newbot` → choisir un nom (ex: `Ekylibre Dev Assistant`)
3. Choisir un username unique terminant par `bot` (ex: `EkylibreDevAssistantBot`)
4. BotFather renvoie un `bot_token` du style `1234567890:AAH-...` → le copier
5. (Optionnel) `/setdescription`, `/setabouttext`, `/setuserpic` pour l'esthétique

### 3.2 Récupérer ton `chat_id` Telegram

```bash
# Envoyer un /start au bot d'abord, puis :
curl -s "https://api.telegram.org/bot<BOT_TOKEN>/getUpdates" | jq '.result[].message.chat.id' | sort -u
```

Note le `chat_id` (entier signé). C'est ce qui ira dans `authorized_chat_ids`.

### 3.3 Récupérer un `authentication_token` Ekylibre pour le tenant pilote

```bash
# Dans le container app prod
docker compose -f docker/prod/docker-compose.dokploy.yml exec app \
  bundle exec rails runner -e production "
    Apartment::Tenant.switch!('ekylibre-dev')   # remplacer par le vrai schema
    user = User.find_by(email: 'admin@ekylibre-dev.com')
    user.reset_authentication_token!
    puts user.authentication_token
  "
```

⚠️ V1 = **token utilisateur complet**, pas scoped. Mitigation V1.5 (cf. spec §10 entrée 1). Pour le pilote interne sur un compte admin contrôlé, le risque est accepté.

### 3.4 Renseigner `nanoclaw-tenants.yml`

Partir du template :

```bash
scp nanoclaw-tenants.yml xxxx:/home/ubuntu/ekylibre/nanoclaw-tenants.yml
ssh xxxxx
chmod 0600 /home/ubuntu/ekylibre/nanoclaw-tenants.yml
chown ubuntu:ubuntu /home/ubuntu/ekylibre/nanoclaw-tenants.yml
```

Contenu cible pour le pilote :

```yaml
tenants:
  - id: demo                            # doit matcher le schema Apartment
    locale: fra
    llm_provider: claude
    ekylibre:
      email: admin@ekylibre.org
      token: ekt_xxxxxxxxxxxxxxxxxxxxxxxx       # 3.3
    telegram:
      bot_token: "1234567890:AAH-..."           # 3.1
      bot_username: EkylibreDevAssistantBot     # 3.1
      authorized_chat_ids: [123456789]          # 3.2 — ton chat_id perso
```

Sanity check YAML :

```bash
python3 -c "import yaml; print(yaml.safe_load(open('/opt/ekylibre/nanoclaw-tenants.yml')))"
```

---

## 4. Déployer le service

### 4.1 Pull de l'image

```bash
cd /opt/ekylibre
docker compose -f docker/prod/docker-compose.dokploy.yml pull nanoclaw
# → variante Caddy : docker-compose.yml
```

### 4.2 Up du service

```bash
docker compose -f docker/prod/docker-compose.dokploy.yml up -d nanoclaw
```

Surveiller le boot :

```bash
docker compose -f docker/prod/docker-compose.dokploy.yml logs -f nanoclaw
```

Attendre les lignes `init.sh: v tenant ekylibre-dev pret` puis `init.sh: Demarrage du host NanoClaw`. Healthcheck devrait passer en `healthy` après ~90 s (`start_period`).

### 4.3 Vérifier l'état

```bash
# Statut Docker
docker compose -f docker/prod/docker-compose.dokploy.yml ps nanoclaw

# Statut applicatif via la CLI embarquée
docker compose -f docker/prod/docker-compose.dokploy.yml exec nanoclaw nanoclaw status
```

Sortie attendue de `nanoclaw status` :
```
TENANT                         STATUS     CONTAINER ID
demo                   running    abc123def456
```

Si le tenant reste en `stopped` après 2 min, voir §6.1 (debug du spawn upstream).

---

## 5. Premier test utilisateur

Depuis ton compte Telegram, dans le chat ouvert avec ton bot :

### 5.1 Smoke test minimal

| Étape | Message envoyé | Comportement attendu |
|---|---|---|
| 1 | `/start` | Message d'accueil du bot (réponse du LLM via le CLAUDE.md du tenant) |
| 2 | `/help` | Liste des capacités / exemples |
| 3 | `Quel temps fait-il demain ?` | Hors périmètre Duke → réponse Claude directe |
| 4 | `Combien me reste-t-il de Karaté Zeon ?` | Appel `duke_chat` → réponse depuis Ekylibre (si stock présent dans le tenant) ou message "pas de stock connu" |

### 5.2 Test du flow intervention (le cas critique)

Message : `J'ai pulvérisé 2 L de Karaté Zeon sur Bel Air ce matin pendant 1h30.`

Attendu :
1. Bot envoie une carte brouillon avec les champs reconnus + boutons `[✓ Valider]` `[🗑 Annuler]`
2. Clic sur `Valider` → message `✅ Intervention #XXXX créée. Voir : https://ekylibre-dev.com/...`
3. Vérification côté Ekylibre : l'intervention apparaît dans `/backend/interventions` du tenant

> Pré-requis pour que ça marche : produit `Karaté Zeon` et parcelle `Bel Air` doivent exister dans le tenant `ekylibre-dev`. Sinon, adapter le message au stock réel.

### 5.3 Vérification logs

Pas de tokens en clair, pas de PII, JSON structuré :

```bash
docker compose -f docker/prod/docker-compose.dokploy.yml logs --tail=200 nanoclaw | jq -c 'select(.event)' | head -20
```

---

## 6. Procédures post-déploiement

### 6.1 Ajouter un second tenant (à chaud)

```bash
# 1. Créer un 2e bot Telegram via BotFather
# 2. Générer un token authentication_token sur le 2e tenant
# 3. Éditer /opt/ekylibre/nanoclaw-tenants.yml (ajouter un bloc tenant)
# 4. Recharger sans interrompre le 1er tenant
docker compose -f docker/prod/docker-compose.dokploy.yml exec nanoclaw nanoclaw reload
docker compose -f docker/prod/docker-compose.dokploy.yml exec nanoclaw nanoclaw status
```

### 6.2 Mise à jour de l'image

```bash
# 1. Bump du tag dans .env
sed -i 's/NANOCLAW_IMAGE_TAG=.*/NANOCLAW_IMAGE_TAG=v0.2.0/' /opt/ekylibre/.env

# 2. Pull + recreate sans toucher les autres services
docker compose -f docker/prod/docker-compose.dokploy.yml pull nanoclaw
docker compose -f docker/prod/docker-compose.dokploy.yml up -d --no-deps nanoclaw
```

Pendant le restart (~30 s), Telegram met les messages en file côté serveur Bot API → pas de perte au retour du long-poll.

### 6.3 Rotation d'un token Telegram (bot leaké)

```bash
# 1. @BotFather → /revoke → choisir le bot → nouveau token
# 2. sudo nano /opt/ekylibre/nanoclaw-tenants.yml → mettre à jour bot_token
# 3. nanoclaw reload
docker compose -f docker/prod/docker-compose.dokploy.yml exec nanoclaw nanoclaw reload
```

### 6.4 Sauvegardes

À configurer dans Dokploy (UI → backups) ou via cron host :

| Donnée | Chemin | Rétention |
|---|---|---|
| Volume `nanoclaw-data` | `/var/lib/docker/volumes/ekylibre_nanoclaw-data/_data` | 30 j |
| `nanoclaw-tenants.yml` | `/opt/ekylibre/nanoclaw-tenants.yml` (chiffré) | illimité |

---

## 7. Rollback

Si NanoClaw casse quelque chose ou si on veut revenir à l'état antérieur :

```bash
# Arrêter et retirer NanoClaw (sans toucher le reste de la stack)
docker compose -f docker/prod/docker-compose.dokploy.yml stop nanoclaw
docker compose -f docker/prod/docker-compose.dokploy.yml rm -f nanoclaw

# (Optionnel) purger le volume de données
docker volume rm ekylibre_nanoclaw-data
```

Aucun impact sur `app`, `sidekiq`, `db`, `duke-api`. NanoClaw est strictement **additif** dans la stack.

---

## 8. Checklist de validation finale

À cocher avant de considérer le pilote stable :

- [ ] Image `ghcr.io/ekylibre/nanoclaw-ekylibre:v0.1.0` publiée
- [ ] `.env` prod contient les 5 variables NanoClaw
- [ ] `/opt/ekylibre/nanoclaw-tenants.yml` créé, 0600, root:root, syntaxe YAML valide
- [ ] `docker compose ... up -d nanoclaw` réussit
- [ ] `nanoclaw status` montre le tenant en `running`
- [ ] `/start` au bot Telegram → réponse reçue
- [ ] Question Q&A Duke → réponse reçue
- [ ] Saisie d'intervention → carte brouillon + Valider → intervention créée dans Ekylibre
- [ ] Sauvegarde du volume `nanoclaw-data` planifiée
- [ ] Pare-feu host : aucun port entrant ajouté pour `nanoclaw` (Telegram = sortant)
- [ ] Issue de tracking ouverte pour le **workaround branche `channels`** (§2.4)
- [ ] Page utilisateur publiée pour les pilotes (`/help` content + limites V1)

---

## 9. Points d'attention restants (à valider pendant le pilote)

Repris de la spec §10 :

| # | Sujet | Comment valider sur le pilote |
|---|---|---|
| 6 | `nanoclaw reload` hot-reload réel upstream | Ajouter un 2e tenant et observer logs : SIGHUP-vs-restart |
| 7 | Override `--network` pour les containers Bun spawnés | Vérifier `docker network inspect ekylibre` pendant qu'un tenant tourne |
| 8 | Compat Dokploy variant | C'est ce déploiement même qui valide |

---

## 10. Contacts en cas d'incident

- Owner pilote : David Joulin (djoulin@ekylibre.com)
- Référent Duke : (à compléter)
- Référent infra Dokploy : (à compléter)

## Historique

| Version | Date | Auteur | Modif |
|---|---|---|---|
| 1.0 | 2026-06-22 | David Joulin (assisté par Claude) | Création initiale après build local OK |
