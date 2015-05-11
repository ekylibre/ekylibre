require 'clean'

desc "Clean all"
task :clean do
  unless ENV["PLUGIN"]
    ENV["PLUGIN"] = "false"
  end
  Rake::Task[:environment].invoke
  [:themes, :schema, :annotations, :tests, :rights, :routes,
   :navigation, :validations, :locales, :views, :code].each do |cleaner|
    Rake::Task["clean:#{cleaner}"].invoke
  end
end
