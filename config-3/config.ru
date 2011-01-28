# This file is used by Rack-based servers to start the application.

require(File.join(File.dirname(__FILE__), 'config', 'environment'))
# require ::File.expand_path('../config/environment',  __FILE__)
run Ekylibre::Application
