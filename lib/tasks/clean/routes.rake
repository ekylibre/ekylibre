namespace :clean do

  desc "Check routes validity"
  task :routes => :environment do
    ref = Clean::Support.actions_hash
    log = File.open(Rails.root.join("log", "clean-routes.log"), "wb")
    missing_controllers = []
    missing_actions = []
    Rails.application.routes.routes.each do |route|
      r = route.requirements
      next unless controller = r[:controller] and action = r[:action]
      if ref[controller]
        unless ref[controller].include? r[:action]
          log.write "Missing action:     #{controller}##{action}\n"
          missing_actions << route
        end
      else
        unless missing_controllers.include?(controller)
          log.write "Missing controller: #{controller}\n"
          missing_controllers << controller
        end
      end
    end
    log.close
    puts " - Routes: #{missing_actions.count} missing actions and #{missing_controllers.count} missing controllers"
  end

end
