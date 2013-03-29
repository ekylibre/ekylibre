require "rails_erd/diagram/graphviz"

desc "Analyze test files and report"
task :diagrams => :environment do
  print " - Diagram: "
  RailsERD.options.warn = false
  RailsERD.options.filename = Rails.root.join("doc", "models").to_s
  RailsERD.options.exclude = :user
  puts RailsERD::Diagram::Graphviz.create
end
