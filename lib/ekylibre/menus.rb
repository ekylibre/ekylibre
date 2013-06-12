# encoding: utf-8
module Ekylibre

  module Modules

    class ReverseImpossible < StandardError
    end

    def self.file
      Rails.root.join("config", "modules.xml")
    end

    mattr_reader :hash, :reversions, :icons
    @@reversions = {}
    @@icons = ActiveSupport::OrderedHash.new
    File.open(file) do |f|
      doc = Nokogiri::XML(f) do |config|
        config.strict.nonet.noblanks
      end
      @@hash = doc.xpath('/modules/module').inject(ActiveSupport::OrderedHash.new) do |modules, element|
        module_name = element.attr("name").to_s.to_sym
        @@icons[module_name] = {:children => ActiveSupport::OrderedHash.new}
        @@icons[module_name][:icon] = element.attr("icon").to_s if element.attr("icon")
        modules[module_name] = element.xpath('group').inject(ActiveSupport::OrderedHash.new) do |groups, elem|
          group_name = elem.attr("name").to_s.to_sym
          @@icons[module_name][:children][group_name] = {:children => ActiveSupport::OrderedHash.new}
          @@icons[module_name][:children][group_name][:icon] = elem.attr("icon").to_s if elem.attr("icon")
          groups[group_name] = elem.xpath('item').inject(ActiveSupport::OrderedHash.new) do |items, e|
            item_name = e.attr("name")
            @@icons[module_name][:children][group_name][:children][item_name] = {:children => []}
            @@icons[module_name][:children][group_name][:children][item_name][:icon] = e.attr("icon").to_s if e.attr("icon")
            items[item_name] = e.xpath('page').collect do |p|
              url = p.attr("to").to_s.split('#')
              @@reversions[url[0]] ||= {}
              @@reversions[url[0]][url[1]] = [module_name, group_name, item_name]
              @@icons[module_name][:children][group_name][:children][item_name][:children] << {:controller => url[0], :action => url[1]}
              {:controller => url[0], :action => url[1]}
            end
            items
          end
          groups
        end
        modules
      end
    end

    # Returns the path (module, group, item) from an action
    def self.reverse(controller, action)
      return reversions[controller][action.to_s]
    rescue
      raise ReverseImpossible.new("Cannot reverse action #{controller}##{action}")
    end

    # Returns the name of the module corresponding to an URL
    def self.module_of(controller, action)
      return action.to_sym if controller.to_s == "backend/dashboards"
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

    # Returns the group hash corresponding to the current module
    def self.groups_of(controller, action)
      return hash[module_of(controller, action)] || {}
    end

    # Reutns the group hash corresponding to the module
    def self.groups_in(mod)
      return hash[mod] || {}
    end

    # Returns a human name corresponding to the arguments
    # 1: module
    # 2: group
    # 3: item
    def self.human_name(*args)
      levels = [nil, :module, :group, :item]
      return self.send("#{levels[args.count]}_human_name", *args)
    end

    # Returns the human name of a group
    def self.module_human_name(mod)
      ::I18n.translate("menus.#{mod}".to_sym, :default => ["labels.menus.#{mod}".to_sym, "labels.#{mod}".to_sym])
    end

    # Returns the human name of a group
    def self.group_human_name(mod, group)
      ::I18n.translate(("menus." + [mod, group].join(".")).to_sym, :default => ["menus.#{group}".to_sym, "labels.menus.#{group}".to_sym, "labels.#{group}".to_sym])
    end

    # Returns the human name of an item
    def self.item_human_name(mod, group, item)
      p = hash[mod][group][item].first
      ::I18n.translate(("menus." + [mod, group, item].join(".")).to_sym, :default => ["menus.#{item}".to_sym, "labels.menus.#{item}".to_sym, "actions.#{p[:controller]}.#{p[:action]}".to_sym, "labels.#{item}".to_sym])
    end


    def self.icon(*args)
      arg = args.shift
      h = @@icons[arg]
      while args.size > 0
        arg = args.shift
        h = h[:children][arg]
      end
      return h[:icon] || arg
    end


  end









  def self.menu_file
    Rails.root.join("config", "menu.xml")
  end

  module Navigation
    # Represents a way to acces to segments
    class Menu
      attr_reader :name, :pages, :items
      def initialize(parent, name, desc = {})
        @parent = parent
        @name = name.to_s.strip.to_sym
        @retro = {} if @parent.nil?
        @pages = []
        @items = ActiveSupport::OrderedHash.new

        # Adds pages
        for page in desc[:pages]
          self.add_page(page)
        end if desc[:pages]

        # Adds items
        for name, item in desc[:items]
          self.add_item(name, item)
        end if desc[:items]
      end

      def self.load_file(file)
        doc = nil
        File.open(file) do |f|
          doc = Nokogiri::XML(f) do |config|
            config.strict.nonet.noblanks
          end
        end
        # Convert to Hash
        desc = descify_element(doc.root)
        return Menu.new(nil, nil, desc)
      end

      def inspect
        "#{@name}(#{@items.size} items)\n"
      end

      def add_item(name, desc)
        raise Exception.new("Invalid menu element: #{desc.class.name}:#{desc.inspect}") unless desc.is_a?(Hash)
        name = name.to_s.strip.downcase.to_sym
        @items[name] = Menu.new(self, name, desc)
      end

      def add_page(page)
        page = Page.new(self, page)
        @pages << page
        retro[page.id] = page
      end

      # Returns the main ancestor of the hierarchy
      def ancestor
        return (@parent ? @parent.ancestor : self)
      end

      # Returns the retro hash
      def retro
        return (@parent ? @parent.retro : @retro)
      end

      # Returns the default action for a menu
      def default_page
        return (@pages.empty? ? @items.first.default_page : @pages.first)
      end

      # Browse all items
      def each(&block)
        @items.values.each do |item|
          yield(item)
        end
        return @items.size
      end

      # Browse all names
      def each_names(&block)
        @items.keys.each do |name|
          yield(name)
        end
        return @items.size
      end

      # Detect if a page is in rhe menu is the way to the given page
      def in_path?(controller, action)
        if page = ancestor.page(controller, action)
          return (page.hierarchy.include?(self) ? true : false)
        else
          return false
        end
      end

      # Returns all menus with sub-menus
      def with_menus
        list = []
        if @items.count > 0
          list << self
          for name, item in @items
            list += item.with_menus if item.items.count > 0
          end
        end
        return list
      end

      def hierarchy
        list = []
        unless @parent.nil?
          list += @parent.hierarchy
        end
        list << self
        return list
      end

      # Find a page
      def page(controller, action)
        return @retro[controller.to_s + '#' + action.to_s]
      end

      # Find a menu by page
      def find_by_page(controller, action)
        return self.page(controller, action).parent
      end

      def human_name
        p = default_page
        ::I18n.translate(("menus." + self.hierarchy.collect{|m| m.name}.join(".")).to_sym, :default => ["menus.#{@name}".to_sym, "labels.menus.#{@name}".to_sym, "actions.#{p.controller}.#{p.action}".to_sym, "labels.#{@name}".to_sym])
      end

      def useful
        return (self.items.size.zero? ? @parent.useful : self)
      end

      private

      def self.descify_element(element)
        desc = {}
        for e in element.children
          if e.name == "menu"
            desc[:items] ||= {}
            desc[:items][e.attr('name')] = descify_element(e)
          elsif e.name == "page"
            desc[:pages] ||= []
            desc[:pages] << e.attr('to')
          else
            # Just ignore
          end
        end
        return desc
      end

    end



    class Page
      attr_reader :controller, :action, :id, :parent
      def initialize(parent, item)
        @parent = parent
        page = item.to_s.gsub(/\s*/, '').downcase.split("#")
        @controller = page[0].to_sym
        @action = page[1].to_sym
        @id = @controller.to_s + '#' + @action.to_s
      end

      def hierarchy
        list = []
        if @parent
          list += @parent.hierarchy
        end
        list << self
        return list
      end

      def url_options
        {:controller => @controller, :action => @action}
      end

      def useful_menu
        return (@parent.items.size > 0 ? @parent : @parent.useful)
      end

    end

  end

  mattr_reader :menu
  @@menu = Navigation::Menu.load_file(menu_file)

  # Adds dashboards


  # mattr_reader :menus, :menus_actions, :reverse_menus
  # @@menus = ActiveSupport::OrderedHash.new
  # @@menus_actions = ActiveSupport::OrderedHash.new
  # @@reverse_menus = {}
  # for menus in YAML.load_file(menus_file)['menus']
  #   for menu, _submenus in menus
  #     m = menu.to_sym
  #     @@menus[m] = ActiveSupport::OrderedHash.new
  #     @@menus_actions[m] = ActiveSupport::OrderedHash.new
  #     for submenus in _submenus
  #       for submenu, lists in submenus
  #         sm = submenu.to_sym
  #         @@menus[m][sm] = []
  #         @@menus_actions[m][sm] = []
  #         for list in lists
  #           if list.is_a? Array and list.size > 0
  #             a = list[0].split("::")
  #             @@menus[m][sm] << {:controller => a[0].to_sym, :action => a[1].to_sym}
  #             @@menus_actions[m][sm] += list
  #             for action in list
  #               @@reverse_menus[action] = [m, sm, list[0]]
  #             end
  #           end
  #         end if lists.is_a? Array
  #         @@reverse_menus["dashboards::#{m}"] = [m, :__hidden__, "dashboards::#{m}"]
  #       end
  #     end
  #   end
  # end

end
