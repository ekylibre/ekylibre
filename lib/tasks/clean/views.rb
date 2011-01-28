#
desc "Look at bad and suspect views"
task :views => :environment do
  print " - Views: "

  views = []
  for controller_file in Dir.glob(Rails.root.join("app", "controllers", "*.rb")).sort
    source = ""
    File.open(controller_file, "rb") do |f|
      source = f.read
    end
    controller = controller_file.split(/[\\\/]+/)[-1].gsub('_controller.rb', '')
    for file in Dir.glob(Rails.root.join("app", "views", controller, "*.*")).sort
      action = file.split(/[\\\/]+/)[-1].split('.')[0]
      valid = false
      valid = true if not valid and source.match(/^\s*def\s+#{action}\s*$/)
      valid = true if not valid and action.match(/^_\w+_form$/) and (source.match(/^\s*def\s+#{action[1..-6]}_(upd|cre)ate\s*$/) or source.match(/^\s*manage\s*\:#{action[1..-6].pluralize}(\W|$)/))
      if action.match(/^_/) and not valid
        if source.match(/^[^\#]*(render|replace_html)[^\n]*partial[^\n]*#{action[1..-1]}/)
          valid = true 
        else
          for view in Dir.glob(Rails.root.join("app", "views", controller, "*.*"))
            File.open(view, "rb") do |f|
              view_source = f.read
              if view_source.match(/(render|replace_html)[^\n]*partial[^\n]*#{action[1..-1]}/)
                valid = true
                break
              end
            end
          end
        end
      end
      views << file.gsub(Rails.root.to_s, '.') unless valid
    end
  end
  print "#{views.size} potentially bad views\n"
  for view in views
    puts "   #{view}"
  end
end
