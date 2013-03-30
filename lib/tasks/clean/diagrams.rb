require "rails_erd/diagram/graphviz"

desc "Analyze test files and report"
task :diagrams => :environment do
  print " - Diagram: "
  begin
    RailsERD.options.warn = false
    RailsERD.options.filename = Rails.root.join("doc", "models").to_s
    RailsERD.options.exclude = :user
    puts RailsERD::Diagram::Graphviz.create
  rescue StandardError => e
    puts "Error! see log to known details."
    log = File.open(Rails.root.join("log", "clean-diagram.log"), "wb")
    log.write e.class.name + "\n"
    log.write e.message + "\n"
    log.write "\nBacktrace: \n"
    log.write e.backtrace.join("\n")
    log.close
  end
end
