#!/usr/bin/env bash
set -e

echo "==DB CREATE=="
bundle exec rake db:create

echo "==DB MIGRATE=="
bundle exec rake db:migrate

# if args passed
if [[ $# -ge 1 ]]; then
    bash $*
fi

if [[ "$RAILS_ENV" = "production" ]]; then
   echo "==ASSETS PRECOMPILE=="
   bundle exec rake assets:precompile

   echo "==START UNICORN=="
   bundle exec unicorn -c config/unicorn.rb
fi

if [[ "$RAILS_ENV" = "development" ]]; then
   echo "==START PUMA=="
   bundle exec puma -C config/puma.rb
fi
