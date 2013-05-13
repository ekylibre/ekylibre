# encoding: utf-8
# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ##### END LICENSE BLOCK #####

# encoding: utf-8

module ApplicationHelper

  # Helper which check authorization of an action
  def authorized?(url_options = {})
    self.controller.authorized?(url_options)
  end


  def selector_tag(name, choices = nil, options = {}, html_options = {})
    choices ||= :unroll
    choices = {:action => choices} if choices.is_a?(Symbol)
    return text_field_tag(name, nil, html_options.merge('data-selector' => url_for(choices)))
  end


  def selector(object_name, association, choices, options = {}, html_options = {})
    object = options[:object] || instance_variable_get("@#{object_name}")
    model = object.class
    unless reflection = object.class.reflections[association.to_sym]
      raise ArgumentError.new("Unknown reflection for #{model.name}: #{association.inspect}")
    end
    raise ArgumentError.new("Reflection #{reflection.name} must be a belongs_to") if reflection.macro != :belongs_to
    return text_field(object_name, reflection.foreign_key, html_options.merge('data-selector' => url_for(choices)))
  end

  # It's the menu generated for the current user
  # Therefore: No current user => No menu
  def menus
    Ekylibre.menu # session[:menu]
  end

  # Return an array of menu and submenu concerned by the action (controller#action)
  def reverse_menus(action=nil)
    # action ||= "#{self.controller.controller_name}##{action_name}"
    # Ekylibre.reverse_menus[action]||[]
    return []
    Ekylibre.menu.stack(controller_name, action_name)
  end

  # LEGALS_ITEMS = [h("Ekylibre " + Ekylibre.version),  h("Ruby on Rails " + Rails.version),  h("Ruby "+ RUBY_VERSION.to_s)].join(" &ndash; ".html_safe).freeze

  def legals_sentence
    # "Ekylibre " << Ekylibre.version << " - Ruby on Rails " << Rails.version << " - Ruby #{RUBY_VERSION} - " << ActiveRecord::Base.connection.adapter_name << " - " << ActiveRecord::Migrator.current_version.to_s
    nbsp = "&nbsp;".html_safe # ,  h("Ruby on Rails") + nbsp + Rails.version, ("HTML" + nbsp + "5").html_sa, h("CSS 3")
    return [h("Ekylibre") + nbsp + Ekylibre.version,  h("Ruby") + nbsp + RUBY_VERSION.to_s].join(" &ndash; ").html_safe
  end

  def choices_yes_no
    [ [::I18n.translate('general.y'), true], [I18n.t('general.n'), false] ]
  end

  def radio_yes_no(name, value=nil)
    radio_button_tag(name, 1, value.to_s=="1", id => "#{name}_1") <<
      content_tag(:label, ::I18n.translate('general.y'), :for => "#{name}_1") <<
      radio_button_tag(name, 0, value.to_s=="0", id => "#{name}_0") <<
      content_tag(:label, ::I18n.translate('general.n'), :for => "#{name}_0")
  end

  def radio_check_box(object_name, method, options = {}, checked_value = "1", unchecked_value = "0")
    # raise Exception.new eval("@#{object_name}.#{method}").inspect
    radio_button_tag(object_name, method, TrueClass, :id => "#{object_name}_#{method}_#{checked_value}") << " " <<
      content_tag(:label, ::I18n.translate('general.y'), :for => "#{object_name}_#{method}_#{checked_value}") << " " <<
      radio_button_tag(object_name, method, FalseClass, :id => "#{object_name}_#{method}_#{unchecked_value}") << " " <<
      content_tag(:label, ::I18n.translate('general.n'), :for => "#{object_name}_#{method}_#{unchecked_value}")
  end

  def number_to_accountancy(value)
    number = value.to_f
    if number.zero?
      return ''
    else
      number_to_currency(number, :precision => 2, :format => '%n', :delimiter => '&nbsp;', :separator => ',')
    end
  end

  def number_to_management(value)
    number = value.to_f
    number_to_currency(number, :precision => 2, :format => '%n', :delimiter => '&nbsp;', :separator => ',')
  end

  # Take an extra argument which will translate
  def number_to_money(amount, currency, options={})
    return unless amount and currency
    return currency.to_currency.localize(amount, options)
  end






  def preference(name)
    # name = self.controller.controller_name.to_s << name.to_s if name.to_s.match(/^\./)
    @current_company.preference(name)
  end

  def locale_selector
    # , :selected => ::I18n.locale)
    locales = ::I18n.active_locales.sort{|a,b| a.to_s <=> b.to_s}
    locale = nil # ::I18n.locale
    if params[:locale].to_s.match(/^[a-z][a-z][a-z]$/)
      locale = params[:locale].to_sym if locales.include? params[:locale].to_sym
    end
    locale ||= ::I18n.locale||::I18n.default_locale
    options = locales.collect do |l|
      content_tag(:option, ::I18n.translate("i18n.name", :locale => l), {:value => l, :dir => ::I18n.translate("i18n.dir", :locale => l)}.merge(locale == l ? {:selected => true} : {}))
    end.join.html_safe
    select_tag("locale", options, "data-redirect" => url_for())
  end


  def link_to_remove_nested_association(name, f)
    return link_to_remove_association(content_tag(:i) + h("labels.remove_#{name}".t), f, 'data-no-turbolink' => true, :class => "nested-remove remove-#{name}")
  end


  # Re-writing of link_to helper
  def link_to(*args, &block)
    if block_given?
      options      = args.first || {}
      html_options = args.second
      link_to(capture(&block), options, html_options)
    else
      name         = args[0]
      options      = args[1] || {}
      html_options = args[2] || {}

      if options.is_a? Hash
        return (html_options[:remove] ? "" : "<a class='forbidden' disabled='true'>#{name}</a>".html_safe) unless authorized?(options)
      end

      html_options = convert_options_to_data_attributes(options, html_options)
      url = url_for(options)

      if html_options
        html_options = html_options.stringify_keys
        href = html_options['href']
        tag_options = tag_options(html_options)
      else
        tag_options = nil
      end

      href_attr = "href=\""+url+"\"" unless href
      "<a #{href_attr}#{tag_options}>".html_safe+(name || url)+"</a>".html_safe
    end
  end

  def li_link_to(*args)
    options      = args[1] || {}
    # if authorized?({:controller => controller_name, :action => action_name}.merge(options))
    if authorized?({:controller => controller_name, :action => :index}.merge(options))
      content_tag(:li, link_to(*args).html_safe)
    else
      ''
    end
  end

  def countries
    [[]]+t('countries').to_a.sort{|a, b| a[1].ascii.to_s <=> b[1].ascii.to_s}.collect{|a| [a[1].to_s, a[0].to_s]}
  end

  def currencies
    I18n.active_currencies.values.sort{|a, b| a.name.ascii.to_s <=> b.name.ascii.to_s}.collect{|c| [c.label, c.code]}
  end

  def languages
    I18n.valid_locales.collect{|l| [t("languages.#{l}"), l.to_s]}.to_a.sort{|a, b| a[0].ascii.to_s <=> b[0].ascii.to_s}
  end

  def back_url
    if session[:history].is_a?(Array) and session[:history][0].is_a?(Hash)
      return session[:history][0][:url]
    else
      return :back
    end
  end

  def link_to_back(options={})
    link_to(tg(options[:label]||'back'), back_url)
  end

  #


  #
  def evalue(object, attribute, options={})
    label, value = attribute_item(object, attribute, options={})
    if options[:orient] == :vertical
      code  = content_tag(:tr, content_tag(:td, label.to_s, :class => :label))
      code << content_tag(:tr, content_tag(:td, value.to_s, :class => :value))
      return content_tag(:table, code, :class => "evalue verti")
    else
      code  = content_tag(:td, label.to_s, :class => :label)
      code << content_tag(:td, value.to_s, :class => :value)
      return content_tag(:table, content_tag(:tr, code), :class => "evalue hori")
    end
  end


  def attribute_item(object, attribute, options={})
    value_class = 'value'
    if object.is_a? String
      label = object
      value = attribute
      value = value.to_s unless [String, TrueClass, FalseClass].include? value.class
    else
      #     label = object.class.human_attribute_name(attribute.to_s)
      value = object.send(attribute)
      model = object.class
      model_name = model.name.underscore
      default = ["activerecord.attributes.#{model_name}.#{attribute.to_s}_id".to_sym]
      default << "activerecord.attributes.#{model_name}.#{attribute.to_s[0..-7]}".to_sym if attribute.to_s.match(/_label$/)
      default << "attributes.#{attribute.to_s}".to_sym
      default << "attributes.#{attribute.to_s}_id".to_sym
      label = ::I18n.translate("activerecord.attributes.#{model_name}.#{attribute.to_s}".to_sym, :default => default)
      if value.is_a? ActiveRecord::Base
        record = value
        value = record.send(options[:label]||[:label, :name, :code, :number, :inspect].detect{|x| record.respond_to?(x)})
        options[:url] = {:action => :show} if options[:url].is_a? TrueClass
        if options[:url].is_a? Hash
          options[:url][:id] ||= record.id
          # raise [model_name.pluralize, record, record.class.name.underscore.pluralize].inspect
          options[:url][:controller] ||= record.class.name.underscore.pluralize
        end
      else
        options[:url] = {:action => :show} if options[:url].is_a? TrueClass
        if options[:url].is_a? Hash
          options[:url][:controller] ||= object.class.name.underscore.pluralize
          options[:url][:id] ||= object.id
        end
      end
      value_class  <<  ' code' if attribute.to_s == "code"
    end
    if [TrueClass, FalseClass].include? value.class
      value = content_tag(:div, "", :class => "checkbox-#{value}")
    elsif value.respond_to?(:text)
      value = value.send(:text)
    elsif attribute.to_s.match(/(^|_)currency$/)
      value = value.to_currency.label
    elsif options[:currency] and value.is_a?(Numeric)
      value = ::I18n.localize(value, :currency => (options[:currency].is_a?(TrueClass) ? object.send(:currency) : options[:currency]))
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif value.respond_to?(:strftime) or value.is_a?(Numeric)
      value = ::I18n.localize(value)
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif options[:duration]
      duration = value
      duration = duration*60 if options[:duration]==:minutes
      duration = duration*3600 if options[:duration]==:hours
      hours = (duration/3600).floor.to_i
      minutes = (duration/60-60*hours).floor.to_i
      seconds = (duration - 60*minutes - 3600*hours).round.to_i
      value = tg(:duration_in_hours_and_minutes, :hours => hours, :minutes => minutes, :seconds => seconds)
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif value.is_a? String
      classes = []
      classes << "code" if attribute.to_s == "code"
      classes << value.class.name.underscore
      value = link_to(value.to_s, options[:url]) if options[:url]
      value = content_tag(:div, value.html_safe, :class => classes.join(" "))
    end
    return label, value
  end


  def attributes_list(record, options={}, &block)
    columns = options[:columns] || 3
    attribute_list = AttributesList.new(record)
    raise ArgumentError.new("One parameter needed") unless block.arity == 1
    yield attribute_list if block_given?
    unless options[:without_custom_fields]
      unless attribute_list.items.detect{|item| item[0] == :custom_fields}
        attribute_list.custom_fields
      end
    end
    unless options[:without_stamp]
      attribute_list.attribute :creator, :label => :full_name
      attribute_list.attribute :created_at
      attribute_list.attribute :updater, :label => :full_name
      attribute_list.attribute :updated_at
      # attribute_list.attribute :lock_version
    end
    code = ""
    items = attribute_list.items.delete_if{|x| x[0] == :custom_fields}
    size = items.size
    if size > 0
      for item in items
        label, value = if item[0] == :custom
                         attribute_item(*item[1])
                       elsif item[0] == :attribute
                         attribute_item(record, *item[1])
                       end
        code << content_tag(:dl, content_tag(:dt, label) + content_tag(:dd, value))
      end
      code = content_tag(:div, code.html_safe, :class => "attributes-list")
    end
    return code.html_safe
  end

  class AttributesList
    attr_reader :items
    def initialize(object)
      @items = []
      @object = object
    end

    def attribute(*args)
      @items << [:attribute, args]
    end

    def custom(*args)
      @items << [:custom, args]
    end

    def custom_fields(*args)
      for custom_field in @object.custom_fields
        value = @object.custom_value(custom_field)
        unless value.blank?
          self.custom(custom_field.name, value)
        end
      end
      @items << [:custom_fields]
    end

  end


  def svg(options = {}, &block)
    return content_tag(:svg, capture(&block))
  end



  # 巣 Beehive permits to create modular interface organized in cells
  def beehive(name = nil, &block)
    html = ""
    return html unless block_given?
    name ||= "#{controller_name}_#{action_name}".to_sym
    board = Beehive.new(name)
    if block.arity < 1
      board.instance_eval(&block)
    else
      block[board]
    end

    return render(:partial => "backend/beehive", :object => board)

    html << "<div class=\"beehive beehive-#{board.name}\">"
    for box in board.boxes
      count = box.size
      next if count.zero?

      if box.is_a?(Beehive::HorizontalBox)
        html << "<div class=\"box box-h box-#{count}-cells\">"
        box.each_with_index do |cell, index|
          html << "<div class=\"cell cell-#{index+1}\">"
          html << "<span class=\"cell-title\">" + cell.title + "</span>"
          if cell.block?
            html << content_tag(:div, capture(&cell.block), :class => "cell-inner")
          else
            html << "<div class=\"cell-inner\" data-cell=\""+ url_for(:controller => "backend/cells/#{cell.name}_cells", :action => :show)+"\"></div>"
          end
          html << "</div>"
        end
        html << "</div>"
      elsif box.is_a?(Beehive::TabBox)
        html << "<div class=\"box box-tab box-#{count}-cells\">"
        panes = "<div class=\"box-panes\">"
        html << "<ul>"
        box.each_with_index do |cell, index|
          html << "<li class=\"cell cell-#{index+1}\"><a href=\"#\">Tab</a></li>"
          if cell.block?
            panes << content_tag(:div, capture(&cell.block), :class => "box-pane")
          else
            panes << "<div class=\"box-pane\" data-cell=\""+ url_for(:controller => "backend/cells/#{cell.name}_cells", :action => :show)+"\"></div>"
          end
        end
        html << "</ul>"
        panes << "</div>"
        html << panes
        html << "</div>"
      end

    end
    html << "</div>"
    return html.html_safe
  end

  class Beehive
    attr_reader :name, :boxes

    class TabBox < Array
      def self.short_name
        "tab"
      end
    end

    class HorizontalBox < Array
      def self.short_name
        "h"
      end
    end

    class Cell
      attr_reader :block, :name
      def initialize(name, options = {}, &block)
        @name = name
        @options = options
        @block = block if block_given?
      end
      def block?
        !@block.nil?
      end
      def title
        @options[:title] || (@name.is_a?(String) ? @name : ::I18n.t("labels.#{@name}"))
      end

      def content
        "Content"
      end
    end

    def initialize(name)
      @name = name
      @boxes = []
      @current_box = nil
    end

    def cell(name = :details, options = {}, &block)
      c = Cell.new(name, options, &block)
      if @current_box
        @current_box << c
      else
        box = HorizontalBox.new
        box << c
        @boxes << box
      end
    end

    def hbox(&block)
      raise Exception.new("Cannot define box in othre box") if @current_box
      @current_box = HorizontalBox.new
      block[self] if block_given?
      @boxes << @current_box unless @current_box.empty?
      @current_box = nil
    end

    def tabbox(&block)
      raise Exception.new("Cannot define box in other box") if @current_box
      @current_box = TabBox.new
      block[self] if block_given?
      @boxes << @current_box unless @current_box.empty?
      @current_box = nil
    end

  end






  def last_page(menu)
    session[:last_page][menu.to_s]||url_for(:controller => :dashboards, :action => menu)
  end


  def doctype_tag
    return "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN\" \"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd\">".html_safe
  end



  # Permits to use themes for Ekylibre
  #  stylesheet_link_tag 'application', 'list', 'list-colors'
  #  stylesheet_link_tag 'print', :media => 'print'
  def theme_link_tag(name=nil)
    name ||= 'tekyla'
    code = ""
    Dir.chdir(Rails.root.join("app", "assets", "stylesheets", "themes", name)) do
      for media in ["all", "embossed", "handheld", "print", "projection", "screen", "speech", "tty", "tv"]
        if File.exist?(media+".css") or File.exist?(media+".css.scss")
          code << stylesheet_link_tag("themes/#{name}/#{media}.css", :media => media)+"\n"
        end
      end
    end
    return code.html_safe
  end


  def theme_button(name, theme='tekyla')
    image_path("themes/#{theme}/buttons/#{name}.png").to_s
  end


  def resizable?
    return (session[:view_mode] == "resized" ? true : false)
  end

  def navigation_tag
    session[:last_page] ||= {}
    render :partial => "layouts/navigation"
  end

  def meta_viewport_tag
    tag(:meta, :name => "viewport", :content => "width=device-width, initial-scale=1.0, maximum-scale=1.0")
  end

  def title_tag
    r = [] # reverse_menus
    title = if @current_user
              code = URI::parse(request.url).host # .split(".")[-3].to_s
              if r.empty?
                tc(:page_title_special, :company_code => code, :action => controller.human_action_name)
              else
                tc(:page_title, :company_code => code, :action => controller.human_action_name, :menu => tl("menus.#{r[0]}"))
              end
            else
              tc(:page_title_by_default, :action => controller.human_action_name)
            end
    return ("<title>" << h(title) << "</title>").html_safe
  end


  def heading_tag
    return content_tag(:h1, controller.human_action_name, :id => :title)
    # heading = "".html_safe
    # unless (rm = reverse_menus).empty?
    #   heading << link_to("labels.menus.#{rm[0]}".t, last_page(rm[0]), :class => :module)
    #   heading << content_tag(:span, "/", :class => "separator")
    # end
    # heading << content_tag(:span, controller.human_action_name, :class => :leaf)
    # content_tag(:h1, heading, :id => :title)
  end

  def subheading(i18n_key, options={})
    raise Exception.new("A subheading has already been given.") if content_for?(:subheading)
    content_for(:subheading, tl(i18n_key, options))
  end

  def subheading_tag
    if content_for?(:subheading)
      return content_tag(:h2, content_for(:subheading), :id => :subtitle)
    end
    return nil
  end



  def side_tag # (submenu = self.controller.controller_name.to_sym)
    path = reverse_menus
    return '' if path.nil?
    render(:partial => 'layouts/side', :locals => {:path => path})
  end

  def side_menu(options={}, &block)
    return "" unless block_given?
    menu = Menu.new
    yield menu

    html = "".html_safe
    for args in menu.items
      name = args[0]
      args[1] ||= {}
      args[2] ||= {}
      li_options = {}
      if args[2].delete(:active)
        li_options[:class] = 'active'
      end
      if name.is_a?(Symbol)
        kontroller = (args[1].is_a?(Hash) ? args[1][:controller] : nil) || controller_name
        args[0] = ::I18n.t("actions.#{kontroller}.#{name}".to_sym, {:default => ["labels.#{name}".to_sym]}.merge(args[2].delete(:i18n)||{}))
      end
      if icon = args[2].delete(:icon)
        args[0] = content_tag(:i, '', :class => "icon-"+icon.to_s) + ' '.html_safe + h(args[0])
      end
      if name.is_a? Symbol and name!=:back
        args[1][:action] ||= name if args[1].is_a?(Hash)
      end
      html << content_tag(:li, link_to(*args), li_options) if authorized?(args[1])
    end

    content_for(:aside, content_tag(:ul, html.html_safe, :class => "side-menu"))

    return nil
  end

  class Menu
    attr_reader :items

    def initialize
      @items = []
    end

    def link(name, *args)
      @items << [name, *args]
    end
  end


  def side_module(name, options={}, &block)
    session[:modules] ||= {}
    session[:modules][name.to_s] = true unless [TrueClass, FalseClass].include?(session[:modules][name.to_s].class)
    shown = session[:modules][name]
    html = ""
    html << "<div class='sd-module#{' '+options[:class].to_s if options[:class]}#{' collapsed' unless shown}'>"
    html << "<div class='sd-title'>"
    html << link_to("", {:action => :toggle_module, :controller => :interfacers}, "data-toggle-module" => name, :class => (shown ? :hide : :show))
    html << "<h2>" + (options[:title]||tl(name)) + "</h2>"
    html << "</div>"
    html << "<div class='sd-content'" + (shown ? '' : ' style="display: none"') + ">"
    begin
      html << capture(&block)
    rescue Exception => e
      html << content_tag(:small, "#{e.class.name}: #{e.message}")
    end
    html << "</div>"
    html << "</div>"
    return html.html_safe
  end


  def notification_tag(mode)
    # content_tag(:div, flash[mode], :class => 'flash ' << mode.to_s) unless flash[mode].blank?
    code = ''
    if flash[:notifications].is_a?(Hash) and flash[:notifications][mode].is_a?(Array)
      for message in flash[:notifications][mode]
        message.force_encoding('UTF-8') if message.respond_to? :force_encoding
        code << "<div class='flash #{mode}' data-alert=\"true\"><div class='icon'></div><div class='message'><h3>#{tg('notifications.' << mode.to_s)}</h3><p>#{h(message).gsub(/\n/, '<br/>')}</p></div><a href=\"#\" class=\"close\">&times;</a></div>" # <div class='end'></div>
      end
    end
    code.html_safe
  end

  def notifications_tag
    return notification_tag(:error) <<
      notification_tag(:warning) <<
      notification_tag(:success) <<
      notification_tag(:information)
  end


  def table_of(array, html_options={}, &block)
    coln = html_options.delete(:columns)||3
    html, item, size = "", "", 0
    for item in array
      item << content_tag(:td, capture(item, &block))
      size += 1
      if size >= coln
        html << content_tag(:tr, item).html_safe
        item, size = "", 0
      end
    end
    html << content_tag(:tr, item).html_safe unless item.blank?
    return content_tag(:table, html, html_options).html_safe
  end





  # Kujaku 孔雀
  # Search bar
  def kujaku(url_options = {}, options = {}, &block)
    k = Kujaku.new(caller[0].split(":in ")[0])
    if block_given?
      yield k
    else
      k.text
    end
    return "" if k.criteria.size.zero?
    crits = "".html_safe
    k.criteria.each_with_index do |c, index|
      code, opts = "", c[:options]||{}
      if c[:type] == :mode
        code = content_tag(:label, opts[:label]||tg(:mode))
        name = c[:name]||:mode
        params[name] ||= c[:modes][0].to_s
        i18n_root = opts[:i18n_root]||'labels.criterion_modes.'
        for mode in c[:modes]
          radio  = radio_button_tag(name, mode, params[name] == mode.to_s)
          radio << " "
          radio << content_tag(:label, ::I18n.translate("#{i18n_root}#{mode}"), :for => "#{name}_#{mode}")
          code << " ".html_safe << content_tag(:span, radio.html_safe, :class => :rad)
        end
      elsif c[:type] == :radio
        code = content_tag(:label, opts[:label]||tg(:state))
        params[c[:name]] ||= c[:states][0].to_s
        i18n_root = opts[:i18n_root]||"labels.#{controller_name}_states."
        for state in c[:states]
          radio  = radio_button_tag(c[:name], state, params[c[:name]] == state.to_s)
          radio << " ".html_safe << content_tag(:label, ::I18n.translate("#{i18n_root}#{state}"), :for => "#{c[:name]}_#{state}")
          code  << " ".html_safe << content_tag(:span, radio.html_safe, :class => :rad)
        end
      elsif c[:type] == :text
        code = content_tag(:label, opts[:label]||tg(:search))
        name = c[:name]||:q
        session[:kujaku] = {} unless session[:kujaku].is_a? Hash
        params[name] = session[:kujaku][c[:uid]] = (params[name]||session[:kujaku][c[:uid]])
        code << " ".html_safe << text_field_tag(name, params[name])
      elsif c[:type] == :date
        code = content_tag(:label, opts[:label]||tg(:select_date))
        name = c[:name]||:d
        code << " ".html_safe << date_field_tag(name, params[name])
      elsif c[:type] == :crit
        code << send("#{c[:name]}_crit", *c[:args])
      elsif c[:type] == :criterion
        code << capture(&c[:block])
      end
      html_options = (c[:html_options]||{}).merge(:class => "crit")
      html_options[:class] << " hideable" unless index.zero?
      crits << content_tag(:div, code.html_safe, html_options)
    end
    # TODO: Add link to unhide hidden criteria
    launch = button_tag(content_tag(:i) + h(tl(:search_go)), 'data-disable-with' => tg(:please_wait), :name => nil)
    tag = content_tag(:div, launch, :class => :submit) + content_tag(:div, crits, :class => :crits)
    tag = form_tag(url_options, :method => :get) { tag } unless options[:form].is_a?(FalseClass)
    id = Time.now.to_i.to_s(36)+(10000*rand).to_i.to_s(36)

    if options[:popover].is_a?(FalseClass)
      return content_tag(:div, tag.to_s.html_safe, :class => "kujaku", :id => id)
    else
      content_for(:popover, content_tag(:div, tag.to_s.html_safe, :class => "kujaku popover", :id => id))
      tool(content_tag(:a, content_tag(:span, nil, :class => :icon) + content_tag(:span, "Rechercher", :class => :text), :class => "btn btn-search", "data-toggle-visibility" => "##{id}"))
      return ""
    end
  end

  class Kujaku
    attr_reader :criteria
    def initialize(uid)
      @uid = uid
      @criteria = []
    end

    # def mode(*modes)
    #   options = modes.delete_at(-1) if modes[-1].is_a? Hash
    #   options = {} unless options.is_a? Hash
    #   @criteria << {:type => :mode, :modes => modes, :options => options}
    # end

    def radio(*states)
      options = (states[-1].is_a?(Hash) ? states.delete_at(-1) : {})
      name = options.delete(:name) || :s
      add_criterion :radio, :name => name, :states => states, :options => options
    end

    def text(name=nil, options={})
      name ||= :q
      add_criterion :text, :name => name, :options => options
    end

    def date(name=nil, options={})
      name ||= :d
      add_criterion :date, :name => name, :options => options
    end

    def crit(name=nil, *args)
      add_criterion :crit, :name => name, :args => args
    end

    def criterion(html_options={}, &block)
      raise ArgumentError.new("No block given") unless block_given?
      add_criterion :criterion, :block => block, :html_options => html_options
    end

    private

    def add_criterion(type=nil, options={})
      @criteria << options.merge(:type => type, :uid => "#{@uid}:"+@criteria.size.to_s)
    end
  end


  # TOOLBAR

  def menu_to(name, url, options={})
    raise ArgumentError.new("##{__method__} cannot use blocks") if block_given?
    icon = (options.has_key?(:menu) ? options.delete(:menu) : url.is_a?(Hash) ? url[:action] : nil)
    sprite = options.delete(:sprite) || "icons-16"
    options[:class] = (options[:class].blank? ? 'mn' : options[:class]+' mn')
    options[:class] += ' '+icon.to_s if icon
    link_to(url, options) do
      (icon ? content_tag(:span, '', :class => "icon")+content_tag(:span, name, :class => "text") : content_tag(:span, name, :class => "text"))
    end
  end


  def tool(code = nil, &block)
    raise ArgumentError.new("Arguments XOR block code are accepted, but not together.") if (code and block_given?) or (code.blank? and !block_given?)
    code = capture(&block) if block_given?
    content_for(:main_toolbar, code)
    return true
  end

  # Build the main toolbar
  def main_toolbar_tag
    content_tag(:div,
                content_for(:main_toolbar),
                :id => "main-toolbar")
  end


  def tool_to(name, url, options={})
    raise ArgumentError.new("##{__method__} cannot use blocks") if block_given?
    icon = (options.has_key?(:tool) ? options.delete(:tool) : url.is_a?(Hash) ? url[:action] : nil)
    sprite = options.delete(:sprite) || "icons-16"
    options[:class] = ''
    options[:class] = (options[:class].blank? ? 'btn' : options[:class].to_s+' btn')
    options[:class] += ' btn-'+icon.to_s if icon
    options[:class] += ' '+options.delete(:size).to_s if options.has_key?(:size)
    link_to(url, options) do
      (icon ? content_tag(:span, '', :class => "icon")+content_tag(:span, name, :class => "text") : content_tag(:span, name, :class => "text"))
    end
  end

  def toolbar(options={}, &block)
    code = '[EmptyToolbarError]'
    if block_given?
      toolbar = Toolbar.new
      if block
        if block.arity < 1
          self.instance_values.each do |k,v|
            toolbar.instance_variable_set("@" + k.to_s, v)
          end
          toolbar.instance_eval(&block)
        else
          block[toolbar]
        end
      end
      toolbar.link :back if options[:back]
      # To HTML
      code = ''
      items = []
      # call = 'views.' << caller.detect{|x| x.match(/\/app\/views\//)}.split(/\/app\/views\//)[1].split('.')[0].gsub(/\//,'.') << '.'
      for tool in toolbar.tools
        nature, args = tool[0], tool[1]
        if nature == :link
          name = args[0]
          args[1] ||= {}
          args[2] ||= {}
          if name.is_a? Symbol
            args[0] = ::I18n.t("actions.#{args[1][:controller]||controller_name}.#{name}".to_sym, {:default => "labels.#{name}".to_sym}.merge(args[2].delete(:i18n)||{}))
          end
          if name.is_a? Symbol and name!=:back
            args[1][:action] ||= name
          end
          items << tool_to(*args) if authorized?(args[1])
        elsif nature == :print
          dn, args, url = tool[1], tool[2], tool[3]
          url[:controller] ||= controller_name
          for dt in DocumentTemplate.of_nature(dn)
            items << tool_to(tc(:print_with_template, :name => dt.name), url.merge(:template => dt.code), :tool => :print) if authorized?(url)
          end
        elsif nature == :mail
          args[2] ||= {}
          email_address = ERB::Util.html_escape(args[0])
          extras = %w{ cc bcc body subject }.map { |item|
            option = args[2].delete(item) || next
            "#{item}=#{Rack::Utils.escape(option).gsub("+", "%20")}"
          }.compact
          extras = extras.empty? ? '' : '?' + ERB::Util.html_escape(extras.join('&'))
          items << tool_to(args[1], "mailto:#{email_address}#{extras}".html_safe, :tool => :mail)
        elsif nature == :missing
          action, record, tag_options = tool[1], tool[2], tool[3]
          tag_options = {} unless tag_options.is_a? Hash
          url = {}
          url.update(tag_options.delete(:params)) if tag_options[:params].is_a? Hash
          url[:controller] ||= controller_name
          url[:action] = action
          url[:id] = record.id
          items << tool_to(t("actions.#{url[:controller]}.#{action}".to_sym, {:default => "labels.#{action}".to_sym}.merge(record.attributes.symbolize_keys)), url, tag_options) if authorized?(url)
        end
      end
    else
      raise Exception.new('No block given for toolbar')
    end
    if @not_first_toolbar
      if items.size > 0
        code = content_tag(:div, items.join.html_safe, :class => 'toolbar' + (options[:class].nil? ? '' : ' ' << options[:class].to_s)) + content_tag(:div, nil, :class => :clearfix)
      end
      return code.html_safe
    else
      for item in items
        tool(item)
      end
      @not_first_toolbar = true
      return ""
    end
  end

  class Toolbar
    attr_reader :tools

    def initialize()
      @tools = []
    end

    def link(*args)
      @tools << [:link, args]
    end

    def mail(*args)
      @tools << [:mail, args]
    end

    def print(*args)
      # TODO reactive print
      # @tools << [:print, args]
    end

    #     def update(record, url={})
    #       @tools << [:update, record, url]
    #     end

    def method_missing(method_name, *args, &block)
      raise ArgumentError.new("Block can not be accepted") if block_given?
      if method_name.to_s.match(/^print_\w+$/)
        nature = method_name.to_s.gsub(/^print_/, '').to_sym
        raise Exception.new("Cannot use method :print_#{nature} because nature '#{nature}' does not exist.") unless parameters = DocumentTemplate.document_natures[nature]
        url = args.delete_at(-1) if args[-1].is_a?(Hash)
        raise ArgumentError.new("Parameters don't match. #{parameters.size} expected, got #{args.size} (#{[args, options].inspect}") unless args.size == parameters.size
        url ||= {}
        url[:action] ||= :show
        url[:format] = :pdf
        url[:id] ||= args[0].id if args[0].respond_to?(:id) and args[0].class.ancestors.include?(ActiveRecord::Base)
        url[:n] = nature
        parameters.each_index do |i|
          url[parameters[i][0]] = args[i]
        end
        @tools << [:print, nature, args, url]
      else
        raise ArgumentError.new("First argument must be an ActiveRecord::Base. (#{method_name})") unless args[0].class.ancestors.include? ActiveRecord::Base
        @tools << [:missing, method_name, args[0], args[1]]
      end
    end
  end


  def error_messages(object)
    object = instance_variable_get("@#{object}") unless object.respond_to?(:errors)
    return unless object.respond_to?(:errors)
    unless (count = object.errors.size).zero?
      I18n.with_options :scope => [:errors, :template] do |locale|
        header_message = locale.t :header, :count => count, :model => object.class.model_name.human
        introduction = locale.t(:body)
        messages = object.errors.full_messages.map do |msg|
          content_tag(:li, msg)
        end.join.html_safe
        message = ""
        message << content_tag(:h3, header_message) unless header_message.blank?
        message << content_tag(:p, introduction) unless introduction.blank?
        message << content_tag(:ul, messages)

        html = ''
        html << content_tag(:div, "", :class => :icon)
        html << content_tag(:div, message.html_safe, :class => :message)
        html << content_tag(:div, "", :class => :end)
        return content_tag(:div, html.html_safe, :class => "flash error")
      end
    else
      ''
    end
  end

  def form_actions(&block)
    return content_tag(:div, capture(&block), :class => "form-actions")
  end

  def form_fields(&block)
    return content_tag(:div, capture(&block), :class => "form-fields")
  end

  def backend_form_for(object, *args, &block)
    options = args.extract_options!
    simple_form_for(object, *(args << options.merge(builder: Backend::FormBuilder)), &block)
  end

  def backend_fields_for(object, *args, &block)
    options = args.extract_options!
    simple_fields_for(object, *(args << options.merge(builder: Backend::FormBuilder)), &block)
  end


  # Wraps a label and its input in a standard wrapper
  def field(label, input, options = {}, &block)
    return content_tag(:div,
                       content_tag(:label, label, :class => "control-label") +
                       content_tag(:div, (block_given? ? capture(&block) : input), :class => "controls"),
                       :class => "control-group")
  end


  def field_set(*args, &block)
    options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    name = args.delete_at(0) || "general-informations".to_sym
    return content_tag(:div,
                       content_tag(:div,
                                   content_tag(:span, "", :class => :icon) +
                                   content_tag(:span, (name.is_a?(Symbol) ? name.to_s.gsub('-', '_').t(:default => ["labels.#{name.to_s.gsub('-', '_')}".to_sym, "form.legends.#{name.to_s.gsub('-', '_')}".to_sym]) : name.to_s)) +
                                   content_tag(:span, "", :class => :toggle),
                                   :class => "fieldset-legend " + (options[:collapsed] ? 'collapsed' : 'not-collapsed'), 'data-toggle-set' => ".fieldset-fields") +
                       content_tag(:div, capture(&block), :class => "fieldset-fields"), :class => "fieldset", :id => name) # "#{name}-fieldset"
  end


  def steps_tag(record, steps, options={})
    name = options[:name] || record.class.name.underscore
    state_method = options[:state_method] || :state
    state = record.send(state_method).to_s
    code = ''
    for step in steps
      title = tc("#{name}_steps.#{step[:name]}")
      classes  = "step"
      classes << " active" if step[:actions].detect{ |url| not url.detect{|k, v| params[k].to_s != v.to_s}} # url = {:action => url.to_s} unless url.is_a? Hash
      classes << " disabled" unless step[:states].include?(state)
      title = link_to(title, (record.id ? step[:actions][0].merge(:id => record.id) : "#"))
      code << content_tag(:div, '&nbsp;'.html_safe, :class => 'transition') unless code.blank?
      code << content_tag(:div, title, :class => classes)
    end
    return content_tag(:div, code.html_safe, :class => "stepper stepper-#{steps.count}-steps")
  end



  def product_stocks_options(product)
    options = []
    options += product.stocks.collect{|x| [x.label, x.id]}
    options += Building.of_product(product).collect{|x| [x.name, -x.id]}
    return options
  end

  def toggle_tag(name=:orientation, modes = [:vertical, :horizontal])
    raise ArgumentError.new("Invalid name") unless name.to_s.match(/^[a-z\_]+$/)
    pref = @current_user.preference("interface.toggle.#{name}", modes[0].to_s)
    code = ""
    for mode in modes
      # code << link_to("", params.merge(name => mode), :title => tl("#{name}.#{mode}"), :class => "icon im-#{mode}#{' current' if mode.to_s==pref.value}")
      if mode.to_s==pref.value
        code << content_tag(:a, nil, :title => tl("#{name}.#{mode}"), :class => "icon im-#{mode} current")
      else
        code << link_to("", params.merge(name => mode), :title => tl("#{name}.#{mode}"), :class => "icon im-#{mode}")
      end
    end
    content_tag(:div, code.html_safe, :class => "toggle tg-#{name}")
  end


  # Imported from app/helpers/relations_helper.rb
  def condition_label(condition)
    if condition.match(/^generic/)
      klass, attribute = condition.split(/\-/)[1].pluralize.classify.constantize, condition.split(/\-/)[2]
      return tl("conditions.filter_on_attribute_of_class", :attribute => klass.human_attribute_name(attribute), :class => klass.model_name.human)
    else
      return tl("conditions.#{condition}")
    end
  end



end

