#!/usr/bin/env bash
set -e

if [ -z "$SECRET_KEY_BASE" ]; then
  echo "ERROR: SECRET_KEY_BASE is empty."
  echo "Generate one with: openssl rand -hex 64"
  echo "Then add it to docker/prod/.env"
  exit 1
fi

echo "==DB CREATE/MIGRATE=="
bundle exec rake db:create db:migrate

DB_URI="postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}/${DB_PROD_NAME}"

LEXICON_LOADED=$(psql -qtAX -d "$DB_URI" -c "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name='lexicon');")

if [ "$LEXICON_LOADED" = "f" ]; then
  echo "==LOAD LEXICON (premier demarrage — peut prendre 5-10 min)=="
  bundle exec rake lexicon:load
else
  LOADED_VER=$(psql -qtAX -d "$DB_URI" -c "SELECT version FROM lexicon.version;")
  WANTED_VER=$(cat .lexicon-version)
  if [ "$LOADED_VER" != "$WANTED_VER" ]; then
    echo "==UPDATE LEXICON ($LOADED_VER -> $WANTED_VER)=="
    bundle exec rake lexicon:load
  fi
fi

echo "==START PUMA=="
rm -f tmp/pids/server.pid
exec bundle exec puma -C config/puma.rb -e production -b tcp://0.0.0.0:3000
