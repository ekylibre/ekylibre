# frozen_string_literal: true

env = ENV['RAILS_ENV'] || 'production'
worker_processes 3
listen 3000
preload_app false
timeout 300
pid '/home/ekylibre/web.pid'
working_directory '/app'
user 'ekylibre'
stderr_path '/app/log/unicorn.stderr.log'
stdout_path '/app/log/unicorn.stdout.log'
