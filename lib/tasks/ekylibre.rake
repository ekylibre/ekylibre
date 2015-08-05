# Load plugins rake tasks
Dir[File.join(Rails.root, 'plugins/*/lib/tasks/**/*.rake')].sort.each { |ext| load ext }
