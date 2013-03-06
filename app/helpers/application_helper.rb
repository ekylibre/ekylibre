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

class SimpleForm::Inputs::DateTimeInput

  def input_html_options
    value = object.send(attribute_name)
    format = @options[:format] || :default
    raise ArgumentError.new("Option :format must be a Symbol referencing a translation 'date.formats.<format>'") unless format.is_a?(Symbol)
    if localized_value = value
      localized_value = I18n.localize(localized_value, :format => format)
    end
    format = I18n.translate('date.formats.'+format.to_s)
    Formize::DATE_FORMAT_TOKENS.each{|js, rb| format.gsub!(rb, js)}
    options = {
      "data-date" => format,
      "data-date-locale" => "i18n.iso2".t,
      "data-date-iso" => value,
      :value => localized_value,
      :size => @options.delete(:size) || 10
    }
    super.merge options
  end

  def input
    @builder.text_field(attribute_name, input_html_options)
  end

end


class SimpleForm::FormBuilder

  # Display a selector with "new" button
  def referenced_association(association, options = {}, &block)
    reflection = find_association_reflection(association)
    raise "Association #{association.inspect} not found" unless reflection
    raise ArgumentError.new("Reflection #{reflection.name} must be a belongs_to") if reflection.macro != :belongs_to


    choices = options[:source] || {}
    choices = {:action => "unroll_#{choices.to_s}".to_sym} unless choices.is_a?(Hash)
    choices[:action] ||= :unroll
    choices[:controller] ||= reflection.class_name.underscore.pluralize

    new_url = {}
    new_url[:controller] ||= choices[:controller]
    new_url[:action] ||= :new

    model = @object.class
    input_id = model.name.underscore + "-" + association.to_s + "-input"

    return input(reflection.foreign_key, options.merge(:wrapper => :append, :reflection => reflection)) do
      self.input_field(reflection.foreign_key, 'data-selector' => @template.url_for(choices), :id => input_id) +
        @template.link_to(('<span class="icon"></span><span class="text">' + @template.send(:h, 'labels.new'.t) + '</span>').html_safe, new_url, 'data-new-item' => input_id, :class => 'btn btn-new')
    end
  end

  # Adds nested association support
  def nested_association(association, *args, &block)
    reflection = find_association_reflection(association)
    raise "Association #{association.inspect} not found" unless reflection
    puts "DEPRECATED: Nested association don't take code block anymore. Use partial '#{association.to_s.singularize}_fields' instead." if block_given?
    # raise ArgumentError.new("Reflection #{reflection.name} must be a has_many") if reflection.macro != :has_many
    item = association.to_s.singularize
    html = self.simple_fields_for(association) do |nested|
      @template.render("#{item}_fields", :f => nested)
    end
    if reflection.macro == :has_many
      html << @template.content_tag(:div, @template.link_to_add_association("labels.add_#{item}".t, self, association, 'data-no-turbolink' => true, :class => 'nested-add add-#{item}'), :class => "links")
    end
    return @template.content_tag(:div, html, :id => "#{association}-field")
  end

  # Adds custom fields
  def custom_fields(*args, &block)
    custom_fields = CustomField.of(@object.class.name)
    if custom_fields.count > 0
      return @template.content_tag(:div, :id => "custom-fields-field") do
        data = @object.custom_field_data
        html = "".html_safe
        for custom_field in custom_fields
          datum = data.select{|d| d.custom_field_id == custom_field.id}.first || custom_field.data.build({:customized => @object}, :without_protection => true)
          html << self.simple_fields_for(:custom_field_data, datum) do |custom|
            inner_html  = custom.hidden_field(:customized_type)
            inner_html << custom.hidden_field(:custom_field_id)
            if custom_field.choice?
              inner_html << custom.association(:choice_value, :collection => custom_field.choices, :required => custom_field.required?, :label => custom_field.name)
            else
              inner_html << custom.input(:value, :as => custom_field.nature.to_sym, :required => custom_field.required?, :label => custom_field.name)
            end
            inner_html
          end
        end
        # Returns HTML
        html
      end
    end
    return nil
  end

end


