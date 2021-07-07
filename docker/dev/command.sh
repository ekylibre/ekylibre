#!/bin/bash

rm -f tmp/pids/server.pid
yarn install --check-files;
bundle install;
RAILS_ENV=development ./bin/rails s -p 3000 -b '0.0.0.0';
