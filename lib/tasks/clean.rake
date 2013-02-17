require File.join(File.expand_path(File.dirname(__FILE__)), "clean", "support")
# cleans = [:rights, :menus, :models, :annotations, :views, :locales, :version, :sqlserver_fixes]
cleans = [:forms, :tests, :rights, :menus, :models, :validations, :annotations, :locales, :sqlserver_fixes, :code]
namespace :clean do
  for clean in cleans
    require File.join(File.expand_path(File.dirname(__FILE__)), "clean", clean.to_s)
  end
end

desc "Clean files -- also available "+cleans.collect{|c| "clean:#{c}"}.join(", ")
task :clean=>[:environment]+cleans.collect{|c| "clean:#{c}"}
