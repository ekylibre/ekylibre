desc "Build db/schema.xml"

task :xmlize do
   require File.join(File.dirname(__FILE__), "../lib/xmlize.rb")
   Xmlize.build_schema
end
