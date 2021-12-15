require 'clean'

desc 'Clean all'
task :clean do
  ENV['PLUGIN'] = 'false' unless ENV['PLUGIN']
  Rake::Task[:environment].invoke
  # %i[themes schema reflections tests annotations rights routes puts
  # navigation validations locales procedures views code]
  %i[schema].each do |cleaner|
    Rake::Task["clean:#{cleaner}"].invoke
  end
end
