#
desc "Update and sort menus.yml"
task :menus => :environment do
  print " - Menus: "
  menus_file = Ekylibre.menus_file # Rails.root.join("config", "menus.yml")

  # Load file
  menus = YAML.load_file(menus_file)

  # Load list of all actions of all controllers
  ref = actions_hash
  ref_actions = ref.collect{|c,a| a.collect{|x| "#{c}::#{x}"} }.flatten.sort

  menus_actions = []
  for menu in menus['menus']
    for name, submenus in menu
      for submenu in submenus
        for name, menuitems in submenu
          menus_actions += menuitems||[]
        end
      end
    end
  end
  menus_actions.flatten!

  unused_actions = ref_actions - menus_actions

  deleted = 0

  yaml = ""
  yaml += "# Unused actions in menus\n" unless unused_actions.empty?
  for action in unused_actions.sort
    yaml += "#         - \"#{action}\"\n"
  end
  # yaml += "\n"
  yaml += "menus:\n"
  for menu in menus['menus']
    for menu_name, submenus in menu
      yaml += "  - #{menu_name}:\n"
      for submenu in submenus
        for submenu_name, lists in submenu
          yaml += "    - #{submenu_name}:\n"
          for list in lists
            if list.is_a? Array and list.size > 0
              # yaml += "      - [#{list.join(', ')}]\n"
              # yaml += "      - - #{list[0]}#{unexistent_action unless ref.include?(list[0])}\n"
              yaml += "      - "+([list[0]]+list[1..-1].sort).collect do |item|
                l = "        - \"#{item}\""
                unless ref_actions.include?(item)
                  deleted += 1
                  l += " # NONEXISTENT ACTION !!!"
                end
                l
              end.join("\n").strip+"\n"
              # lines
            end
          end if lists.is_a? Array
        end
      end
    end
  end

  File.open(menus_file, "wb") do |file|
    file.write yaml
  end
  print " #{unused_actions.size.to_s.rjust(3)} unused actions, #{deleted.to_s.rjust(3)} deletable actions\n"

end
