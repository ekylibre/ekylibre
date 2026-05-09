#!/usr/bin/env bash
# Récupère la CA racine générée par Caddy (`tls internal`) et l'installe
# dans le store de confiance du système ainsi que dans les bases NSS de
# Firefox / Chromium pour que les `https://*.ekylibre.test` soient validés
# sans warning.
#
# À lancer une fois après le premier `docker compose up caddy`. Idempotent.

set -euo pipefail

CADDY_CONTAINER="${CADDY_CONTAINER:-caddy}"
CA_PATH_IN_CONTAINER="/data/caddy/pki/authorities/local/root.crt"
CA_HOST_PATH="/usr/local/share/ca-certificates/caddy-ekylibre-dev.crt"
TMP_CA="$(mktemp --suffix=.crt)"
trap 'rm -f "$TMP_CA"' EXIT

if ! docker inspect -f '{{.State.Running}}' "$CADDY_CONTAINER" >/dev/null 2>&1; then
	echo "Erreur : container '$CADDY_CONTAINER' introuvable ou arrêté." >&2
	echo "Lancer d'abord : docker compose -f docker/dev/docker-compose.yml up -d caddy" >&2
	exit 1
fi

# Caddy génère la CA au premier handshake TLS — on attend qu'elle existe.
for _ in $(seq 1 30); do
	if docker exec "$CADDY_CONTAINER" test -f "$CA_PATH_IN_CONTAINER" 2>/dev/null; then
		break
	fi
	sleep 1
done

if ! docker exec "$CADDY_CONTAINER" test -f "$CA_PATH_IN_CONTAINER" 2>/dev/null; then
	echo "Erreur : CA Caddy non trouvée. Faire d'abord un curl https://*.ekylibre.test/" >&2
	echo "pour déclencher la génération de la CA, puis relancer ce script." >&2
	exit 1
fi

docker cp "$CADDY_CONTAINER:$CA_PATH_IN_CONTAINER" "$TMP_CA"

# 1) Store système (Debian/Ubuntu).
if [[ -d /usr/local/share/ca-certificates ]]; then
	if [[ -f "$CA_HOST_PATH" ]] && cmp -s "$TMP_CA" "$CA_HOST_PATH"; then
		echo "✓ CA système déjà à jour"
	else
		sudo install -m 644 "$TMP_CA" "$CA_HOST_PATH"
		sudo update-ca-certificates >/dev/null
		echo "✓ CA installée dans le store système"
	fi
fi

# 2) NSS (Firefox + Chromium-based).
if command -v certutil >/dev/null 2>&1; then
	for nss_db in "$HOME"/.pki/nssdb "$HOME"/.mozilla/firefox/*.default* "$HOME"/snap/firefox/common/.mozilla/firefox/*.default*; do
		[[ -d "$nss_db" ]] || continue
		certutil -d "sql:$nss_db" -D -n "Caddy Local Authority - Ekylibre Dev" 2>/dev/null || true
		certutil -d "sql:$nss_db" -A -t "C,," -n "Caddy Local Authority - Ekylibre Dev" -i "$TMP_CA"
		echo "✓ CA installée dans NSS : $nss_db"
	done
else
	echo "ℹ certutil absent (paquet libnss3-tools) — Firefox/Chrome ne valideront pas la CA tant qu'elle n'y est pas ajoutée manuellement."
fi

echo
echo "Redémarrer les navigateurs ouverts pour qu'ils rechargent le store."
