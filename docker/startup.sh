#!/usr/bin/env bash
set -e

if [ $RAILS_ENV == "development" ]; then
  cp -n docker/dev/.env.dist .env
  # `--path` est déprécié depuis Bundler 2 : le chemin vient de BUNDLE_PATH,
  # posé dans docker-compose.yml.
  bundle install
  yarn install --check-files

  # Clé de signature des tests, la même que celle de la CI. Elle vit dans le
  # trousseau du conteneur, donc elle disparaît à chaque reconstruction de
  # l'image — et la clôture d'exercice, l'archivage et l'impression signée
  # tombent alors sur « No usable secret GPG key found », sur ce poste
  # seulement. `config/environments/test.rb` fixe `GPG_EMAIL` sur cette
  # identité ; l'import est idempotent.
  gpg --batch --import test/fixture-files/my-private-key.asc 2>/dev/null || true
fi

if [ $RAILS_ENV == "production" ]; then
  DB_NAME=$DB_PROD_NAME
elif [ $RAILS_ENV == "development" ]; then
  DB_NAME=$DB_DEV_NAME
else
  DB_NAME=$DB_TEST_NAME
fi

DB_URI="postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}"

echo "==DB CREATE=="
bundle exec rake db:create

# Sur une base neuve — le cas de tout poste depuis le passage du serveur en
# PostgreSQL 18, qui impose un volume de données neuf — `rake db:migrate`
# commence par charger db/structure.sql avec ON_ERROR_STOP=1. Or le dump
# contient `CREATE SCHEMA postgis` et `CREATE SCHEMA public`, que
# docker/db/init.sql vient de créer pour y installer les extensions : le
# chargement s'arrête là, et le conteneur avec lui.
#
# Le dump est donc chargé à la main, sans arrêt sur erreur, et les seules
# erreurs tolérées sont ces schémas déjà présents. La CI résout le même
# problème de la même façon — voir .github/workflows/test.yml.
#
# Rejouer les migrations depuis zéro n'est pas un repli : `t.attachment`, que
# Paperclip fournissait, est encore employé par la migration de base et la gem
# est partie avec Active Storage.
if [ -z "$(psql -qtAX -d $DB_URI -c "SELECT to_regclass('public.schema_migrations')")" ]; then
    echo "==LOAD STRUCTURE (base neuve)=="
    psql -d $DB_URI --quiet --no-psqlrc --output /dev/null -f db/structure.sql 2> /tmp/psql-structure-load.err || true
    if grep -E '^psql:.*ERROR' /tmp/psql-structure-load.err | grep -qv 'already exists'; then
        echo "Erreurs inattendues au chargement du schéma :"
        cat /tmp/psql-structure-load.err
        exit 1
    fi
fi

echo "==DB MIGRATE=="
bundle exec rake db:migrate

# if args passed
if [[ $# -ge 1 ]]; then
    bash $*
fi

# La version chargée, pas l'existence du schéma : `db/structure.sql` déclare le
# schéma `lexicon` et ses tables, si bien qu'une base neuve le porte *vide*.
# L'ancien test — « le schéma existe donc le lexique est là » — passait alors
# dans la branche de comparaison de versions, où la requête ne rendait rien et
# où `[ != x ]` échouait sur « unary operator expected » : le lexique n'était
# jamais chargé, et le premier `first_run` partait sans référentiel.
#
# Une requête qui échoue (schéma ou table absents) vaut version vide, donc
# chargement — c'est le comportement voulu dans les deux cas.
LEXICON_LOADED_VERSION=$(psql -qtAX -d $DB_URI -c "SELECT version FROM lexicon.version" 2>/dev/null || true)
LEXICON_VERSION=$(cat .lexicon-version)

if [ "$LEXICON_LOADED_VERSION" != "$LEXICON_VERSION" ]; then
    echo "==LOAD LEXICON=="
    bundle exec rake lexicon:load
fi

if [ $RAILS_ENV == "production" ]; then
   echo "==START UNICORN=="
   bundle exec unicorn -c config/unicorn.rb
fi

if [ $RAILS_ENV == "development" ]; then
   echo "==START RAILS SERVER=="
   rm -f tmp/pids/server.pid
   ./bin/rails s -p 3000 -b '0.0.0.0';
fi
