#!/bin/bash

psql -U postgres -c "CREATE ROLE ekylibre PASSWORD 'md52b3b1e752e46adf9e731b38583a55289' NOSUPERUSER NOCREATEROLE CREATEDB INHERIT LOGIN;"
psql -U postgres -c "CREATE DATABASE ekylibre_production;"
psql -U postgres -d ekylibre_production -c "CREATE SCHEMA postgis;"
psql -U postgres -d ekylibre_production -c "CREATE EXTENSION postgis SCHEMA postgis;"
psql -U postgres -c "GRANT ALL PRIVILEGES ON ekylibre_production TO ekylibre;"

cp -f pkg/database.yml config/database.yml

JAVA_HOME=/usr/lib/jvm/java-7-openjdk NOKOGIRI_USE_SYSTEM_LIBRARIES=1 bundle exec rake db:migrate RAILS_ENV=production