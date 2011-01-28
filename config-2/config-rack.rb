# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
# require "config/environment" 
use Rails::Rack::LogTailer 
use Rails::Rack::Static 
run ActionController::Dispatcher.new 