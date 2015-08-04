# Adds extra path to JAVA classpath
RjbLoader.before_load do |config|
  # This code changes the JVM classpath, so it has to run BEFORE loading Rjb.
  config.classpath << File::PATH_SEPARATOR + File.expand_path(Rails.root.join('config', 'reporting', 'beardley'))
  config.classpath << File::PATH_SEPARATOR + File.expand_path(Rails.root.join('app', 'themes', 'tekyla', 'fonts'))
end
