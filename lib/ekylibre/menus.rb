module Ekylibre

  def self.menus_file
    Rails.root.join("config", "menus.yml")
  end

  mattr_reader :menus, :menus_actions, :reverse_menus
  @@menus = ActiveSupport::OrderedHash.new
  @@menus_actions = ActiveSupport::OrderedHash.new
  @@reverse_menus = {}
  for menus in YAML.load_file(menus_file)['menus']
    for menu, _submenus in menus
      m = menu.to_sym
      @@menus[m] = ActiveSupport::OrderedHash.new
      @@menus_actions[m] = ActiveSupport::OrderedHash.new
      for submenus in _submenus
        for submenu, lists in submenus
          sm = submenu.to_sym
          @@menus[m][sm] = []
          @@menus_actions[m][sm] = []
          for list in lists
            if list.is_a? Array and list.size > 0
              a = list[0].split("::")
              @@menus[m][sm] << {:controller=>a[0].to_sym, :action=>a[1].to_sym}
              @@menus_actions[m][sm] += list
              for action in list
                @@reverse_menus[action] = [m, sm, list[0]]
              end
            end
          end if lists.is_a? Array
          @@reverse_menus["dashboards::#{m}"] = [m, :__hidden__, "dashboards::#{m}"]
        end
      end
    end
  end

end
