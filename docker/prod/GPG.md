# Configuration GPG pour la signature en production

Ekylibre signe certains documents (clôtures d'exercice fiscal, archives de documents) avec GPG via la gem [`gpgme`](https://github.com/ueno/ruby-gpgme). La signature produite est un **clearsign PGP** (format ASCII armored standard) du SHA256 du fichier, sauvegardé en `.asc` à côté du document original.

Usages dans le code :
- `lib/ekylibre/document_management/signature_manager.rb` — signature des documents générés
- `app/services/financial_year_close.rb` — signature des archives ZIP de clôture d'exercice

L'identité du signataire est lue dans **`ENV['GPG_EMAIL']`**. La clé privée doit être présente dans le keyring GPG du processus Rails.

---

## 1. Pourquoi une clé GPG en production ?

- **Intégrité** : prouver qu'un document n'a pas été modifié depuis sa génération
- **Conformité comptable** : les clôtures d'exercice doivent être signées (impératif légal en France pour les archives comptables)
- **Audit trail** : permet de vérifier *a posteriori* qu'un export est bien celui produit à une date donnée

Si vous **n'utilisez pas** les fonctionnalités de clôture d'exercice ou de signature de documents, vous pouvez ignorer cette doc — le reste d'Ekylibre fonctionne sans clé GPG.

---

## 2. Prérequis

Sur la machine où vous générez la clé (votre poste de travail) :

```bash
gpg --version
# gpg (GnuPG) 2.2 ou supérieur
```

Si manquant :
```bash
sudo apt install gnupg     # Debian / Ubuntu
brew install gnupg         # macOS
```

---

## 3. Génération de la clé (mode batch, sans passphrase)

> ⚠️ **Sans passphrase** : indispensable pour l'automatisation (le container ne peut pas saisir interactivement). En contrepartie, **toute personne ayant accès au fichier de clé peut signer en votre nom** — protéger le fichier comme un secret de production (chmod 600, volume monté en read-only, accès machine restreint).

### 3.1 Préparer un fichier batch

Créer `gpg-batch.conf` sur votre poste :

```ini
%no-protection
Key-Type: EDDSA
Key-Curve: ed25519
Key-Usage: sign
Subkey-Type: ECDH
Subkey-Curve: cv25519
Subkey-Usage: encrypt
Name-Real: Ekylibre Production
Name-Email: ekylibre@example.com
Expire-Date: 0
%commit
```

Adapter :
- `Name-Email` → l'adresse que vous mettrez dans `GPG_EMAIL` (doit matcher exactement)
- `Expire-Date: 0` = pas d'expiration (acceptable pour une clé de signature documentaire ; alternativement `2y` pour 2 ans et planifier une rotation)

**Pourquoi ed25519** : algo moderne (Curve25519), signatures courtes, rapide, supporté par GPG 2.1+ et par toutes les versions de `gpgme`. Si vous avez besoin d'interopérabilité avec des outils anciens (Windows GPG4Win < 4, etc.), utiliser RSA 4096 :

```ini
%no-protection
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Subkey-Type: RSA
Subkey-Length: 4096
Subkey-Usage: encrypt
Name-Real: Ekylibre Production
Name-Email: ekylibre@example.com
Expire-Date: 0
%commit
```

### 3.2 Générer la clé dans un keyring isolé

Pour éviter de mélanger avec votre keyring personnel :

```bash
mkdir -p ekylibre-gnupg
chmod 700 ekylibre-gnupg

gpg --homedir ./ekylibre-gnupg --batch --gen-key gpg-batch.conf
```

Vérifier :
```bash
gpg --homedir ./ekylibre-gnupg --list-secret-keys --keyid-format LONG
# /home/.../ekylibre-gnupg/pubring.kbx
# ------------------------------------
# sec   ed25519/A1B2C3D4E5F60718 2026-06-12 [SC]
#       FINGERPRINT...
# uid                 [ultimate] Ekylibre Production <ekylibre@example.com>
# ssb   cv25519/...                 2026-06-12 [E]
```

Noter le **fingerprint** (40 caractères hex) — utile pour les opérations futures.

### 3.3 Forcer la trust ultimate sur la propre clé

`gpgme` refuse de signer avec une clé qui n'est pas "trusted ultimate" :

```bash
FPR=$(gpg --homedir ./ekylibre-gnupg --list-secret-keys --with-colons | awk -F: '/^fpr:/ {print $10; exit}')
echo "${FPR}:6:" | gpg --homedir ./ekylibre-gnupg --import-ownertrust
```

`6` = ultimate trust.

---

## 4. Préparer les fichiers pour le container

Le container Ekylibre lit le keyring dans `/home/ekylibre/.gnupg`. On va monter notre `ekylibre-gnupg/` dessus.

### 4.1 Structure attendue

```
secrets/
└── gnupg/
    ├── pubring.kbx
    ├── trustdb.gpg
    └── private-keys-v1.d/
        └── <KEYGRIP>.key
```

### 4.2 Copier le keyring sur le serveur de production

```bash
# Sur le poste qui a généré la clé
tar czf ekylibre-gnupg.tar.gz -C ekylibre-gnupg .

# Transférer
scp ekylibre-gnupg.tar.gz user@prod-server:/path/to/ekylibre/secrets/

# Sur le serveur
cd /path/to/ekylibre/secrets
mkdir -p gnupg
tar xzf ekylibre-gnupg.tar.gz -C gnupg
chmod 700 gnupg
chmod 600 gnupg/private-keys-v1.d/*
rm ekylibre-gnupg.tar.gz
```

Vérifier les permissions :
```bash
ls -la secrets/gnupg/
# drwx------ ... pubring.kbx
# drwx------ ... private-keys-v1.d
```

### 4.3 Ignorer le dossier dans git

S'assurer que `secrets/` est dans `.gitignore` (le `.gitignore` du projet contient déjà `**/secrets/` ou équivalent — vérifier).

---

## 5. Configurer Docker Compose

Le mount GPG est déjà déclaré dans les deux composes prod (`docker-compose.yml` et `docker-compose.dokploy.yml`), paramétré par la variable `GPG_KEYRING_PATH`. Aucune édition du YAML n'est nécessaire — il suffit de renseigner les variables dans `.env`.

```yaml
# Extrait de docker-compose.yml — déjà présent sur app ET sidekiq
volumes:
  - ${GPG_KEYRING_PATH:-./secrets/gnupg}:/home/ekylibre/.gnupg:ro
```

> Le mount en `:ro` évite que le process Rails modifie le keyring par accident. Si vous devez importer/rotater une clé, faites-le hors container.

### 5.1 Renseigner `GPG_KEYRING_PATH` et `GPG_EMAIL` dans `.env`

```dotenv
# Chemin absolu sur l'hôte vers le dossier qui contient pubring.kbx, private-keys-v1.d/, etc.
GPG_KEYRING_PATH=/home/ubuntu/ekylibre/secrets/gnupg

# Doit matcher EXACTEMENT l'email de la clé (case-sensitive).
GPG_EMAIL=ekylibre@example.com
```

> Si `GPG_KEYRING_PATH` n'est pas défini, Docker utilise le chemin par défaut `./secrets/gnupg` (relatif au dossier `docker/prod/`). Si le chemin n'existe pas, Docker crée un dossier vide → le mount est inoffensif mais GPG signing échouera (No secret key).

### 5.2 Redémarrer le stack

```bash
docker compose -f docker/prod/docker-compose.yml up -d --force-recreate app sidekiq
```

---

## 6. Vérification

### 6.1 Tester depuis la console Rails

```bash
docker compose -f docker/prod/docker-compose.yml exec app bundle exec rails c
```

```ruby
crypto = GPGME::Crypto.new
sig = crypto.clearsign("test fingerprint 12345", signer: ENV['GPG_EMAIL'])
puts sig
# -----BEGIN PGP SIGNED MESSAGE-----
# Hash: SHA512
#
# test fingerprint 12345
# -----BEGIN PGP SIGNATURE-----
# ...
# -----END PGP SIGNATURE-----
```

Si vous obtenez un `GPGME::Error::BadSignature` ou `Unusable secret key` → la clé n'est pas trusted ultimate (revoir §3.3) ou `GPG_EMAIL` ne matche pas.

### 6.2 Vérifier que la signature est valide

```bash
docker compose -f docker/prod/docker-compose.yml exec app bash -c \
  'echo "test fingerprint 12345" | gpg --clearsign | gpg --verify'
# gpg: Signature made ...
# gpg: Good signature from "Ekylibre Production <ekylibre@example.com>"
```

---

## 7. Distribution de la clé publique

Pour que des tiers (auditeurs, comptables, fisc) puissent vérifier les signatures, exporter et publier la clé publique :

```bash
gpg --homedir ./ekylibre-gnupg --armor --export ekylibre@example.com > ekylibre-public.asc
```

Le fichier `ekylibre-public.asc` peut être :
- Hébergé sur votre site (`https://example.com/.well-known/gpg.asc`)
- Publié sur un keyserver (`gpg --send-keys <FPR>`)
- Distribué avec chaque export signé

Toute personne avec ce fichier peut vérifier les `.asc` produits par Ekylibre.

---

## 8. Rotation / Révocation

### Générer un certificat de révocation (à faire MAINTENANT, à archiver hors-ligne)

```bash
gpg --homedir ./ekylibre-gnupg --output ekylibre-revoke.asc --gen-revoke ekylibre@example.com
# Choisir "1 = Key has been compromised" comme raison par défaut
```

Stocker `ekylibre-revoke.asc` dans un coffre offline (clé USB chiffrée, papier scellé). Ce fichier permet de révoquer la clé même si vous perdez le secret.

### Rotation programmée (recommandé tous les 2 ans)

1. Générer une nouvelle clé (§3)
2. Signer les deux clés croisées si vous voulez préserver la chaîne de confiance
3. Mettre à jour le mount Docker + `GPG_EMAIL` (si l'email change)
4. Publier la nouvelle clé publique en signalant la rotation
5. Conserver l'ancienne clé en lecture seule pour les vérifications historiques

---

## 9. Sécurité & checklist

- [ ] Le dossier `secrets/gnupg/` est dans `.gitignore`
- [ ] `chmod 700 secrets/gnupg` et `chmod 600 secrets/gnupg/private-keys-v1.d/*`
- [ ] Volume monté en `:ro` dans le compose
- [ ] `GPG_EMAIL` renseigné dans `.env` et matche l'UID de la clé
- [ ] Certificat de révocation généré et stocké hors-ligne
- [ ] Clé publique publiée pour vérification externe
- [ ] Backup chiffré du keyring (la perte = impossibilité de re-signer des documents historiques)
- [ ] Accès SSH au serveur restreint à l'équipe ops

---

## 10. Troubleshooting

### `GPGME::Error::BadPassphrase`

La clé a une passphrase. Soit la retirer (générer sans `%no-protection` est une erreur), soit configurer `gpg-agent` avec preset (non recommandé en container).

```bash
# Retirer la passphrase d'une clé existante
gpg --homedir ./ekylibre-gnupg --edit-key ekylibre@example.com
> passwd
> (saisir l'ancienne passphrase, puis Enter vide deux fois)
> save
```

### `gpg: signing failed: Unusable secret key`

La clé n'est pas trusted ultimate (revoir §3.3) **OU** le keygrip de la clé privée manque dans `private-keys-v1.d/` (le transfert §4.2 a oublié des fichiers).

### `gpg: skipped "ekylibre@example.com": No secret key`

Le keyring monté ne contient pas de clé privée. Vérifier :
```bash
docker compose -f docker/prod/docker-compose.yml exec app gpg --list-secret-keys
```

### `permission denied` sur `pubring.kbx`

Les permissions du volume monté sont mauvaises. Sur l'hôte :
```bash
sudo chown -R 1000:1000 secrets/gnupg
chmod 700 secrets/gnupg
chmod 600 secrets/gnupg/private-keys-v1.d/*
```

(`1000:1000` = UID/GID de l'utilisateur `ekylibre` dans le container.)

### Le bundle `gpgme` n'a pas trouvé `libgpgme` au build de l'image

Si vous customisez l'image, s'assurer que les paquets sont présents : `apt-get install -y libgpgme-dev gnupg`. L'image de base `ghcr.io/ekylibre/docker-base-images/ruby2.6:latest` les inclut déjà.
