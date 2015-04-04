# encoding: utf-8
module Ekylibre

  module Parts

    class ReverseImpossible < StandardError
    end

    def self.file
      Rails.root.join("config", "parts.xml")
    end

    mattr_reader :hash, :reversions, :icons
    @@reversions = {}
    @@icons = ActiveSupport::OrderedHash.new
    File.open(file) do |f|
      doc = Nokogiri::XML(f) do |config|
        config.strict.nonet.noblanks
      end
      @@hash = doc.xpath('/parts/part').inject(ActiveSupport::OrderedHash.new) do |parts, element|
        part_name = element.attr("name").to_s.to_sym
        @@icons[part_name] = {:children => ActiveSupport::OrderedHash.new}
        @@icons[part_name][:icon] = element.attr("icon").to_s if element.attr("icon")
        parts[part_name] = element.xpath('group').inject(ActiveSupport::OrderedHash.new) do |groups, elem|
          group_name = elem.attr("name").to_s.to_sym
          @@icons[part_name][:children][group_name] = {:children => ActiveSupport::OrderedHash.new}
          @@icons[part_name][:children][group_name][:icon] = elem.attr("icon").to_s if elem.attr("icon")
          groups[group_name] = elem.xpath('item').inject(ActiveSupport::OrderedHash.new) do |items, e|
            item_name = e.attr("name")
            @@icons[part_name][:children][group_name][:children][item_name] = {:children => []}
            @@icons[part_name][:children][group_name][:children][item_name][:icon] = e.attr("icon").to_s if e.attr("icon")
            items[item_name] = e.xpath('page').collect do |p|
              url = p.attr("to").to_s.split('#')
              @@reversions[url[0]] ||= {}
              @@reversions[url[0]][url[1]] = [part_name, group_name, item_name]
              @@icons[part_name][:children][group_name][:children][item_name][:children] << {:controller => url[0], :action => url[1]}
              {:controller => "/" + url[0], :action => url[1]}
            end
            items
          end
          groups
        end
        parts
      end
    end

    # Returns the path (part, group, item) from an action
    def self.reverse(controller, action)
      path = nil
      if reversions[controller]
        path = reversions[controller][action.to_s]
      end
      return path
    end

    # Returns the path (part, group, item) from an action
    def self.reverse!(controller, action)
      unless path = self.reverse(controller, action)
        raise ReverseImpossible, "Cannot reverse action #{controller}##{action}"
      end
      return path
    end

    # Returns the name of the part corresponding to an URL
    def self.part_of(controller, action)
      return action.to_sym if controller.to_s == "backend/dashboards" and hash.keys.include?(action.to_sym)
      if r = reverse(controller, action)
        return r[0]
      end
      return nil
    end

    # Returns the name of the group corresponding to an URL
    def self.group_of(controller, action)
      return reverse(controller, action)[1]
    end

    # Returns the name of the item corresponding to an URL
    def self.item_of(controller, action)
      return reverse(controller, action)[2]
    end

    # Returns the group hash corresponding to the current part
    def self.groups_of(controller, action)
      return hash[part_of(controller, action)] || {}
    end

    # Reutns the group hash corresponding to the part
    def self.groups_in(part)
      return hash[part] || {}
    end

    # Returns a human name corresponding to the arguments
    # 1: part
    # 2: group
    # 3: item
    def self.human_name(*args)
      levels = [nil, :part, :group, :item]
      return self.send("#{levels[args.count]}_human_name", *args)
    end

    # Returns the human name of a group
    def self.part_human_name(part)
      ::I18n.translate("menus.#{part}".to_sym, default: ["labels.menus.#{part}".to_sym, "labels.#{part}".to_sym])
    end

    # Returns the human name of a group
    def self.group_human_name(part, group)
      ::I18n.translate(("menus." + [part, group].join(".")).to_sym, default: ["menus.#{group}".to_sym, "labels.menus.#{group}".to_sym, "labels.#{group}".to_sym])
    end

    # Returns the human name of an item
    def self.item_human_name(part, group, item)
      p = hash[part][group][item].first
      ::I18n.translate(("menus." + [part, group, item].join(".")).to_sym, default: ["menus.#{item}".to_sym, "labels.menus.#{item}".to_sym, "actions.#{p[:controller][1..-1]}.#{p[:action]}".to_sym, "labels.#{item}".to_sym])
    end


    def self.icon(*args)
      arg = args.shift
      h = @@icons[arg]
      while args.any?
        arg = args.shift
        h = h[:children][arg]
      end
      return h[:icon] || arg
    end

  end

end
