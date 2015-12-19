require 'clean'

desc 'Clean all'
task :clean do
  ENV['PLUGIN'] = 'false' unless ENV['PLUGIN']
  Rake::Task[:environment].invoke
  [:themes, :schema, :tests, :annotations, :rights, :routes,
   :navigation, :validations, :locales, :views, :code].each do |cleaner|
    Rake::Task["clean:#{cleaner}"].invoke
  end
end
