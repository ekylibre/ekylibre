#

desc "Update and sort config/menus.xml"
task :menus => :environment do
  print " - Menus: "
  menu_file = Rails.root.join("config", "menu.xml")

  # Read file
  doc = nil
  if File.exist?(menu_file)
    File.open(menu_file) do |f|
      doc = Nokogiri::XML(f) do |config|
        config.strict.nonet.noblanks
      end
    end
  else
    doc = Nokogiri::XML.new
    doc.root = Nokogiri::XML::Node.new('menu', doc)
  end

  # Removes undefined
  doc.xpath('//undefined').remove

  ref = actions_hash
  ref_actions = ref.collect{|c,a| a.collect{|x| "#{c}::#{x}"} }.flatten.sort
  # puts ref.inspect
  deleted = 0
  unused_actions = []
  for page in doc.xpath('//page')
    to = page.attr("to")
    url = to.to_s.strip.split("#")
    if ref[url[0]]
      page.remove_attribute('deletable')
      ref[url[0]].delete(url[1])
    else
      page['deletable'] = 'true'
      deleted += 1
    end
  end






  undefined = Nokogiri::XML::Node.new('undefined', doc)
  for controller, actions in ref.sort
    next unless actions.size > 0
    menu = Nokogiri::XML::Node.new('menu', doc)
    menu[:name] = controller
    if first = actions.delete("index")
      page = Nokogiri::XML::Node.new('page', doc)
      page[:to] = "#{controller}##{first}"
      menu.add_child(page)
      unused_actions << page[:to]
    end
    for action in actions.sort
      page = Nokogiri::XML::Node.new('page', doc)
      page[:to] = "#{controller}##{action}"
      menu.add_child(page)
      unused_actions << page[:to]
    end
    undefined.add_child(menu)
  end

  doc.root.add_child(undefined)
  File.open(menu_file, 'wb') do |f|
    f.write doc.to_s
  end
  print " #{unused_actions.size.to_s.rjust(3)} unused actions, #{deleted.to_s.rjust(3)} deletable actions\n"

end


desc "Update and sort menus.yml"
task :old_menus => :environment do
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
