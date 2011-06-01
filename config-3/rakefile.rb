# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'application'))
# require File.expand_path('../config/application', __FILE__)
# require 'rake'

Ekylibre::Application.load_tasks
