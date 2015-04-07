desc "Clean all"
task :clean do
  unless ENV["PLUGIN"]
    ENV["PLUGIN"] = "false"
  end
  Rake::Task[:environment].invoke
  [:themes, :schema, :annotations, :tests, :rights,
   :parts, :validations, :locales, :code].each do |cleaner|
    Rake::Task["clean:#{cleaner}"].invoke
  end
end
