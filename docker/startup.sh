#!/usr/bin/env bash
set -e

if [ $RAILS_ENV == "development" ]; then
  cp -n docker/dev/.env.dist .env
  bundle install --path vendor/bundle
  yarn install --check-files
fi

echo "==DB CREATE=="
bundle exec rake db:create

echo "==DB MIGRATE=="
bundle exec rake db:migrate

# if args passed
if [[ $# -ge 1 ]]; then
    bash $*
fi

if [ $RAILS_ENV == "production" ]; then
  DB_NAME=$DB_PROD_NAME
elif [ $RAILS_ENV == "development" ]; then
  DB_NAME=$DB_DEV_NAME
else
  DB_NAME=$DB_TEST_NAME
fi

DB_URI="postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}"

LEXICON_LOADED=$(psql -qtAX -d $DB_URI -c "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'lexicon');")

if [ $LEXICON_LOADED == 'f' ]; then
    echo "==LOAD LEXICON=="
    bundle exec rake lexicon:load
else
    LEXICON_LOADED_VERSION=$(psql -qtAX -d $DB_URI -c "SELECT version FROM lexicon.version;")
    LEXICON_VERSION=$(cat .lexicon-version)

    if [ $LEXICON_LOADED_VERSION != $LEXICON_VERSION ]; then
        echo "==LOAD LEXICON=="
        bundle exec rake lexicon:load
    fi
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
