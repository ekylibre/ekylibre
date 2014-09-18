require File.join(File.expand_path(File.dirname(__FILE__)), "clean", "support")
cleaners = [:themes, :schema, :annotations, :tests, :rights, :modules, :validations, :locales, :code]
namespace :clean do
  for clean in cleaners
    require File.join(File.expand_path(File.dirname(__FILE__)), "clean", clean.to_s)
  end
end

desc "Clean files -- also available " + cleaners.collect{|c| "clean:#{c}"}.to_sentence
task clean: :environment do
  for cleaner in cleaners
    Rake::Task["clean:#{cleaner}"].invoke
  end
end
