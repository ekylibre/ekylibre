#! /bin/sh

until nc -z -v -w30 db 5432
do
  echo 'Waiting for PostgreSQL...'
  sleep 1
done
echo "PostgreSQL is up and running"

echo "==DB CREATE=="
bundle exec rake db:create

echo "==DB MIGRATE=="
bundle exec rake db:migrate 2>/dev/null

echo "==YARN INSTALL=="
yarn install

if [ "$RAILS_ENV" = "production" ]; then
   echo "==ASSETS PRECOMPILE=="
   bundle exec rake assets:precompile

   echo "==START UNICORN=="
   bundle exec unicorn -c config/unicorn.rb
fi

if [ "$RAILS_ENV" = "development" ]; then
   echo "==START PUMA=="
   bundle exec puma -C config/puma.rb
fi
