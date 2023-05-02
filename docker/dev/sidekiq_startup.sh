#!/usr/bin/env bash
set -e

bundle install --path /app/vendor/bundle
bundle exec sidekiq