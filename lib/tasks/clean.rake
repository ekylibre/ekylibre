require 'clean'

desc 'Clean all'
task :clean do
  ENV['PLUGIN'] = 'false' unless ENV['PLUGIN']
  Rake::Task[:environment].invoke
  [:themes, :schema, :reflections, :tests, :annotations, :rights, :routes, :puts,
   :navigation, :validations, :locales, :procedures, :views, :code].each do |cleaner|
    Rake::Task["clean:#{cleaner}"].invoke
  end
end
