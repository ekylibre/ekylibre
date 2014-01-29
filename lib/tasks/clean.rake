require File.join(File.expand_path(File.dirname(__FILE__)), "clean", "support")
cleans = [:themes, :schema, :annotations, :tests, :rights, :modules, :validations, :locales, :code] # , :diagrams
namespace :clean do
  for clean in cleans
    require File.join(File.expand_path(File.dirname(__FILE__)), "clean", clean.to_s)
  end
end

desc "Clean files -- also available " + cleans.collect{|c| "clean:#{c}"}.join(", ")
task :clean => [:environment] + cleans.collect{|c| "clean:#{c}"}
