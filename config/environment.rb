# Load the rails application
require File.expand_path('../application', __FILE__)
ENV['JAVA_HOME'] = "/usr/lib/jvm/java-1.7.0-openjdk-amd64"
# Initialize the rails application
Ekylibre::Application.initialize!