module ApplicationHelper

  # Returns the absolute controller name
  # Example: "backend/accounts"
  def absolute_controller_name
    self.controller.class.absolute_controller_name
  end

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
    return [h("Ekylibre " + Ekylibre.version),  h("Ruby on Rails " + Rails.version),  h("Ruby "+ RUBY_VERSION.to_s), h("HTML 5"), h("CSS 3")].join(" &ndash; ").html_safe
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
      for datum in @object.custom_field_data.joins("JOIN custom_fields ON (custom_fields.id = custom_field_id AND active)").order(:position)
        unless datum.value.to_s.blank?
          self.custom datum.custom_field.name, datum.value
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



  def wikize(content, options={})
    # AJAX fails with XHTML entities because there is no DOCTYPE in AJAX response

    content.gsub!(/(\w)(\?|\:)([\s$])/ , '\1~\2\3' )
    content.gsub!(/(\w+)[\ \~]+(\?|\:)/ , '\1~\2' )
    content.gsub!(/\~/ , '&#160;')

    content.gsub!(/^\ \ \*\ +(.*)\ *$/ , '<ul><li>\1</li></ul>')
    content.gsub!(/<\/ul>\n<ul>/ , '')
    content.gsub!(/^\ \ \-\ +(.*)\ *$/ , '<ol><li>\1</li></ol>')
    content.gsub!(/<\/ol>\n<ol>/ , '')
    content.gsub!(/^\ \ \?\ +(.*)\ *$/ , '<dl><dt>\1</dt></dl>')
    content.gsub!(/^\ \ \!\ +(.*)\ *$/ , '<dl><dd>\1</dd></dl>')
    content.gsub!(/<\/dl>\n<dl>/ , '')

    content.gsub!(/^>>>\ +(.*)\ *$/ , '<p class="notice">\1</p>')
    content.gsub!(/<\/p>\n<p class="notice">/ , '<br/>')
    content.gsub!(/^!!!\ +(.*)\ *$/ , '<p class="warning">\1</p>')
    content.gsub!(/<\/p>\n<p class="warning">/ , '<br/>')

    content.gsub!(/\{\{\ *[^\}\|]+\ *(\|[^\}]+)?\}\}/) do |data|
      data = data.squeeze(' ')[2..-3].split('|')
      align = {'  ' => 'center', ' x' => 'right', 'x ' => 'left', 'xx' => ''}[(data[0][0..0] + data[0][-1..-1]).gsub(/[^\ ]/,'x')]
      title = data[1]||data[0].split(/[\:\\\/]+/)[-1].humanize
      src = data[0].strip
      if src.match(/^icon:/)
        icon_name = src.split(':')[1]
        "<i class='icon icon-#{icon_name}'></i>"
      else
        src = image_path(src)
        '<img class="md md-' + align + '" alt="' + title + '" title="' + title + '" src="' + src + '"/>'
      end
    end


    options[:url] ||= {}
    content = content.gsub(/\[\[>[^\|]+\|[^\]]*\]\]/) do |link|
      link = link[3..-3].split('|')
      url = link[0].split(/[\#\?\&]+/)
      url = options[:url].merge(:controller => url[0], :action => (url[1]||:index))
      (authorized?(url) ? link_to(link[1], url) : link[1])
    end

    options[:method] = :get
    content = content.gsub(/\[\[[\w\-]+\|[^\]]*\]\]/) do |link|
      link = link[2..-3].split('|')
      url = url_for(options[:url].merge(:id => link[0]))
      link_to(link[1].html_safe, url, {:remote => true, "data-type" => :html}.merge(options)) # REMOTE
    end

    content = content.gsub(/\[\[[\w\-]+\]\]/) do |link|
      link = link[2..-3]
      url = url_for(options[:url].merge(:id => link))
      link_to(link.html_safe, url, {:remote => true, "data-type" => :html}.merge(options)) # REMOTE
    end

    for x in 1..6
      n = 7-x
      content.gsub!(/^\s*\={#{n}}\s*([^\=]+)\s*\={#{n}}/, "<h#{x}>\\1</h#{x}>")
    end

    content.gsub!(/^\ \ (.*\w+.*)$/, '  <pre>\1</pre>')

    content.gsub!(/([^\:])\/\/([^\s][^\/]+)\/\//, '\1<em>\2</em>')
    content.gsub!(/\'\'([^\s][^\']+)\'\'/, '<code>\1</code>')
    content.gsub!(/(^)([^\s\<][^\s].*)($)/, '<p>\2</p>') unless options[:without_paragraph]
    content.gsub!(/^\s*(\<a.*)\s*$/, '<p>\1</p>')

    content.gsub!(/\*\*([^\s\*]+)\*\*/, '<strong>\1</strong>')
    content.gsub!(/\*\*([^\s\*][^\*]*[^\s\*])\*\*/, '<strong>\1</strong>')
    content.gsub!(/(^|[^\*])\*([^\*]|$)/, '\1&lowast;\2')
    content.gsub!("</p>\n<p>", "\n")

    content.strip!

    #raise Exception.new content
    return content.html_safe
  end


  def heading_tag
    heading = "".html_safe
    unless (rm = reverse_menus).empty?
      heading << link_to("labels.menus.#{rm[0]}".t, last_page(rm[0]), :class => :module)
      heading << content_tag(:span, "/", :class => "separator")
    end
    heading << content_tag(:span, controller.human_action_name, :class => :leaf)
    content_tag(:h1, heading, :id => :title)
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
    tag = form_tag(url_options, :method => :get) { content_tag(:div, launch, :class => :submit) + content_tag(:div, crits, :class => :crits) }
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




  def field(*args, &block)
    options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    label, input = nil, nil
    if args[0].is_a?(String)
      label, input = args[0], args[1]
    elsif args[0].is_a?(Symbol)
      attribute = args[0]
      object = @object_of_current_field_set
      model = object.class
      label = model.human_attribute_name(attribute)
      input = if options[:source]
                select(object, attribute, options[:source])
              else
                text_field(object, attribute)
              end
    else
      raise ArgumentError("field don't understand these parameters: #{args.inspect}")
    end

    return content_tag(:div, content_tag(:label, label, :class => "control-label") + content_tag(:div, (block_given? ? capture(&block) : input), :class => "controls"), :class => "control-group")
  end




  # # TABBOX
  # def tabbox(id, options={})
  #   tb = Tabbox.new(id)
  #   yield tb
  #   return '' if tb.tabs.size.zero?
  #   tabs = ''
  #   taps = ''
  #   session[:tabbox] ||= {}
  #   for tab in tb.tabs
  #     session[:tabbox][tb.id] ||= tab[:index]
  #     style_name = (session[:tabbox][tb.id] == tab[:index] ? "current " : "")
  #     tabs << content_tag(:span, tab[:name], :class => style_name + "tab", "data-tabbox-index" => tab[:index])
  #     taps << content_tag(:div, capture(&tab[:block]).html_safe, :class => style_name + "tabpanel", "data-tabbox-index" => tab[:index])
  #   end
  #   return content_tag(:div, :class => options[:class]||"tabbox", :id => tb.id, "data-tabbox" => url_for(:controller => :interfacers, :action => :toggle_tab, :id => tb.id)) do
  #     code  = content_tag(:div, tabs.html_safe, :class => :tabs)
  #     code << content_tag(:div, taps.html_safe, :class => :tabpanels)
  #     code
  #   end
  # end


  # class Tabbox
  #   attr_accessor :tabs, :id

  #   def initialize(id)
  #     @tabs = []
  #     @id = id.to_s
  #     @sequence = 0
  #   end

  #   # Register a tab with a block of code
  #   # The name of tab use I18n searching in :
  #   #   - labels.<tabbox_id>_tabbox.<tab_name>
  #   #   - labels.<tab_name>
  #   def tab(name, options={}, &block)
  #     raise ArgumentError.new("No given block") unless block_given?
  #     if name.is_a?(Symbol)
  #       options[:default] = [] unless options[:default].is_a?(Array)
  #       options[:default] << "labels.#{name}".to_sym
  #       options[:default] << "attributes.#{name}".to_sym
  #       name = ::I18n.translate("labels.#{@id}_tabbox.#{name}", options)
  #     end
  #     @tabs << {:name => name, :index => (@sequence*1).to_s(36), :block => block}
  #     @sequence += 1
  #   end

  # end


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


  def tool(code, &block)
    raise ArgumentError.new("Arguments XOR block code are accepted, but not together.") if code and block_given?
    code = capture(&block) if block_given?
    # code = content_tag(:li, code)
    content_for(:main_toolbar, code)
    return true
  end

  def main_toolbar_tag
    content_tag(:div, content_for(:main_toolbar), :id => "main-toolbar") #  + content_tag(:div, tool_to(:menu, '#', "data-target" => "#side", :tool => :nav, :id => "nav"), :class => :group)
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


  # Build the master form using all form through modules and assemblies them in one
  # Auto manage dialog use
  def master_form(action, options = {})
    nature = options.delete(:nature) || "form"
    @master_model = (options[:model] || controller.controller_name).to_s.classify.constantize
    # Compile fields
    fields = field_sets(nature)
    # Prepare form
    form_options = {}
    form_options[:id] = options[:id] || "f"+rand(1_000_000_000).to_s(36)
    form_options[:method] = options[:method] || :post
    form_options[:multipart] = @_multipart
    return render(:partial => "forms/form", :locals => {:form_options => form_options, :action => action, :nature => nature, :options => options, :fields => fields})
  end


  FACES = {
    :textarea => :text,
    :text_area => :text,
    :date => :date_field
  }


  # This helper assemblies all form parts to generate one unique form
  # This method use simple_form to build forms
  def field_sets(nature = "form")
    resource = @master_model.name.underscore
    kontroller = controller.controller_name.underscore.singularize
    composers = [nature]
    base_directory = Rails.root.join("app", "views")
    composers += Dir[base_directory.join("**", "#{nature}-#{kontroller}.html.*")].collect do |path|
      "/" + path.relative_path_from(base_directory).to_s
    end

    # Cache this in a view method
    method_name = "field_sets_#{kontroller}_#{nature}".to_sym
    if self.respond_to?(method_name) and !Rails.env.development?
      return send(method_name)
    end

    @field_sets = {}
    @groups = {}
    @fields = collect_fields do
      for partial in composers
        # no HTML expected to be generated
        render(:partial => partial)
      end
      # check presence of custom_fields
      unless @fields.flatten.detect{|f| f[:name] == :custom_fields}
        custom_fields(:set => @field_sets.keys.first)
      end
    end


    # Orders
    field_sets = @field_sets.values
    tree = field_sets.select{|fs| fs[:before].blank? and fs[:after].blank?}
    raise ArgumentError.new("No root form defined...") if tree.size.zero?
    others = field_sets - tree
    # raise [others.collect{|x| x[:name]}, tree.collect{|x| x[:name]}].inspect
    counter = others.size + 1
    while others.size > 0
      break if counter.zero?
      for other in others.reverse
        if other[:before]
          raise Exception.new("Unknown field set #{other[:before]}") unless @field_sets[other[:before]]
          if fs = tree.select{|fs| fs[:name] == other[:before]}.first
            tree.insert(tree.index(fs), others.delete(other))
          end
        elsif other[:after]
          raise Exception.new("Unknown field set #{other[:after]}") unless @field_sets[other[:after]]
          if fs = tree.select{|fs| fs[:name] == other[:after]}.first
            tree.insert(tree.index(fs)+1, others.delete(other))
          end
        end
      end
      counter -= 1
    end
    raise ArgumentError.new("Field set positionning seems to loop") if counter.zero?

    # Check field_set, field and association
    default_field_set = tree.first[:name]
    for field in @fields
      field[:set] ||= default_field_set
    end

    fields = @fields.dup
    roots = fields.select{|f| f[:before].blank? and f[:after].blank?}
    raise ArgumentError.new("No root field defined...") if roots.size.zero?
    for set in tree
      set[:fields] = roots.select{|f| f[:set] == set[:name]}
    end
    others = fields - roots
    # raise [others.collect{|x| x[:name]}, tree.collect{|x| x[:name]}].inspect
    counter = others.size + 1
    while others.size > 0
      break if counter.zero?
      for other in others.reverse
        if other[:before]
          ref = @fields.select{|f| f[:name] == other[:before]}.first
          raise Exception.new("Unknown field #{other[:before]}") unless ref
          raise Exception.new("Fields (#{other[:name]} before #{ref[:name]}) must be in the same set if you want to use :before") if ref[:set] != other[:set]
          fs = tree.select{|fs| fs[:name] == other[:set]}.first
          if fs[:fields].select{|f| f[:name] == other[:before]}.first
            fs[:fields].insert(fs[:fields].index(ref), others.delete(other))
          end
        elsif other[:after]
          ref = @fields.select{|f| f[:name] == other[:after]}.first
          raise Exception.new("Unknown field #{other[:after]}") unless ref
          raise Exception.new("Fields (#{other[:name]} after #{ref[:name]}) must be in the same set if you want to use :after") if ref[:set] != other[:set]
          fs = tree.select{|fs| fs[:name] == other[:set]}.first
          if fs[:fields].select{|f| f[:name] == other[:after]}.first
            fs[:fields].insert(fs[:fields].index(ref)+1, others.delete(other))
          end
        end
      end
      counter -= 1
    end
    raise ArgumentError.new("Field positionning seems to loop") if counter.zero?

    # Build method
    basename = nature.to_s
    file =  basename + ".html.haml"
    dir = Rails.root.join("tmp", "cache", "forms", *(controller.class.name.underscore.gsub(/_controller$/, '').split('/')))
    FileUtils.mkdir_p(dir)

    haml  = "" # "-# Generated on #{Time.now.l(:locale => :eng)}\n"
    for fs in tree
      fs_name = fs[:name]
      set_id = "#{fs_name}-fields"
      toggle_id = "#{set_id}-toggle"
      fs_haml  = "%fieldset##{fs[:wrapper_id]}.fieldset.form-horizontal\n"
      fs_haml << "  .fieldset-legend\n"
      fs_haml << "    %span.icon\n"
      fs_haml << "    %span{:for => '#{toggle_id}'}=" + (fs_name.is_a?(Symbol) ? ":'#{fs_name.to_s.gsub('-', '_')}'.t(:default => [:'labels.#{fs_name.to_s.gsub('-', '_')}', :'form.legends.#{fs_name.to_s.gsub('-', '_')}'])" : fs_name.to_s.inspect) + "\n"
      fs_haml << "    %span##{toggle_id}.#{fs[:collapsed] ? 'collapsed' : 'not-collapsed'}{'data-toggle-set' => '##{set_id}'}\n"
      fs_haml << "  ##{set_id}.fieldset-fields" + (fs[:collapsed] ? "{:style => 'display: none'}" : "") + "\n"
      for field in fs[:fields]
        fs_haml << render_field(field, 2)
      end

      for group in fs[:in]
        fs_haml = ".#{@groups[group][:wrapper_id]}.fieldset-group\n" + fs_haml.gsub(/^/, '  ')
      end if fs[:in]

      haml << fs_haml
    end

    haml = "-# Generated on #{Time.now.l(:locale => :eng)}\n" +
      "=simple_fields_for(@#{resource}) do |f|\n" +
      haml.gsub(/^/, '  ')

    # if Rails.env.development?
    #   haml << "\n=@#{resource}.errors.inspect if @#{resource}.errors\n"
    # end

    File.open(dir.join(file), "wb") do |f|
      f.write(haml)
    end

    multipart = @fields.detect{|f| f[:multipart]}
    code  = "def #{method_name}\n"
    code << "  @_multipart = #{multipart ? 'true' : 'false'}\n"
    code << "  return render(:file => '#{dir.join(basename).relative_path_from(Rails.root)}')\n"
    code << "end\n"
    eval(code)

    return send(method_name)
  end


  def field_set(*args, &block)
    options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    name  = (args[0].is_a?(Symbol) ? args.delete_at(0) : "general-informations").to_sym
    # Test if we are building a field_set with master_form
    if @field_sets
      if @field_sets[name]
        if options.size > 0 or args.size > 0
          raise ArgumentError.new("This field_set is already defined. You can not give other parameters.")
        end
      else
        options[:name] = name
        options[:wrapper_id] = name.to_s.gsub(/\_/, '-') + "-fieldset"
        if options[:before] and options[:after]
          raise Exception.new("Cannot be before something and after other thing")
        end
        options[:object] = (args[-1] ? args.delete_at(-1) : (options[:object] || instance_variable_get('@' + controller.controller_name.to_s.singularize)))
        options[:in] = normalize_groups(options[:in])
        @field_sets[name] = options
      end
      if block_given?
        @current_field_set = name
        yield
        @current_field_set = nil
      end
      return nil
    else
      @object_of_current_field_set = args[-1]
      set_id = "#{name}-fields"
      toggle_id = "#{set_id}-toggle"
      return content_tag(:div,
                         content_tag(:div,
                                     content_tag(:span, "", :class => :icon) +
                                     content_tag(:span, (name.is_a?(Symbol) ? name.to_s.gsub('-', '_').t(:default => ["labels.#{name.to_s.gsub('-', '_')}".to_sym, "form.legends.#{name.to_s.gsub('-', '_')}".to_sym]) : name.to_s)) +
                                     content_tag(:span, "", :id => toggle_id, :class => (options[:collapsed] ? 'collapsed' : 'not-collapsed'), 'data-toggle-set' => "##{set_id}"),
                                     :class => "fieldset-legend") +
                         content_tag(:div, capture(&block), :class => "fieldset-fields", :id => set_id), :class => "fieldset", :id => "#{name}-fieldset")
    end
  end

  def input(name, options = {})
    check_field_name_before_push(name, __method__)
    options.merge!(:type => __method__, :name => name)
    model = options[:model] || @options[0][:model] || @master_model
    # raise "Unknown column #{name} for #{model.name}" unless model.columns_hash[name.to_s]
    if column = model.columns_hash[name.to_s]
      options[:field] ||= :text if column.type == :text
    end
    if options[:hide].is_a?(Hash) and options[:hide].empty?
      if model.respond_to?(name.to_sym)
        options[:hide] = model.send(name.to_sym).values.inject({}) do |hash, value|
          hash[value.to_sym] = value.to_sym
          hash
        end
      else
        raise ArgumentError.new("Option :hide cannot be an empty because no enumerize defined for #{name}")
      end
    end
    if options[:show].is_a?(Hash) and options[:show].empty?
      if model.respond_to?(name.to_sym)
        options[:show] = model.send(name.to_sym).values.inject({}) do |hash, value|
          hash[value.to_sym] = value.to_sym
          hash
        end
      else
        raise ArgumentError.new("Option :show cannot be an empty because no enumerize defined for #{name}")
      end
    end

    if model.respond_to?(:attachment_definitions)
      unless model.attachment_definitions.nil?
        options[:multipart] = true
      end
    end
    push_field(options)
  end

  def association(name, options = {})
    check_field_name_before_push(name, __method__)
    options.merge!(:type => __method__, :name => name)
    push_field(options)
  end

  def partial(name, options = {})
    check_field_name_before_push(name, __method__)
    options.merge!(:type => __method__, :name => name)
    push_field(options)
  end

  def nested_association(name, options = {}, &block)
    check_field_name_before_push(name, __method__)
    model = options[:model] || @options[0][:model] || @master_model
    raise ArgumentError.new("Unknown reflection #{name} for #{model.name}") unless model.reflections[name]
    nested_model = model.reflections[name].class_name.constantize
    fields = (block_given? ? collect_fields(:model => nested_model, &block) : [])
    options.merge!(:type => __method__, :name => name, :fields => fields)
    push_field(options)
  end

  def custom_fields(options = {})
    check_field_name_before_push(__method__, __method__)
    options.merge!(:type => __method__, :name => __method__)
    push_field(options)
  end

  def check_field_name_before_push(name, type)
    raise ArgumentError.new("Name must be a symbol") unless name.is_a?(Symbol)
    if name == :custom_fields and name != type
      raise ArgumentError.new("custom_fields is a key word.")
    end
    if @fields[0].detect{|f| f[:name] == name }
      raise ArgumentError.new("Name #{name.inspect} has been already used")
    end
    return true
  end

  def push_field(field)
    field[:wrapper_id] = "#{field[:name].to_s.gsub(/\_/, '-')}-field"
    field[:name] = field[:name].to_sym
    field[:set] ||= @current_field_set
    field[:in] = normalize_groups(field[:in])
    @fields[0] << field
    return true
  end

  def collect_fields(options = {}, &block)
    @fields = [] unless @fields.is_a?(Array)
    @fields.insert(0, [])
    @options = [] unless @options.is_a?(Array)
    @options.insert(0, options)
    yield if block_given?
    @options.delete_at(0)
    return @fields.delete_at(0)
  end

  def form_element_ids(expr)
    expr = expr.to_s.split(/[\,\s]+/) unless expr.is_a?(Array)
    expr.collect do |id|
      wid = if g = @groups[id.to_sym]
              "."+g[:wrapper_id].to_s
            elsif s = @field_sets[id.to_sym]
              "#"+s[:wrapper_id].to_s
            elsif f = @fields.select{|f| f[:name].to_s == id.to_s}.first
              "#"+f[:wrapper_id].to_s
            else
              raise Exception.new("Unable to find form element #{expr}")
            end
      wid
    end.flatten.join(", ")
  end

  def normalize_groups(groups)
    if groups.nil? or groups.blank?
      return nil
    else
      groups = [groups] unless groups.is_a?(Array)
      groups = groups.flatten.collect{|g| g.to_sym}
      for group in groups
        @groups[group] ||= {:name => group, :wrapper_id => group.to_s.gsub(/\_/, '-') + "-group"}
      end
    end
    return groups
  end


  def normalize_source(source, default_controller)
    url = {}
    if source.to_s.match("#")
      asource = source.to_s.split('#')
      url[:controller], url[:action] = asource[0], asource[1].to_s
    else
      url[:controller] = default_controller.to_s
      url[:action] = source.to_s
    end
    url[:action] = ("unroll" + (url[:action].blank? ? "" : "_" + url[:action].to_s)).to_sym
    return url
  end


  def render_field(field, depth = 0)
    options = field.dup
    name, type = options.delete(:name), options.delete(:type)
    haml = send("render_field_#{type}", name, options).strip
    for group in options[:in]
      haml = ".#{@groups[group][:wrapper_id]}.field-group\n" + haml.gsub(/^/, '  ')
    end if options[:in]
    return haml.gsub(/^/, '  '*depth) + "\n"
  end

  def render_field_input(name, options = {})
    source = options.delete(:source)
    face = options.delete(:field)
    haml  = ""
    input_html = {}
    model = options[:model] || @master_model
    object = options[:object] || "@" + model.name.underscore
    readonly = model.readonly_attributes.include?(name.to_s)
    # face ||= :select if source.is_a?(Symbol)
    if model.columns_hash[name.to_s]
      face = :date if model.columns_hash[name.to_s].type == :date
    end
    # Need to adapt data-show(-if) to radio
    # if model.respond_to?(name)
    #   if model.send(name).respond_to?(:values)
    #     face = :radio
    #   end
    # end

    haml << "=f.input(:#{name}"
    haml << ", :collection => #{source}" if source.is_a?(Symbol)
    haml << ", :as => :#{FACES[face]||face}" if face.is_a?(Symbol)
    haml << ", :readonly => !#{object}.new_record?" if readonly
    haml << ", :label => I18n.translate(#{options[:label].inspect})" if options[:label]
    haml << ", :wrapper_html => {:id => '#{options[:wrapper_id]}'}"
    input_html[:rows] = "3" if face == :text

    if options[:hide].is_a?(Hash)
      input_html["data-hide-if"] = "'" + options[:hide].inject({}) do |hash, pair|
        hash[pair[0]] = form_element_ids(pair[1])
        hash
      end.to_json + "'"
    elsif !options[:hide].blank?
      input_html["data-hide"] = "'#{form_element_ids(options[:hide].to_s)}'"
    end

    if options[:show].is_a?(Hash)
      input_html["data-show-if"] = "'" + options[:show].inject({}) do |hash, pair|
        hash[pair[0]] = form_element_ids(pair[1])
        hash
      end.to_json + "'"
    elsif !options[:show].blank?
      input_html["data-show"] = "'#{form_element_ids(options[:show].to_s)}'"
    end

    unless input_html.empty?
      haml << ", :input_html => {" + input_html.collect do |k,v|
        "'#{k}' => #{v}"
      end.join(', ') + "}"
    end
    haml << ")"
    return haml
  end

  def render_field_association(name, options = {})
    model = options[:model] || @master_model
    object = options[:object] || "@" + model.name.underscore
    reflection = model.reflections[name]
    raise ArgumentError.new("Unknown reflection :#{name} for #{model.name}") if reflection.nil?
    reflection_model = reflection.class_name.constantize
    source = options.delete(:source)
    face = options.delete(:field)
    required = (options.has_key?(:required) ? options[:required] : model.validators_on(name).detect{|v| v.attributes.include?(name) and v.is_a?(ActiveModel::Validations::PresenceValidator)} ? true : false)
    required_class = (required ? "required" : "optional")
    input_id = "#{model.name.underscore}-#{reflection.name}-input"
    haml = ""
    if face == :hidden
      haml << "=f.association(:#{reflection.name}, :as => :hidden, :wrapper_html => {:id => '#{options[:wrapper_id]}'})\n"
    else
      haml << "##{options[:wrapper_id]}.control-group.selector.#{required_class}\n"
      haml << "  %label.control-label.#{required_class}{:for => '#{input_id}'}\n"
      haml << "    %abbr{:title => 'required'} *\n" if required
      haml << "    =#{model.name}.human_attribute_name('#{reflection.name}')\n"
      attrs = (reflection_model.columns_hash.keys + reflection_model.instance_methods).collect{|a| a.to_sym}
      label_method = options[:label_method] || [:label, :native_name, :name, :to_s, :inspect].detect{|x| attrs.include?(x)}
      include_blank = !required
      haml << "  .controls\n"
      haml << "    %span.input\n"
      if source.is_a?(Hash)
        sources = source.to_a
        default_source = sources.select{ |a| a[0].is_a?(Hash) and a[0].empty? }.first || [{}, nil]
        sources.delete_if { |a| a[0].is_a?(Hash) and a[0].empty? }
        sources << default_source
        sources_code = sources.collect do |s|
          x  = ""
          x << "(" + s[0].collect{|k,v| "#{object}.#{k}.to_s == '#{v}'" }.join(" && ") + ") ? " unless s[0].empty?
          x << (s[1].nil? ? "'NoDefaultSource'" : normalize_source(s[1], reflection.class_name.underscore.pluralize).inspect)
          x
        end.join(" : ")
        sources_data = sources.collect do |s|
          x  = ""
          x << (s[0].empty? ? "" : s[0].collect{|k,v| "#{k}=#{v}" }.join(" and ") + " ? ")
          x << (s[1].nil? ? "NoDefaultSource" : url_for(normalize_source(s[1], reflection.class_name.underscore.pluralize)))
          x
        end.join(" : ")
        haml << "      =selector(:#{model.name.underscore}, :#{reflection.name}, (#{sources_code}), {:object => #{object}}, :id => '#{input_id}', :class => 'selector #{required_class}', 'data-change-source' => '#{sources_data}')"
      else
        source = normalize_source(source, reflection.class_name.underscore.pluralize)
        haml << "      =selector(:#{model.name.underscore}, :#{reflection.name}, #{source.inspect}, {:object => #{object}}, :id => '#{input_id}', :class => 'selector #{required_class}')"
      end
      buttons = options[:buttons] || {}
      for action in [:new] # , :edit  system actions
        if buttons[action].is_a?(FalseClass) or options[action].is_a?(FalseClass)
          buttons.delete(action)
        elsif !buttons[action].is_a?(Hash)
          buttons[action] = {}
        end
      end
      buttons[:edit][:member] = true if buttons[:edit]
      for action, action_options in buttons
        buttons[action] = {} if !buttons[action].is_a?(Hash)
      end

      item_id = "@#{reflection.foreign_key.to_s.upcase}@"
      if buttons.size > 0
        # haml << "    %<\n"
        for action, action_options in buttons
          # HAML puts unwanted spaces and don't permit to remove it
          haml << " + link_to(('<span class=\"icon\"></span><span class=\"text\">' + h('labels.#{action}'.t) + '</span>').html_safe, {:controller => :#{reflection_model.name.pluralize.underscore}, :action => :#{action}" + (action_options.delete(:member) ? ", :id => '#{item_id}'" : '') + action_options.collect{|k,v| ", :#{k} => " + (v.is_a?(Symbol) ? "#{object}.#{v}" : v.inspect)}.join + "}, 'data-#{action}-item' => '#{input_id}'" + (action_options[:member] ? ", 'data-#{action}-item-id' => '#{item_id}'" : '') + ", :class => 'btn btn-#{action}')\n"
          # haml << "      %span.icon\n"
          # haml << "      %span.text='labels.#{action}'.t\n"
        end
      end

      # Errors
      haml << "    -for error in #{object}.errors['#{reflection.name}']\n" # + #{object}.errors['#{reflection.foreign_key}']
      haml << "      %span.help-inline=error\n"

    end
    return haml
  end

  def render_field_partial(name, options = {})
    partial = options[:with] || "#{name}_form"
    attrs = []
    if options[:depend_on]
      attrs << "'data-depend-on' => '#{form_element_ids(options[:depend_on])}'"
      options[:refresh_url] ||= {:action => "refresh_#{name}"}
    end
    if options[:refresh_url]
      attrs << "'data-refresh' => '#{url_for(options[:refresh_url])}'"
      options[:refresh_mode] ||= :update
    end
    if options[:refresh_mode]
      attrs << "'data-refresh-mode' => '#{options[:refresh_mode]}'"
    end
    attrs = "{" + attrs.join(", ") + "}" unless attrs.empty?
    haml  = ""
    haml << "##{options[:wrapper_id]}#{attrs}=render(:partial => '#{partial}')\n"
    return haml
  end



  def render_field_nested_association(name, options = {})
    model = options[:model] || @master_model
    record = name.to_s.singularize
    raise ArgumentError("Unknown reflection #{name.inspect} for #{model.name}") unless model.reflections[name]
    nested_model = model.reflections[name].class_name.constantize
    object = nested_model.name.underscore
    fs_name = options[:in]

    partial  = "-# Generated automatically. Don't edit this file.\n"
    partial << "-#{object} ||= f.object\n"
    partial << ".nested-fields\n"
    partial << "  =link_to_remove_association('labels.remove_#{record}'.t, f, 'data-no-turbolink' => true, :class => 'nested-remove remove-#{record.to_s.parameterize}')\n"
    for f in options[:fields]
      partial << render_field(f.merge(:model => nested_model, :object => object), 1)
    end

    File.open(Rails.root.join("app", "views", *(controller.class.name.underscore.gsub(/_controller$/, '').split('/')), "_#{record}_fields.html.haml"), "wb") do |f|
      f.write partial
    end
    haml  = "##{options[:wrapper_id]}\n"
    haml << "  =f.simple_fields_for(:#{name}) do |#{record}|\n"
    haml << "    =render '#{record}_fields', :f => #{record}\n"
    haml << "  .links\n"
    haml << "    =link_to_add_association('labels.add_#{record}'.t, f, :#{name}, 'data-no-turbolink' => true, :class => 'nested-add add-#{record.to_s.parameterize}')\n"
    return haml
  end

  def render_field_custom_fields(name, options = {})
    model = options[:model] || @master_model
    object = options[:object] || "@#{model.name.underscore}"
    subfields = "custom_field_fields"

    haml  = ""
    haml << "-custom_fields = CustomField.of(:#{model.name.underscore})\n"
    haml << "-if custom_fields.count > 0\n"
    haml << "  ##{options[:wrapper_id]}\n"
    haml << "    -data = #{object}.custom_field_data\n"
    haml << "    -for custom_field in custom_fields\n"
    haml << "      -datum = data.select{|d| d.custom_field_id == custom_field.id}.first || custom_field.data.build({:customized => #{object}}, :without_protection => true)\n"
    haml << "      =f.simple_fields_for(:custom_field_data, datum) do |#{subfields}|\n"
    common_options = ", :required => custom_field.required?, :label => custom_field.name"
    haml << "        =#{subfields}.hidden_field(:customized_type)\n"
    haml << "        =#{subfields}.hidden_field(:custom_field_id)\n"
    haml << "        -if custom_field.choice?\n"
    haml << "          =#{subfields}.association(:choice_value, :collection => custom_field.choices#{common_options})\n"
    haml << "        -elsif custom_field.boolean?\n"
    haml << "          =#{subfields}.input(:value, :as => :boolean#{common_options})\n"
    haml << "        -elsif custom_field.date?\n"
    haml << "          =#{subfields}.input(:value, :as => :date_field#{common_options})\n"
    haml << "        -elsif custom_field.datetime?\n"
    haml << "          =#{subfields}.input(:value, :as => :datetime#{common_options})\n"
    haml << "        -elsif custom_field.decimal?\n"
    haml << "          =#{subfields}.input(:value, :as => :decimal#{common_options})\n"
    haml << "        -else\n"
    haml << "          =#{subfields}.input(:value, :as => :string#{common_options})\n"
    return haml
  end
















  # class IkaFormBuilder < SimpleForm::FormBuilder

  #   def association(association, options={}, &block)
  #     options = options.dup

  #     return simple_fields_for(*[association,
  #                                options.delete(:collection), options].compact, &block) if block_given?

  #     raise ArgumentError, "Association cannot be used in forms not associated with an object" unless @object

  #     reflection = find_association_reflection(association)
  #     raise "Association #{association.inspect} not found" unless reflection

  #     # Determinates source
  #     source = (options[:source] ? options[:source].split('#') : [reflection.class_name.underscore, "all"])
  #     raise ArgumentError.new("Source must be defined in 'object#filter' format.") if source[1].blank?
  #     filter = source[1]
  #     source = source[0]
  #     source_object = (source == "self" ? @object : source.classify.constantize)
  #     count = source_object.send(filter).count

  #     # Determinates if radio, select or unroll is needed...
  #     nature = options[:as] || (count <= 80 ? :select : :unroll)

  #     buttons = options.delete(:new)
  #     buttons ||= {:new => {}}
  #     options[:collection] ||= options.fetch(:collection) {
  #       # reflection.klass.all(reflection.options.slice(:conditions, :order))
  #       source_object.send(filter)
  #     }

  #     attribute = case reflection.macro
  #       when :belongs_to
  #         (reflection.respond_to?(:options) && reflection.options[:foreign_key]) || :"#{reflection.name}_id"
  #       when :has_one
  #         raise ArgumentError, ":has_one associations are not supported by f.association"
  #       else
  #         if options[:as] == :select
  #           html_options = options[:input_html] ||= {}
  #           html_options[:size] ||= 5
  #           html_options[:multiple] = true unless html_options.key?(:multiple)
  #         end

  #         # Force the association to be preloaded for performance.
  #         if options[:preload] != false && object.respond_to?(association)
  #           target = object.send(association)
  #           target.to_a if target.respond_to?(:to_a)
  #         end

  #         :"#{reflection.name.to_s.singularize}_ids"
  #     end

  #     #
  #     id = "#{@object.class.name.underscore}_#{attribute}"
  #     html = input(attribute, options.merge(:reflection => reflection, :wrapper => :append)) do
  #       input_html = "".html_safe
  #       attrs = options.dup
  #       attrs[:as] = nature
  #       attrs[:id] = id
  #       if nature == :select
  #         attrs["data-refresh"] = @template.url_for(:controller => :interfacers, :action => :unroll, :source => source, :filter => filter, :model => @object.class.name.underscore, :id => (@object.id || 0))
  #         attrs["data-id-parameter-name"] = "selected"
  #       elsif nature == :unroll
  #         attrs["data-refresh"] = @template.url_for(:controller => :interfacers, :action => :search_for, :source => source, :filter => filter, :model => @object.class.name.underscore, :id => (@object.id || 0))
  #       end
  #       input_html << self.input_field(attribute, attrs)
  #       for tool in [:new]
  #         unless buttons.has_key?(tool) and buttons[tool].nil?
  #           input_html << @template.link_to(@template.content_tag(:span, nil, :class => "icon") + @template.content_tag(:span, tool.t(:scope => "labels"), :class => "text"), @template.url_for({:action => :new, :controller => reflection.class_name.underscore.pluralize}.merge(buttons[tool]||{})), "data-#{tool}-item" => id, :class => "btn btn-#{tool}")
  #         end
  #       end
  #       input_html
  #     end
  #     # if buttons
  #     #   html << @template.link_to(:new.t(:scope => "labels"), @template.url_for(:action => :new), "data-new-item" => "test", :class => :btn)
  #     #   html = @template.content_tag(:div, html, :class => "input-append")
  #     #   # if buttons.is_a? Symbol
  #     #   #   buttons = {:controller => buttons.to_s.pluralize.to_sym}
  #     #   # elsif buttons.is_a? TrueClass
  #     #   #   buttons = {}
  #     #   # end
  #     #   # if buttons.is_a?(Hash) and [:select, :dyselect, :combo_box].include?(type)
  #     #   #   options[:edit] = {} unless options[:edit].is_a? Hash
  #     #   #   if name.to_s.match(/_id$/) and refl = @class.reflections[name.to_s[0..-4].to_sym]
  #     #   #     buttons[:controller] ||= refl.class_name.underscore.pluralize
  #     #   #     options[:edit][:controller] ||= buttons[:controller]
  #     #   #   end
  #     #   #   buttons[:action] ||= :new
  #     #   #   options[:edit][:action] ||= :edit
  #     #   #   if type == :select
  #     #   #     input << link_to(label, buttons, :class => :fastadd, "data-confirm" => ::I18n.t('notifications.you_will_lose_all_your_current_data')) unless request.xhr?
  #     #   #   elsif true # authorized?(buttons)
  #     #   #     data = (options[:update] ? options[:update] : rlid)
  #     #   #     input << content_tag(:span, link_to(:new.t(:scope => "labels"), @controller.url_for(buttons), "data-new-item" => data, :tool => :new).html_safe, :class => "mini-toolbar")
  #     #   #   end
  #     #   # end
  #     # end
  #     return html
  #   end

  #   # Permits to define an input for the object
  #   def input(attribute_name, options = {}, &block)
  #     options[:input_html] ||= {}
  #     options[:input_html].update :class => 'custom'
  #     super
  #   end

  #   # Permits to add all custom fields (see CustomField)
  #   def custom_fields(*args)
  #   end

  #   # Permits to define a nested form
  #   def nested(*args)
  #   end

  #   # Permits to define a custom field
  #   def custom_field(*args)
  #   end
  # end



  # class Formika < ActionView::Helpers::FormBuilder
  #   include ActionView::Helpers

  #   def initialize(record, options = {})
  #     @record = record
  #     @class = record.class
  #     @controller = options[:controller]
  #   end


  #   def input(name, options={}, html_options = {})
  #     classes = [:field]
  #     input_id = rand.to_s
  #     html = ""

  #     # input
  #     column = @class.columns_hash[name.to_s]
  #     input_id = @class.name.tableize.singularize << '_' << name.to_s
  #     for k, v in options
  #       html_options[k] = v if k.to_s.match(/^data\-/)
  #     end
  #     type = options[:as]
  #     if name.to_s.match /password/
  #       html_options[:size] ||= 12
  #       type ||= :password
  #     end

  #     html_options[:size] = options[:size]||24
  #     html_options[:class] = options[:class].to_s
  #     html_options[:required] = true if options[:required]
  #     if column
  #       type ||= column.type
  #       html_options[:required] ||= true unless column.null or type == :boolean
  #       unless column.limit.nil?
  #         html_options[:size] = column.limit if column.limit < html_options[:size]
  #         html_options[:maxlength] = column.limit
  #       end
  #     end
  #     html_options[:size] ||= 16 if type == :integer
  #     if type == :date
  #       html_options[:size] ||= 10
  #     elsif type == :timestamp
  #       type = :datetime
  #     end

  #     options[:options] ||= {}

  #     if options[:choices]
  #       html_options.delete :size
  #       html_options.delete :maxlength
  #       rlid = options[:id]
  #       if options[:choices].is_a? Array
  #         type = :select if type != :radio
  #       elsif options[:choices].is_a? Hash
  #         type = :dyselect
  #         html_options[:id] = rlid
  #       elsif options[:choices].is_a? Symbol
  #         type = :combo_box
  #         html_options[:id] = rlid
  #         # options[:options][:field_id] = rlid
  #       else
  #         raise ArgumentError.new("Option :choices must be Array, Symbol or Hash (got #{options[:choices].class.name})")
  #       end
  #     end

  #     input = case type
  #             when :password
  #               password_field(@record, name, html_options)
  #             when :label
  #               @record.send(name)
  #             when :boolean
  #               check_box(@record, name, html_options)
  #             when :select
  #               options[:choices].insert(0, [options[:options].delete(:include_blank), '']) if options[:options][:include_blank].is_a? String
  #               select(@record, name, options[:choices], options[:options], html_options)
  #             when :dyselect
  #               select(@record, name, options_for_unroll(options[:choices]), options[:options], html_options.merge("data-refresh" => @controller.url_for(options[:choices].merge(:controller => :interfacers, :action => :unroll_options)), "data-id-parameter-name" => "selected") )
  #             # when :combo_box
  #             #   combo_box(@record, name, options[:choices], options[:options].merge(:controller => :interfacers), html_options)
  #             when :radio
  #               options[:choices].collect{|x| content_tag(:span, radio_button(@record, name, x[1], x[2]||{}) + " " + content_tag(:label, x[0], :for => input_id + '_' + x[1].to_s), :class => :rad)}.join(" ").html_safe
  #             when :textarea, :text_area
  #               text_area(@record, name, :cols => options[:options][:cols]||50, :rows => options[:options][:rows]||2, :class => (options[:options][:cols]==80 ? :code : nil))
  #             # when :date
  #             #   date_field(@record, name, html_options)
  #             # when :datetime
  #             #   datetime_field(@record, name, html_options)
  #             else
  #               text_field(@record, name, html_options)
  #             end

  #     if options[:new].is_a? Symbol
  #       options[:new] = {:controller => options[:new].to_s.pluralize.to_sym}
  #     elsif options[:new].is_a? TrueClass
  #       options[:new] = {}
  #     end
  #     if options[:new].is_a?(Hash) and [:select, :dyselect, :combo_box].include?(type)
  #       options[:edit] = {} unless options[:edit].is_a? Hash
  #       if name.to_s.match(/_id$/) and refl = @class.reflections[name.to_s[0..-4].to_sym]
  #         options[:new][:controller] ||= refl.class_name.underscore.pluralize
  #         options[:edit][:controller] ||= options[:new][:controller]
  #       end
  #       options[:new][:action] ||= :new
  #       options[:edit][:action] ||= :edit
  #       if type == :select
  #         input << link_to(label, options[:new], :class => :fastadd, "data-confirm" => ::I18n.t('notifications.you_will_lose_all_your_current_data')) unless request.xhr?
  #       elsif true # authorized?(options[:new])
  #         data = (options[:update] ? options[:update] : rlid)
  #         input << content_tag(:span, link_to(:new.t(:scope => "labels"), @controller.url_for(options[:new]), "data-new-item" => data, :tool => :new).html_safe, :class => "mini-toolbar")
  #       end
  #     end

  #     # label
  #     label = options[:label] || @class.human_attribute_name(name.to_s.gsub(/_id$/, ''))
  #     html << content_tag(:label, label, :for => input_id)

  #     html << input # text_field(@record, name)
  #     return content_tag(:div,html.html_safe, :class => classes.join(" "))
  #   end


  #   def custom_field(label, input, options = {})
  #     return content_tag(:div, name.to_s, :class => :input)
  #   end

  #   private

  # end



  # class Formalize
  #   attr_reader :items

  #   def initialize()
  #     @items = []
  #   end

  #   def title(value = "general-informations".to_sym, options={})
  #     @items << options.merge({:nature => :title, :value => value})
  #   end

  #   def field(*params)
  #     item = params[2]||{}
  #     id = item[:id]||"ff" << Time.now.to_i.to_s(36) << rand.to_s[2..-1].to_i.to_s(36)
  #     if params[1].is_a? Symbol
  #       item[:model] = params[0]
  #       item[:attribute] = params[1]
  #     else
  #       item[:label] = params[0]
  #       item[:field] = params[1]
  #     end
  #     item[:nature] = :field
  #     item[:id] = id
  #     @items << item
  #     return id
  #   end

  #   # def error(*params)
  #   def error(object)
  #     @items << {:nature => :error, :object => object}
  #   end
  # end


  # def formalize(options={})
  #   raise ArgumentError.new("Missing block") unless block_given?
  #   form = Formalize.new
  #   yield form
  #   return formalize_items(form, options).html_safe
  # end


  # protected

  # # This methods build a form item after item
  # def formalize_items(form, form_options)
  #   code = ''
  #   controller = self.controller
  #   xcn = 2

  #   # build HTML
  #   for item in form.items
  #     css_class = item[:nature].to_s

  #     # item
  #     item_code = ''
  #     case item[:nature]
  #     when :error
  #       item_code << content_tag(:td, error_messages(item[:object]), :class => "error", :colspan => xcn)
  #     when :title
  #       if item[:value].is_a? Symbol
  #         #calls = caller
  #         #file = calls[3].split(/\:\d+\:/)[0].split('/')[-1].split('.')[0]
  #         options = item.dup
  #         options.delete_if{|k,v| [:nature, :value].include?(k)}
  #         item[:value] = tl(item[:value], options)
  #       end
  #       item_code << content_tag(:th,item[:value].to_s, :class => "title", :id => item[:value].to_s.lower_ascii, :colspan => xcn)
  #     when :field
  #       fragments = item_fragments(item)
  #       item_code << content_tag(:td, fragments[:label], :class => "label")
  #       item_code << content_tag(:td, fragments[:input], :class => "input")
  #       # item_code << content_tag(:td, fragments[:help],  :class => "help")
  #     end
  #     unless item_code.blank?
  #       html_options = item[:html_options]||{}
  #       html_options[:class] = css_class
  #       code << content_tag(:tr, item_code.html_safe, html_options)
  #     end

  #   end
  #   code = content_tag(:table, code.html_safe, :class => 'formalize',:id => form_options[:id])
  #   return code
  # end



  # def item_fragments(item)
  #   fragments = {}


  #   #     help_tags = [:info, :example, :hint]
  #   #     help = ''
  #   #     for hs in help_tags
  #   #       item[hs] = translate_help(item, hs)
  #   #       #      help << content_tag(:div,l(hs, [content_tag(:span,item[hs].to_s)]), :class => hs) if item[hs]
  #   #       help << content_tag(:div,t(hs), :class => hs) if item[hs]
  #   #     end
  #   #     fragments[:help] = help

  #   #          help_options = {:class => "help", :id => options[:help_id]}
  #   #          help_options[:colspan] = 1+xcn-xcn*col if c==col-1 and xcn*col<xcn
  #   #label = content_tag(:td, label, :class => "label", :id => options[:label_id])
  #   #input = content_tag(:td, input, :class => "input", :id => options[:input_id])
  #   #help  = content_tag(:td, help,  :class => "help",  :id => options[:help_id])

  #   if item[:model] and item[:attribute]
  #     record  = item.delete(:model)
  #     method  = item.delete(:attribute)
  #     options = item

  #     record.to_sym if record.is_a?(String)
  #     object = record.is_a?(Symbol) ? instance_variable_get('@' + record.to_s) : record
  #     raise Exception.new("Object #{record.inspect} is " << object.inspect) if object.nil?
  #     model = object.class
  #     raise Exception.new('ModelError on object (not an ActiveRecord): ' << object.class.to_s) unless model.ancestors.include? ActiveRecord::Base # methods.include? "create"

  #     #      record = model.name.underscore.to_sym
  #     column = model.columns_hash[method.to_s]

  #     options[:field] = :password if method.to_s.match /password/

  #     input_id = object.class.name.tableize.singularize << '_' << method.to_s

  #     html_options = {}
  #     for k, v in options
  #       html_options[k] = v if k.to_s.match(/^data\-/)
  #     end
  #     html_options[:size] = options[:size]||24
  #     html_options[:class] = options[:class].to_s
  #     if column.nil?
  #       html_options[:required] = true if options[:null]==false
  #       # html_options[:class] << ' notnull' if options[:null]==false
  #       if method.to_s.match /password/
  #         html_options[:size] = 12
  #         options[:field] = :password if options[:field].nil?
  #       end
  #     else
  #       html_options[:required] = true unless column.null or column.type == :boolean
  #       # html_options[:class] << ' notnull' unless column.null
  #       html_options[:size] = 16 if column.type==:integer
  #       unless column.limit.nil?
  #         html_options[:size] = column.limit if column.limit<html_options[:size]
  #         html_options[:maxlength] = column.limit
  #       end
  #       options[:field] = :checkbox if column.type==:boolean
  #       if column.type==:date
  #         options[:field] = :date
  #         html_options[:size] = 10
  #       elsif column.type==:datetime or column.type==:timestamp
  #         options[:field] = :datetime
  #       end
  #     end

  #     options[:options] ||= {}

  #     if options[:choices]
  #       html_options.delete :size
  #       html_options.delete :maxlength
  #       rlid = options[:id]
  #       if options[:choices].is_a? Array
  #         options[:field] = :select if options[:field]!=:radio
  #       elsif options[:choices].is_a? Hash
  #         options[:field] = :dyselect
  #         html_options[:id] = rlid
  #       elsif options[:choices].is_a? Symbol
  #         options[:field] = :combo_box
  #         html_options[:id] = rlid
  #         # options[:options][:field_id] = rlid
  #       else
  #         raise ArgumentError.new("Option :choices must be Array, Symbol or Hash (got #{options[:choices].class.name})")
  #       end
  #     end

  #     input = case options[:field]
  #             when :password
  #               password_field(record, method, html_options)
  #             when :label
  #               object.send(method)
  #             when :checkbox
  #               check_box(record, method, html_options)
  #             when :select
  #               options[:choices].insert(0, [options[:options].delete(:include_blank), '']) if options[:options][:include_blank].is_a? String
  #               select(record, method, options[:choices], options[:options], html_options)
  #             when :dyselect
  #               select(record, method, options_for_unroll(options[:choices]), options[:options], html_options.merge("data-refresh" => url_for(options[:choices].merge(:controller => :interfacers, :action => :unroll_options)), "data-id-parameter-name" => "selected") )
  #             when :combo_box
  #               combo_box(record, method, options[:choices], options[:options].merge(:controller => :interfacers), html_options)
  #             when :radio
  #               options[:choices].collect{|x| content_tag(:span, radio_button(record, method, x[1], x[2]||{}) + " " + content_tag(:label, x[0], :for => input_id + '_' + x[1].to_s), :class => :rad)}.join(" ").html_safe
  #             when :textarea
  #               text_area(record, method, :cols => options[:options][:cols]||50, :rows => options[:options][:rows]||2, :class => (options[:options][:cols]==80 ? :code : nil))
  #             when :date
  #               date_field(record, method, html_options)
  #             when :datetime
  #               datetime_field(record, method, html_options)
  #             else
  #               text_field(record, method, html_options)
  #             end

  #     if options[:new].is_a? Symbol
  #       options[:new] = {:controller => options[:new].to_s.pluralize.to_sym}
  #     elsif options[:new].is_a? TrueClass
  #       options[:new] = {}
  #     end
  #     if options[:new].is_a?(Hash) and [:select, :dyselect, :combo_box].include?(options[:field])
  #       options[:edit] = {} unless options[:edit].is_a? Hash
  #       if method.to_s.match(/_id$/) and refl = model.reflections[method.to_s[0..-4].to_sym]
  #         options[:new][:controller] ||= refl.class_name.underscore.pluralize
  #         options[:edit][:controller] ||= options[:new][:controller]
  #       end
  #       options[:new][:action] ||= :new
  #       options[:edit][:action] ||= :edit
  #       if options[:field] == :select
  #         input << link_to(label, options[:new], :class => :fastadd, "data-confirm" => ::I18n.t('notifications.you_will_lose_all_your_current_data')) unless request.xhr?
  #       elsif authorized?(options[:new])
  #         data = (options[:update] ? options[:update] : rlid)
  #         # input << content_tag(:span, content_tag(:span, link_to(tg(:new), options[:new], "data-new-item" => data, :class => "icon im-new").html_safe, :class => :tool).html_safe, :class => "toolbar mini-toolbar")
  #         input << content_tag(:span, tool_to(tg(:new), options[:new], "data-new-item" => data, :tool => :new).html_safe, :class => "mini-toolbar")

  #       end
  #     end

  #     label = options[:label] || object.class.human_attribute_name(method.to_s.gsub(/_id$/, ''))
  #     label = content_tag(:label, label, :for => input_id) if object!=record
  #   elsif item[:field]
  #     label = item[:label]||'[NoLabel]'
  #     if item[:field].is_a? Hash
  #       options = item[:field].dup
  #       options[:options]||={}
  #       datatype = options.delete(:datatype)
  #       name  = options.delete(:name)
  #       value = options.delete(:value)
  #       input = case datatype
  #               when :boolean
  #                 hidden_field_tag(name, "0") << check_box_tag(name, "1", value, options)
  #               when :string
  #                 size = (options[:size]||0).to_i
  #                 if size>64
  #                   text_area_tag(name, value, :id => options[:id], :maxlength => size, :cols => 50, :rows => 2)
  #                 else
  #                   text_field_tag(name, value, :id => options[:id], :maxlength => size, :size => size)
  #                 end
  #               when :radio
  #                 options[:choices].collect{ |x| content_tag(:span, radio_button_tag(name, x[1], (value.to_s==x[1].to_s), :id => "#{name}_#{x[1]}") << " " << content_tag(:label,x[0], :for => "#{name}_#{x[1]}"), :class => :rad) }.join(" ").html_safe
  #               when :choice
  #                 options[:choices].insert(0,[options[:options].delete(:include_blank), '']) if options[:options][:include_blank].is_a? String
  #                 content = select_tag(name, options_for_select(options[:choices], value), :id => options[:id])
  #                 if options[:new].is_a? Hash
  #                   content << link_to(tg(options[:new].delete(:label)||:new), options[:new], :class => :fastadd)
  #                 end
  #                 content
  #               when :record
  #                 model = options[:model]
  #                 instance = model.new
  #                 method_name = [:label, :native_name, :name, :to_s, :inspect].detect{|x| instance.respond_to?(x)}
  #                 choices = model.collect{|x| [x.send(method_name), x.id]}
  #                 select_tag(name, options_for_select([""]+choices, (value.is_a?(ActiveRecord::Base) ? value.id : value)), :id => options[:id])
  #               when :date
  #                 date_select(name, value, :start_year => 1980)
  #               when :datetime
  #                 datetime_select(name, value, :default => Time.now, :start_year => 1980)
  #               else
  #                 text_field_tag(name, value, :id => options[:id])
  #               end

  #     else
  #       input = item[:field].to_s
  #     end
  #   else
  #     raise Exception.new("Unable to build fragments without :model/:attribute or :field")
  #   end
  #   fragments[:label] = label
  #   fragments[:input] = input
  #   return fragments
  # end


  # def translate_help(options,nature,id=nil)
  #   t = nil
  #   if options[nature].nil? and id
  #     t = lh(controller.controller_name.to_sym, controller.action_name.to_sym, (id << '_' << nature.to_s).to_sym)
  #   elsif options[nature].is_a? Symbol
  #     t = tc(options[nature])
  #   elsif options[nature].is_a? String
  #     t = options[nature]
  #   end
  #   return t
  # end

  # Imported from app/helpers/accountancy_helper.rb







  # Imported from app/helpers/management_helper.rb


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

  SALES_STEPS = [
                 {:name => :products,   :actions => [{:controller => :sales, :action => :show, :step => :products}, "sales#new", "sales#create", "sales#edit", "sales#update", "sale_items#new", "sale_items#create", "sale_items#edit", "sale_items#update", "sale_items#destroy"], :states => ['aborted', 'draft', 'estimate', 'refused', 'order', 'invoice']},
                 {:name => :deliveries, :actions => [{:controller => :sales, :action => :show, :step => :deliveries}, "outgoing_deliveries#show", "outgoing_deliveries#new", "outgoing_deliveries#create", "outgoing_deliveries#edit", "outgoing_deliveries#update"], :states => ['order', 'invoice']},
                 {:name => :summary,    :actions => [{:controller => :sales, :action => :show, :step => :summary}], :states => ['invoice']}
                ].collect{|s| {:name => s[:name], :actions => s[:actions].collect{|u| (u.is_a?(String) ? {:controller => u.split('#')[0].to_sym, :action => u.split('#')[1].to_sym} : u)}, :states => s[:states]}}.freeze

  def sales_steps(sale=nil)
    sale ||= @sale
    steps_tag(sale, SALES_STEPS, :name => :sales)
  end

  PURCHASE_STEPS = [
                    {:name => :products,   :actions => [{:controller => :purchases, :action => :show, :step => :products}, "purchases#new", "purchases#create", "purchases#edit", "purchases#update", "purchase_items#new", "purchase_items#create", "purchase_items#edit", "purchase_items#update", "purchase_items#destroy"], :states => ['aborted', 'draft', 'estimate', 'refused', 'order', 'invoice']},
                    {:name => :deliveries, :actions => [{:controller => :purchases, :action => :show, :step => :deliveries}, "incoming_deliveries#new", "incoming_deliveries#create", "incoming_deliveries#edit", "incoming_deliveries#update"], :states => ['order', 'invoice']},
                    {:name => :summary,    :actions => [{:controller => :purchases, :action => :show, :step => :summary}], :states => ['invoice']}
                   ].collect{|s| {:name => s[:name], :actions => s[:actions].collect{|u| (u.is_a?(String) ? {:controller => u.split('#')[0].to_sym, :action => u.split('#')[1].to_sym} : u)}, :states => s[:states]}}.freeze

  def purchase_steps(purchase=nil)
    purchase ||= @purchase
    steps_tag(purchase, PURCHASE_STEPS, :name => :purchase)
  end



  def product_stocks_options(product)
    options = []
    options += product.stocks.collect{|x| [x.label, x.id]}
    options += Warehouse.of_product(product).collect{|x| [x.name, -x.id]}
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

