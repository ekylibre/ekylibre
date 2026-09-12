#!/usr/bin/env bash
set -e

# `--path` est déprécié depuis Bundler 2 : le chemin vient de BUNDLE_PATH, posé
# dans docker-compose.yml.
bundle install

exec bundle exec sidekiq -C config/sidekiq.yml
