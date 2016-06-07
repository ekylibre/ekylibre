require 'clean'

desc 'Clean all'
task :clean do
  ENV['PLUGIN'] = 'false' unless ENV['PLUGIN']
  ENV['CRON'] = '0' unless ENV['CRON']
  Rake::Task[:environment].invoke
  [:themes, :schema, :reflections, :tests, :annotations, :rights, :routes,
   :navigation, :validations, :locales, :views, :code].each do |cleaner|
    Rake::Task["clean:#{cleaner}"].invoke
  end
end
