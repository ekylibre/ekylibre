#!/usr/bin/env bash
set -e
exec bundle exec sidekiq -C config/sidekiq.yml
