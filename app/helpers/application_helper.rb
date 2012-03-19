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


# require_dependency Rails.root.join("lib", "exchanges", "svf", "loader").to_s


# module ActiveRecord
#   class Base


#     def merge(object, force=false)
#       raise Exception.new("Unvalid object to merge: #{object.class}. #{self.class} expected.") if object.class != self.class
#       reflections = self.class.reflections.collect{|k,v|  v if v.macro==:has_many}.compact
#       if force
#         for reflection in reflections
#           klass = reflection.class_name.constantize 
#           begin
#             klass.update_all({reflection.foreign_key=>self.id}, {reflection.foreign_key=>object.id})
#           rescue
#             for item in object.send(reflection.name)
#               begin
#                 item.send(reflection.foreign_key.to_s << '=', self.id)
#                 item.send(:update_without_callbacks)
#               rescue
#                 # If the item can't be attached, the item can't be.
#                 puts item.inspect
#                 klass.delete(item)
#               end
#             end
#           end
#         end
#         object.delete
#       else
#         ActiveRecord::Base.transaction do
#           for reflection in reflections
#             reflection.class_name.constantize.update_all({reflection.foreign_key=>self.id}, {reflection.foreign_key=>object.id})
#           end
#           object.delete
#         end
#       end
#       return self
#     end

#     def has_dependencies?

#     end


#   end
# end

# encoding: utf-8




module ApplicationHelper
  
  def authorized?(url={})
    if url.is_a?(String) and url.match(/\#/)
      action = url.split("#")
      url = {:controller=>action[0].to_sym, :action=>action[1].to_sym}
    end
    url[:controller]||=controller_name
    ApplicationController.authorized?(url)
  end

  # It's the menu generated for the current user
  # Therefore: No current user => No menu
  def menus
    session[:menus]
  end

  # Return an array of menu and submenu concerned by the action (controller#action)
  def reverse_menus(action=nil)
    action ||= "#{self.controller.controller_name}::#{action_name}"
    Ekylibre.reverse_menus[action]||[]
  end

  LEGALS_SENTENCE = ("Ekylibre " << Ekylibre.version << " - Ruby on Rails " << Rails.version << " - Ruby #{RUBY_VERSION}").freeze

  def legals_sentence
    # "Ekylibre " << Ekylibre.version << " - Ruby on Rails " << Rails.version << " - Ruby #{RUBY_VERSION} - " << ActiveRecord::Base.connection.adapter_name << " - " << ActiveRecord::Migrator.current_version.to_s
    LEGALS_SENTENCE
  end

  def choices_yes_no
    [ [::I18n.translate('general.y'), true], [I18n.t('general.n'), false] ]
  end

  def radio_yes_no(name, value=nil)
    radio_button_tag(name, 1, value.to_s=="1", id=>"#{name}_1") <<
      content_tag(:label, ::I18n.translate('general.y'), :for=>"#{name}_1") <<
      radio_button_tag(name, 0, value.to_s=="0", id=>"#{name}_0") <<
      content_tag(:label, ::I18n.translate('general.n'), :for=>"#{name}_0")
  end

  def radio_check_box(object_name, method, options = {}, checked_value = "1", unchecked_value = "0")
    # raise Exception.new eval("@#{object_name}.#{method}").inspect
    radio_button_tag(object_name, method, TrueClass, :id=>"#{object_name}_#{method}_#{checked_value}") << " " << 
      content_tag(:label, ::I18n.translate('general.y'), :for=>"#{object_name}_#{method}_#{checked_value}") << " " << 
      radio_button_tag(object_name, method, FalseClass, :id=>"#{object_name}_#{method}_#{unchecked_value}") << " " << 
      content_tag(:label, ::I18n.translate('general.n'), :for=>"#{object_name}_#{method}_#{unchecked_value}")
  end

  def number_to_accountancy(value)
    number = value.to_f
    if number.zero?
      return ''
    else
      number_to_currency(number, :precision=>2, :format=>'%n', :delimiter=>'&nbsp;', :separator=>',')
    end
  end

  def number_to_management(value)
    number = value.to_f
    number_to_currency(number, :precision=>2, :format=>'%n', :delimiter=>'&nbsp;', :separator=>',')
  end


  def preference(name)
    # name = self.controller.controller_name.to_s << name.to_s if name.to_s.match(/^\./)
    @current_company.preference(name)
  end

  def locale_selector
    # , :selected=>::I18n.locale)
    locales = ::I18n.active_locales.sort{|a,b| a.to_s<=>b.to_s}
    locale = nil # ::I18n.locale
    if params[:locale].to_s.match(/^[a-z][a-z][a-z]$/)
      locale = params[:locale].to_sym if locales.include? params[:locale].to_sym
    end
    locale ||= ::I18n.locale||::I18n.default_locale
    options = locales.collect do |l|
      content_tag(:option, ::I18n.translate("i18n.name", :locale=>l), {:value=>l, :dir=>::I18n.translate("i18n.dir", :locale=>l)}.merge(locale == l ? {:selected=>true} : {}))
    end.join.html_safe
    select_tag("locale", options, "data-redirect"=>url_for())
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
        return (html_options[:keep] ? "<a class='forbidden'>#{name}</a>".html_safe : "") unless authorized?(options) 
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
    # if authorized?({:controller=>controller_name, :action=>action_name}.merge(options))
    if authorized?({:controller=>controller_name, :action=>:index}.merge(options))
      content_tag(:li, link_to(*args).html_safe)
    else
      ''
    end
  end
  
  def countries
    [[]]+t('countries').to_a.sort{|a, b| a[1].ascii.to_s<=>b[1].ascii.to_s}.collect{|a| [a[1].to_s, a[0].to_s]}
  end

  def currencies
    Numisma.active_currencies.values.sort{|a, b| a.name.ascii.to_s<=>b.name.ascii.to_s}.collect{|c| [c.label, c.code]}
  end

  def languages
    I18n.valid_locales.collect{|l| [t("languages.#{l}"), l.to_s]}.to_a.sort{|a, b| a[0].ascii.to_s<=>b[0].ascii.to_s}
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


  def attribute_item(object, attribute, options={})
    value_class = 'value'
    if object.is_a? String
      label = object
      value = attribute
      value = value.to_s unless [String, TrueClass, FalseClass].include? value.class
    else
      #     label = object.class.human_attribute_name(attribute.to_s)
      value = object.send(attribute)
      model_name = object.class.name.underscore
      default = ["activerecord.attributes.#{model_name}.#{attribute.to_s}_id".to_sym]
      default << "activerecord.attributes.#{model_name}.#{attribute.to_s[0..-7]}".to_sym if attribute.to_s.match(/_label$/)
      default << "attributes.#{attribute.to_s}".to_sym
      default << "attributes.#{attribute.to_s}_id".to_sym
      label = ::I18n.translate("activerecord.attributes.#{model_name}.#{attribute.to_s}".to_sym, :default=>default)
      if value.is_a? ActiveRecord::Base
        record = value
        value = record.send(options[:label]||[:label, :name, :code, :number, :inspect].detect{|x| record.respond_to?(x)})
        options[:url] = {:action=>:show} if options[:url].is_a? TrueClass
        if options[:url].is_a? Hash
          options[:url][:id] ||= record.id
          # raise [model_name.pluralize, record, record.class.name.underscore.pluralize].inspect
          options[:url][:controller] ||= record.class.name.underscore.pluralize
        end
      else
        options[:url] = {:action=>:show} if options[:url].is_a? TrueClass
        if options[:url].is_a? Hash
          options[:url][:controller] ||= object.class.name.underscore.pluralize
          options[:url][:id] ||= object.id
        end
      end
      value_class  <<  ' code' if attribute.to_s == "code"
    end
    if [TrueClass, FalseClass].include? value.class
      value = content_tag(:div, "", :class=>"checkbox-#{value}")
    elsif ["Date", "Time", "DateTime"].include? value.class.name
      value = ::I18n.localize(value)
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif options[:duration]
      duration = value
      duration = duration*60 if options[:duration]==:minutes
      duration = duration*3600 if options[:duration]==:hours
      hours = (duration/3600).floor.to_i
      minutes = (duration/60-60*hours).floor.to_i
      seconds = (duration - 60*minutes - 3600*hours).round.to_i
      value = tg(:duration_in_hours_and_minutes, :hours=>hours, :minutes=>minutes, :seconds=>seconds)
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif value.is_a? String
      classes = []
      classes << "code" if attribute.to_s == "code"
      classes << value.class.name.underscore
      value = link_to(value.to_s, options[:url]) if options[:url]
      value = content_tag(:div, value.html_safe, :class=>classes.join(" "))
    end
    return label, value
  end


  #
  def evalue(object, attribute, options={})
    label, value = attribute_item(object, attribute, options={})
    if options[:orient] == :vertical
      code  = content_tag(:tr, content_tag(:td, label.to_s, :class=>:label))
      code << content_tag(:tr, content_tag(:td, value.to_s, :class=>:value))
      return content_tag(:table, code, :class=>"evalue verti")
    else
      code  = content_tag(:td, label.to_s, :class=>:label)
      code << content_tag(:td, value.to_s, :class=>:value)
      return content_tag(:table, content_tag(:tr, code), :class=>"evalue hori")
    end
  end


  def attributes_list(record, options={}, &block)
    columns = options[:columns] || 3
    attribute_list = AttributesList.new
    raise ArgumentError.new("One parameter needed") unless block.arity == 1
    yield attribute_list if block_given?
    unless options[:without_stamp]
      attribute_list.attribute :creator
      attribute_list.attribute :created_at
      attribute_list.attribute :updater
      attribute_list.attribute :updated_at
      # attribute_list.attribute :lock_version
    end
    code = ""
    size = attribute_list.items.size
    if size > 0
      column_height = (size.to_f/columns.to_f).ceil

      column_height.times do |c|
        line = ""
        columns.times do |i|
          args = attribute_list.items[i*column_height+c] # [c*columns+i]
          next if args.nil?
          label, value = if args[0] == :custom
                           attribute_item(*args[1])
                         elsif args[0] == :attribute
                           attribute_item(record, *args[1])
                         end
          line << content_tag(:td, label, :class=>:label) << content_tag(:td, value, :class=>:value)
        end
        code << content_tag(:tr, line.html_safe)
      end
      code = content_tag(:table, code.html_safe, :class=>"attributes-list")

      #       for c in 1..columns
      #         column = ""
      #         for i in 1..column_height
      #           args = attribute_list.items.shift
      #           break if args.nil?
      #           if args[0] == :evalue
      #             column << evalue(*args[1]) if args.is_a? Array
      #           elsif args[0] == :attribute
      #             column << evalue(record, *args[1]) if args.is_a? Array
      #           end
      #         end
      #         code << content_tag(:td, column.html_safe)
      #       end
      #       code = content_tag(:tr, code.html_safe)
      #      code = content_tag(:table, code.html_safe, :class=>"attributes-list")
    end
    return code.html_safe
  end

  class AttributesList
    attr_reader :items
    def initialize()
      @items = []
    end

    def attribute(*args)
      @items << [:attribute, args]
    end

    def custom(*args)
      @items << [:custom, args]
    end

  end    


  
  def last_page(menu)
    session[:last_page][menu.to_s]||url_for(:controller=>:dashboards, :action=>menu)
  end


  def doctype_tag
    return "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN\" \"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd\">".html_safe
  end



  # Permits to use themes for Ekylibre
  #  stylesheet_link_tag 'application', 'list', 'list-colors'
  #  stylesheet_link_tag 'print', :media=>'print'
  def theme_link_tag(name=nil)
    name ||= 'tekyla'
    code = ""
    for sheet in Dir.glob(Rails.root.join("public", "themes", name, "stylesheets", "*.css"))
      media = (sheet.match(/print/) ? :print : :screen)
      code << stylesheet_link_tag("/themes/#{name}/stylesheets/#{sheet.split(/[\\\/]+/)[-1]}", :media=>media)
    end
    return code.html_safe
  end


  def theme_button(name, theme='tekyla')
    image_path("/themes/#{theme}/images/buttons/#{name}.png").to_s
  end


  def resizable?
    return (session[:view_mode] == "resized" ? true : false)
  end

  def top_tag
    session[:last_page] ||= {}
    render :partial=>"layouts/top"
  end

  def title_tag
    r = reverse_menus
    title = if @current_company
              if r.empty?
                tc(:page_title_special, :company_code=>@current_company["code"], :company_name=>@current_company["name"], :action=>controller.human_action_name)
              else
                tc(:page_title, :company_code=>@current_company["code"], :company_name=>@current_company["name"], :action=>controller.human_action_name, :menu=>tl("menus.#{r[0]}"))
              end
            else
              tc(:page_title_by_default, :action=>controller.human_action_name)
            end
    return ("<title>" << h(title) << "</title>").html_safe
  end

  def title_header_tag
    titles = controller.human_action_name
    content_tag(:h1, titles, :class=>"title", :title=>titles)
  end


  def subheading(key, options={})
    content_tag(:div, tl(key, options), :class=>"subheading")
  end

  
  def side_tag # (submenu = self.controller.controller_name.to_sym)
    path = reverse_menus
    return '' if path.nil?
    render(:partial=>'layouts/side', :locals=>{:path=>path})
  end

  def side_module(name, options={}, &block)
    session[:modules] ||= {}
    session[:modules][name.to_s] = true unless [TrueClass, FalseClass].include?(session[:modules][name.to_s].class)
    shown = session[:modules][name]
    html = ""
    html << "<div class='sd-module#{' '+options[:class].to_s if options[:class]}#{' collapsed' unless shown}'>"
    html << "<div class='sd-title'>"
    html << link_to("", {:action=>:toggle_module, :controller=>:interfacers}, "data-toggle-module"=>name, :class=>(shown ? :hide : :show))
    html << "<h2>" + (options[:title]||tl(name)) + "</h2>"
    html << "</div>"
    html << "<div class='sd-content'" + (shown ? '' : ' style="display: none"') + ">"
    html << capture(&block)
    html << "</div>"
    html << "</div>"
    return html.html_safe
  end


  def notification_tag(mode)
    # content_tag(:div, flash[mode], :class=>'flash ' << mode.to_s) unless flash[mode].blank?
    code = ''
    if flash[:notifications].is_a?(Hash) and flash[:notifications][mode].is_a?(Array)
      for message in flash[:notifications][mode]
        message.force_encoding('UTF-8') if message.respond_to? :force_encoding
        code << "<div class='flash #{mode}'><h3>#{tg('notifications.' << mode.to_s)}</h3><p>#{h(message).gsub(/\n/, '<br/>')}</p></div>"
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

  def link_to_submit(form_name, label=:submit, options={})
    link_to_function(l(label), "document." << form_name << ".submit()", options.merge({:class=>:button}))
  end


  def table_of(array, html_options={}, &block)
    coln = html_options.delete(:columns)||3
    html, line, size = "", "", 0
    for item in array
      line << content_tag(:td, capture(item, &block))
      size += 1
      if size >= coln
        html << content_tag(:tr, line).html_safe
        line, size = "", 0
      end
    end
    html << content_tag(:tr, line).html_safe unless line.blank?
    return content_tag(:table, html, html_options).html_safe
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
      align = {'  '=>'center', ' x'=>'right', 'x '=>'left', 'xx'=>''}[(data[0][0..0] + data[0][-1..-1]).gsub(/[^\ ]/,'x')]
      title = data[1]||data[0].split(/[\:\\\/]+/)[-1].humanize
      src = data[0].strip
      if src.match(/^theme:/)
        src = image_path("/themes/#{@current_theme}/images/#{src.split(':')[1]}")
      else
        src = image_path(src)
      end
      '<img class="md md-' + align + '" alt="' + title + '" title="' + title + '" src="' + src + '"/>'
    end


    options[:url] ||= {}
    content = content.gsub(/\[\[>[^\|]+\|[^\]]*\]\]/) do |link|
      link = link[3..-3].split('|')
      url = link[0].split(/[\/\?\&]+/)
      url = options[:url].merge(:controller=>url[0], :action=>url[1])
      (authorized?(url) ? link_to(link[1], url) : link[1])
    end

    options[:method] = :get
    content = content.gsub(/\[\[[\w\-]+\|[^\]]*\]\]/) do |link|
      link = link[2..-3].split('|')
      url = url_for(options[:url].merge(:id=>link[0]))
      link_to(link[1].html_safe, url, {:remote=>true, "data-type"=>:html}.merge(options)) # REMOTE
    end

    content = content.gsub(/\[\[[\w\-]+\]\]/) do |link|
      link = link[2..-3]
      url = url_for(options[:url].merge(:id=>link))
      link_to(link.html_safe, url, {:remote=>true, "data-type"=>:html}.merge(options)) # REMOTE
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


  def article(file, options={})
    content = nil
    if File.exists?(file)
      File.open(file, 'r'){|f| content = f.read}
      content = content.split(/\n/)[1..-1].join("\n") if options.delete(:without_title)
      content = wikize(content.to_s, options)
    end
    return content
  end
  #   name = name.to_s
  #   content = ''
  #   file_name, locale = '', nil
  #   for locale in [I18n.locale, I18n.default_locale]
  #     help_dir = Rails.root.join("config", "locales", locale.to_s, "help")
  #     file_name = [name, name.split("-")[0].to_s << "-index"].detect do |pattern|
  #       File.exists? help_dir.join(pattern << ".txt")
  #     end
  #     break unless file_name.blank?
  #   end
  #   file_text = Rails.root.join("config", "locales", locale.to_s, "help", file_name.to_s << ".txt")
  #   if File.exists?(file_text)
  #     File.open(file_text, 'r') do |file|
  #       content = file.read
  #     end
  #     content = wikize(content, options)
  #   end
  #   return content
  # end

  


  # Unagi 鰻 
  # Flexible module management
  def unagi(options={})
    u = Unagi.new
    yield u
    tag = ""
    for c in u.cells
      code = content_tag(:h2, tl(c.title, c.options)) << content_tag(:div, capture(&c.block).html_safe)
      tag << content_tag(:div, code.html_safe, :class=>:menu)
    end
    return content_tag(:div, tag.html_safe, :class=>:unagi)
  end

  class Unagi
    attr_reader :cells
    def initialize
      @cells = []
    end
    def cell(title, options={}, &block)
      @cells << UnagiCell.new(title, options, &block)
    end
  end

  class UnagiCell
    attr_reader :title, :options, :block
    def initialize(title, options={}, &block)
      @title = title.to_s
      @options = options
      @block = block
    end

    def content
      "aAAAAAAAAAAAAAAAAAA" << capture(@block).to_s
    end
  end


  # Kujaku 孔雀
  # Search bar
  def kujaku(url={}, &block)
    k = Kujaku.new(caller[0].split(":in ")[0])
    if block_given?
      yield k
    else
      k.text
    end
    return "" if k.criteria.size.zero?
    tag = ""
    first = true
    for c in k.criteria
      code, options = "", c[:options]||{}
      if c[:type] == :mode
        code = content_tag(:label, options[:label]||tg(:mode))
        name = c[:name]||:mode
        params[name] ||= c[:modes][0].to_s
        i18n_root = options[:i18n_root]||'labels.criterion_modes.'
        for mode in c[:modes]
          radio  = radio_button_tag(name, mode, params[name] == mode.to_s)
          radio << " "
          radio << content_tag(:label, ::I18n.translate("#{i18n_root}#{mode}"), :for=>"#{name}_#{mode}")
          code << " ".html_safe << content_tag(:span, radio.html_safe, :class=>:rad)
        end
      elsif c[:type] == :radio
        code = content_tag(:label, options[:label]||tg(:state))
        params[c[:name]] ||= c[:states][0].to_s
        i18n_root = options[:i18n_root]||"labels.#{controller_name}_states."
        for state in c[:states]
          radio  = radio_button_tag(c[:name], state, params[c[:name]] == state.to_s)
          radio << " ".html_safe << content_tag(:label, ::I18n.translate("#{i18n_root}#{state}"), :for=>"#{c[:name]}_#{state}")
          code  << " ".html_safe << content_tag(:span, radio.html_safe, :class=>:rad)
        end
      elsif c[:type] == :text
        code = content_tag(:label, options[:label]||tg(:search))
        name = c[:name]||:q
        session[:kujaku] = {} unless session[:kujaku].is_a? Hash
        params[name] = session[:kujaku][c[:uid]] = (params[name]||session[:kujaku][c[:uid]])
        code << " ".html_safe << text_field_tag(name, params[name])
      elsif c[:type] == :date
        code = content_tag(:label, options[:label]||tg(:select_date))
        name = c[:name]||:d
        code << " ".html_safe << date_field_tag(name, params[name])
      elsif c[:type] == :crit
        code << send("#{c[:name]}_crit", *c[:args])
      elsif c[:type] == :criterion
        code << capture(&c[:block])
      end
      code = content_tag(:td, code.html_safe, (c[:html_options]||{}).merge(:class=>:crit))
      if first
        code << content_tag(:td, submit_tag(tl(:search_go), :disable_with=>tg(:please_wait), :name=>nil), :rowspan=>k.criteria.size, :class=>:submit)
        first = false
      end
      tag << content_tag(:tr, code.html_safe)
    end
    tag = form_tag(url, :method=>:get) {content_tag(:table, tag.html_safe)}
    return content_tag(:div, tag.to_s.html_safe, :class=>:kujaku)
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
    #   @criteria << {:type=>:mode, :modes=>modes, :options=>options}
    # end
    
    def radio(*states)
      options = states.delete_at(-1) if states[-1].is_a? Hash
      options = {} unless options.is_a? Hash
      name = options.delete(:name)||:s
      add_criterion :radio, :name=>name, :states=>states, :options=>options
    end
    
    def text(name=nil, options={})
      name ||= :q
      add_criterion :text, :name=>name, :options=>options
    end

    def date(name=nil, options={})
      name ||= :d
      add_criterion :date, :name=>name, :options=>options
    end

    def crit(name=nil, *args)
      add_criterion :crit, :name=>name, :args=>args
    end

    def criterion(html_options={}, &block)
      raise ArgumentError.new("No block given") unless block_given?
      add_criterion :criterion, :block=>block, :html_options=>html_options
    end

    private
    
    def add_criterion(type=nil, options={})
      @criteria << options.merge(:type=>type, :uid=>"#{@uid}:"+@criteria.size.to_s)
    end
  end





  # TABBOX
  def tabbox(id, options={})
    tb = Tabbox.new(id)
    yield tb
    tabs = ''
    taps = ''
    session[:tabbox] ||= {}
    for tab in tb.tabs
      session[:tabbox][tb.id] ||= tab[:index]
      style_name = (session[:tabbox][tb.id] == tab[:index] ? "current " : "")
      tabs << content_tag(:span, tab[:name], :class=>style_name + "tab", "data-tabbox-index"=>tab[:index])
      taps << content_tag(:div, capture(&tab[:block]).html_safe, :class=>style_name + "tabpanel", "data-tabbox-index"=>tab[:index])
    end
    return content_tag(:div, :class=>options[:class]||"tabbox", :id=>tb.id, "data-tabbox"=>url_for(:controller=>:interfacers, :action=>:toggle_tab, :id=>tb.id)) do
      code  = content_tag(:div, tabs.html_safe, :class=>:tabs)
      code << content_tag(:div, taps.html_safe, :class=>:tabpanels)
      code
    end
  end


  class Tabbox
    attr_accessor :tabs, :id

    def initialize(id)
      @tabs = []
      @id = id.to_s
      @sequence = 0
    end

    # Register a tab with a block of code
    # The name of tab use I18n searching in :
    #   - labels.<tabbox_id>_tabbox.<tab_name>
    #   - labels.<tab_name>
    def tab(name, options={}, &block)
      raise ArgumentError.new("No given block") unless block_given?
      if name.is_a?(Symbol)
        options[:default] = [] unless options[:default].is_a?(Array)
        options[:default] << ["labels.#{name}".to_sym]
        name = ::I18n.translate("labels.#{@id}_tabbox.#{name}", options) 
      end
      @tabs << {:name=>name, :index=>(@sequence*1).to_s(36), :block=>block}
      @sequence += 1
    end

  end


  # TOOLBAR

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
      # call = 'views.' << caller.detect{|x| x.match(/\/app\/views\//)}.split(/\/app\/views\//)[1].split('.')[0].gsub(/\//,'.') << '.'
      for tool in toolbar.tools
        nature, args = tool[0], tool[1]
        if nature == :link
          name = args[0]
          args[1] ||= {}
          args[2] ||= {}
          # args[2][:class] ||= "icon im-" + name.to_s.split('_')[-1]
          args[0] = ::I18n.t("actions.#{args[1][:controller]||controller_name}.#{name}".to_sym, {:default=>["labels.#{name}".to_sym]}.merge(args[2].delete(:i18n)||{})) if name.is_a? Symbol
          if name.is_a? Symbol and name!=:back
            args[1][:action] ||= name
            args[2][:class] = "icon im-" + args[1][:action].to_s if args[1][:action]
          else
            args[2][:class] = "icon im-" + args[1][:action].to_s.split('_')[-1] if args[1][:action]
          end
          code << content_tag(:div, link_to(*args), :class=>:tool) if authorized?(args[1])
        elsif nature == :print
          dn, args, url = tool[1], tool[2], tool[3]
          url[:controller] ||= controller_name
          for dt in @current_company.document_templates.find(:all, :conditions=>{:nature=>dn.to_s, :active=>true}, :order=>:name)
            code << content_tag(:div, link_to(tc(:print_with_template, :name=>dt.name), url.merge(:template=>dt.code), :class=>"icon im-print"), :class=>:tool) if authorized?(url)
          end
        elsif nature == :mail
          args[2] ||= {}
          args[2][:class] = "icon im-mail"
          code << content_tag(:div, mail_to(*args), :class=>:tool)
        elsif nature == :missing
          verb, record, tag_options = tool[1], tool[2], tool[3]
          action = verb # "#{record.class.name.underscore}_#{verb}"
          tag_options = {} unless tag_options.is_a? Hash
          tag_options[:class] = "icon im-#{verb}"
          url = {}
          url.update(tag_options.delete(:params)) if tag_options[:params].is_a? Hash
          url[:controller] ||= controller_name
          url[:action] = action
          url[:id] = record.id
          code << content_tag(:div, link_to(t("actions.#{url[:controller]}.#{action}", record.attributes.symbolize_keys), url, tag_options), :class=>:tool) if authorized?(url)
        end
      end
      if code.strip.length>0
        # code = content_tag(:ul, code.html_safe) << content_tag(:div)
        # code = content_tag(:h2, t(call << options[:title].to_s)) << code if options[:title]
        code = content_tag(:div, code.html_safe, :class=>'toolbar' + (options[:class].nil? ? '' : ' ' << options[:class].to_s)) + content_tag(:div, nil, :class=>:clearfix)
      end
    else
      raise Exception.new('No block given for toolbar')
    end
    return code.html_safe
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
        contents = ''
        contents << content_tag(:h3, header_message) unless header_message.blank?
        contents << content_tag(:p, introduction) unless introduction.blank?
        contents << content_tag(:ul, messages)
        content_tag(:div, contents.html_safe, :class=>"flash error")
      end
    else
      ''
    end
  end


  class Formalize
    attr_reader :lines

    def initialize()
      @lines = []
    end

    def title(value=:general_informations, options={})
      @lines << options.merge({:nature=>:title, :value=>value})
    end

    def field(*params)
      line = params[2]||{}
      id = line[:id]||"ff" << Time.now.to_i.to_s(36) << rand.to_s[2..-1].to_i.to_s(36)
      if params[1].is_a? Symbol
        line[:model] = params[0]
        line[:attribute] = params[1]
      else
        line[:label] = params[0]
        line[:field] = params[1]
      end
      line[:nature] = :field
      line[:id] = id
      @lines << line
      return id
    end

    # def error(*params)
    def error(object)
      @lines << {:nature=>:error, :object=>object}
    end
  end


  def formalize(options={})
    raise ArgumentError.new("Missing block") unless block_given?
    form = Formalize.new
    yield form
    return formalize_lines(form, options).html_safe
  end


  protected

  # This methods build a form line after line
  def formalize_lines(form, form_options)
    code = ''
    controller = self.controller
    xcn = 2
    
    # build HTML
    for line in form.lines
      css_class = line[:nature].to_s
      
      # line
      line_code = ''
      case line[:nature]
      when :error
        line_code << content_tag(:td, error_messages(line[:object]), :class=>"error", :colspan=>xcn)
      when :title
        if line[:value].is_a? Symbol
          #calls = caller
          #file = calls[3].split(/\:\d+\:/)[0].split('/')[-1].split('.')[0]
          options = line.dup
          options.delete_if{|k,v| [:nature, :value].include?(k)}
          line[:value] = tl(line[:value], options)
        end
        line_code << content_tag(:th,line[:value].to_s, :class=>"title", :id=>line[:value].to_s.lower_ascii, :colspan=>xcn)
      when :field
        fragments = line_fragments(line)
        line_code << content_tag(:td, fragments[:label], :class=>"label")
        line_code << content_tag(:td, fragments[:input], :class=>"input")
        # line_code << content_tag(:td, fragments[:help],  :class=>"help")
      end
      unless line_code.blank?
        html_options = line[:html_options]||{}
        html_options[:class] = css_class
        code << content_tag(:tr, line_code.html_safe, html_options)
      end
      
    end
    code = content_tag(:table, code.html_safe, :class=>'formalize',:id=>form_options[:id])
    return code
  end



  def line_fragments(line)
    fragments = {}


    #     help_tags = [:info, :example, :hint]
    #     help = ''
    #     for hs in help_tags
    #       line[hs] = translate_help(line, hs)
    #       #      help << content_tag(:div,l(hs, [content_tag(:span,line[hs].to_s)]), :class=>hs) if line[hs]
    #       help << content_tag(:div,t(hs), :class=>hs) if line[hs]
    #     end
    #     fragments[:help] = help

    #          help_options = {:class=>"help", :id=>options[:help_id]}
    #          help_options[:colspan] = 1+xcn-xcn*col if c==col-1 and xcn*col<xcn
    #label = content_tag(:td, label, :class=>"label", :id=>options[:label_id])
    #input = content_tag(:td, input, :class=>"input", :id=>options[:input_id])
    #help  = content_tag(:td, help,  :class=>"help",  :id=>options[:help_id])

    if line[:model] and line[:attribute]
      record  = line.delete(:model)
      method  = line.delete(:attribute)
      options = line

      record.to_sym if record.is_a?(String)
      object = record.is_a?(Symbol) ? instance_variable_get('@' << record.to_s) : record
      raise Exception.new("Object #{record.inspect} is " << object.inspect) if object.nil?
      model = object.class
      raise Exception.new('ModelError on object (not an ActiveRecord): ' << object.class.to_s) unless model.ancestors.include? ActiveRecord::Base # methods.include? "create"

      #      record = model.name.underscore.to_sym
      column = model.columns_hash[method.to_s]
      
      options[:field] = :password if method.to_s.match /password/
      
      input_id = object.class.name.tableize.singularize << '_' << method.to_s

      html_options = {}
      for k, v in options
        html_options[k] = v if k.to_s.match(/^data\-/)
      end
      html_options[:size] = options[:size]||24
      html_options[:class] = options[:class].to_s
      if column.nil?
        html_options[:class] << ' notnull' if options[:null]==false
        if method.to_s.match /password/
          html_options[:size] = 12
          options[:field] = :password if options[:field].nil?
        end
      else
        html_options[:class] << ' notnull' unless column.null
        html_options[:size] = 16 if column.type==:integer
        unless column.limit.nil?
          html_options[:size] = column.limit if column.limit<html_options[:size]
          html_options[:maxlength] = column.limit
        end
        options[:field] = :checkbox if column.type==:boolean
        if column.type==:date
          options[:field] = :date 
          html_options[:size] = 10
        elsif column.type==:datetime or column.type==:timestamp
          options[:field] = :datetime
        end
      end

      options[:options] ||= {}
      
      if options[:choices]
        html_options.delete :size
        html_options.delete :maxlength
        rlid = options[:id]
        if options[:choices].is_a? Array
          options[:field] = :select if options[:field]!=:radio
        elsif options[:choices].is_a? Hash
          options[:field] = :dyselect
          html_options[:id] = rlid
        elsif options[:choices].is_a? Symbol
          options[:field] = :combo_box
          html_options[:id] = rlid
          # options[:options][:field_id] = rlid
        else
          raise ArgumentError.new("Option :choices must be Array, Symbol or Hash (got #{options[:choices].class.name})")
        end
      end

      input = case options[:field]
              when :password
                password_field(record, method, html_options)
              when :label
                object.send(method)
              when :checkbox
                check_box(record, method, html_options)
              when :select
                options[:choices].insert(0, [options[:options].delete(:include_blank), '']) if options[:options][:include_blank].is_a? String
                select(record, method, options[:choices], options[:options], html_options)
              when :dyselect
                select(record, method, @current_company.reflection_options(options[:choices]), options[:options], html_options.merge("data-refresh"=>url_for(options[:choices].merge(:controller=>:interfacers, :action=>:unroll_options)), "data-id-parameter-name"=>"selected") )
              when :combo_box
                combo_box(record, method, options[:choices], options[:options].merge(:controller=>:interfacers), html_options)
              when :radio
                options[:choices].collect{|x| content_tag(:span, radio_button(record, method, x[1], x[2]||{}) + " " + content_tag(:label, x[0], :for=>input_id + '_' + x[1].to_s), :class=>:rad)}.join(" ").html_safe
              when :textarea
                text_area(record, method, :cols => options[:options][:cols]||30, :rows => options[:options][:rows]||3, :class=>(options[:options][:cols]==80 ? :code : nil))
              when :date
                date_field(record, method, html_options)
              when :datetime
                datetime_field(record, method, html_options)
              else
                text_field(record, method, html_options)
              end

      if options[:new].is_a? Symbol
        options[:new] = {:controller=>options[:new].to_s.pluralize.to_sym} 
      elsif options[:new].is_a? TrueClass
        options[:new] = {}
      end
      if options[:new].is_a?(Hash) and [:select, :dyselect, :combo_box].include?(options[:field])
        options[:edit] = {} unless options[:edit].is_a? Hash
        if method.to_s.match(/_id$/) and refl = model.reflections[method.to_s[0..-4].to_sym]
          options[:new][:controller] ||= refl.class_name.underscore.pluralize
          options[:edit][:controller] ||= options[:new][:controller]
        end
        options[:new][:action] ||= :new
        options[:edit][:action] ||= :edit
        if options[:field] == :select
          input << link_to(label, options[:new], :class=>:fastadd, :confirm=>::I18n.t('notifications.you_will_lose_all_your_current_data')) unless request.xhr?
        elsif authorized?(options[:new])
          data = (options[:update] ? options[:update] : rlid)
          input << content_tag(:span, content_tag(:span, link_to(tg(:new), options[:new], "data-new-item"=>data, :class=>"icon im-new").html_safe, :class=>:tool).html_safe, :class=>"toolbar mini-toolbar")

        end
      end
      
      label = options[:label] || object.class.human_attribute_name(method.to_s.gsub(/_id$/, ''))
      label = " " if options[:options][:hide_label] 
      label = content_tag(:label, label, :for=>input_id) if object!=record
    elsif line[:field]
      label = line[:label]||'[NoLabel]'
      if line[:field].is_a? Hash
        options = line[:field].dup
        options[:options]||={}
        datatype = options.delete(:datatype)
        name  = options.delete(:name)
        value = options.delete(:value)
        input = case datatype
                when :boolean
                  hidden_field_tag(name, "0") << check_box_tag(name, "1", value, options)
                when :string
                  size = (options[:size]||0).to_i
                  if size>64
                    text_area_tag(name, value, :id=>options[:id], :maxlength=>size, :cols => 30, :rows => 3)
                  else
                    text_field_tag(name, value, :id=>options[:id], :maxlength=>size, :size=>size)
                  end
                when :radio
                  options[:choices].collect{ |x| content_tag(:span, radio_button_tag(name, x[1], (value.to_s==x[1].to_s), :id=>"#{name}_#{x[1]}") << " " << content_tag(:label,x[0], :for=>"#{name}_#{x[1]}"), :class=>:rad) }.join(" ").html_safe
                when :choice
                  options[:choices].insert(0,[options[:options].delete(:include_blank), '']) if options[:options][:include_blank].is_a? String
                  content = select_tag(name, options_for_select(options[:choices], value), :id=>options[:id])
                  if options[:new].is_a? Hash
                    content << link_to(tg(options[:new].delete(:label)||:new), options[:new], :class=>:fastadd)
                  end
                  content
                when :record
                  model = options[:model]
                  instance = model.new
                  method_name = [:label, :native_name, :name, :to_s, :inspect].detect{|x| instance.respond_to?(x)}
                  choices = model.find_all_by_company_id(@current_company.id).collect{|x| [x.send(method_name), x.id]}
                  select_tag(name, options_for_select([""]+choices, (value.is_a?(ActiveRecord::Base) ? value.id : value)), :id=>options[:id])
                when :date
                  date_select(name, value, :start_year=>1980)
                when :datetime
                  datetime_select(name, value, :default=>Time.now, :start_year=>1980)
                else
                  text_field_tag(name, value, :id=>options[:id])
                end
        
      else
        input = line[:field].to_s
      end
    else
      raise Exception.new("Unable to build fragments without :model/:attribute or :field")
    end
    fragments[:label] = label
    fragments[:input] = input
    return fragments
  end
  

  def translate_help(options,nature,id=nil)
    t = nil
    if options[nature].nil? and id
      t = lh(controller.controller_name.to_sym, controller.action_name.to_sym, (id << '_' << nature.to_s).to_sym)
    elsif options[nature].is_a? Symbol
      t = tc(options[nature])
    elsif options[nature].is_a? String
      t = options[nature]
    end
    return t
  end

  # Imported from app/helpers/accountancy_helper.rb



  def major_accounts_tabs_tag
    majors = []
    majors << if params[:prefix].blank?
                content_tag(:strong, tc(:all_accounts))
              else
                link_to(tc(:all_accounts), :controller=>:accounts, :action=>:index, :prefix=>nil)
              end
    majors << @current_company.major_accounts.collect do |account| 
      if params[:prefix] == account.number.to_s
        content_tag(:strong, account.label)
      else
        link_to(account.label, params.merge(:controller=>:accounts, :action=>:index, :prefix=>account.number))
      end
    end
    if majors.size>0
      return content_tag(:div, majors.join.html_safe, :class=>'major-accounts')
    end
    return ""
  end


  def journals_tag
    render :partial=>"journals/index"
  end


  def journal_view_tag
    code = content_tag(:span, tg(:view))
    for mode in controller.journal_views
      if @journal_view == mode
        code << content_tag(:strong, tc("journal_view.#{mode}"))
      else
        code << link_to(tc("journal_view.#{mode}"), params.merge(:view=>mode)).html_safe
      end
    end
    return content_tag(:div, code, :class=>:view)
  end

  # Create a widget with all the possible periods
  def journal_period_crit(name=:period, value=nil, options={})
    configuration = {:custom=>:interval}
    configuration.update(options) if options.is_a?(Hash)
    configuration[:id] ||= name.to_s.gsub(/\W+/, '_').gsub(/(^_|_$)/, '')
    value = params[name]
    list = []
    list << [tc(:all_periods), "all"]
    for year in @current_company.financial_years.find(:all, :order=>:started_on)
      list << [year.code, year.started_on.to_s << "_" << year.stopped_on.to_s]
      list2 = []
      date = year.started_on
      while date<year.stopped_on and date < Date.today
        date2 = date.end_of_month
        list2 << [tc(:month_period, :year=>date.year, :month=>t("date.month_names")[date.month], :code=>year.code), date.to_s << "_" << date2.to_s]
        date = date2+1
      end
      list += list2.reverse
    end
    code = ""
    code << content_tag(:label, tc(:period), :for=>configuration[:id]) + " "
    fy = @current_company.current_financial_year
    params[:period] = value = value || (fy ? fy.started_on.to_s + "_" + fy.stopped_on.to_s : :all)
    if configuration[:custom]
      params[:started_on] = params[:started_on].to_date rescue (fy ? fy.started_on : Date.today)
      params[:stopped_on] = params[:stopped_on].to_date rescue (fy ? fy.stopped_on : Date.today)
      params[:stopped_on] = params[:started_on] if params[:started_on] > params[:stopped_on]
      list.insert(0, [tc(configuration[:custom]), configuration[:custom]])
      custom_id = "#{configuration[:id]}_#{configuration[:custom]}"
      toggle_method = "toggle#{custom_id.camelcase}"
      code << select_tag(name, options_for_select(list, value), :id=>configuration[:id], "data-show-value"=>"##{configuration[:id]}_")
      code << " " << content_tag(:span, tc(:manual_period, :start=>date_field_tag(:started_on, params[:started_on], :size=>8), :finish=>date_field_tag(:stopped_on, params[:stopped_on], :size=>8)).html_safe, :id=>custom_id)
    else
      code << select_tag(name, options_for_select(list, value), :id=>configuration[:id])
    end
    return code.html_safe
  end

  # Create a widget to select states of entries (and entry lines)
  def journal_entries_states_crit
    code = ""
    code << content_tag(:label, tc(:journal_entries_states))
    states = JournalEntry.states
    params[:states] = {} unless params[:states].is_a? Hash
    no_state = !states.detect{|x| params[:states].has_key?(x)}
    for state in states
      key = state.to_s
      name, id = "states[#{key}]", "states_#{key}"
      if active = (params[:states][key]=="1" or no_state)
        params[:states][key] = "1"
      else
        params[:states].delete(key)
      end
      code << " " << check_box_tag(name, "1", active, :id=>id)
      code << " " << content_tag(:label, JournalEntry.state_label(state), :for=>id)
    end
    return code.html_safe
  end

  # Create a widget to select some journals
  def journals_crit
    code, field = "", :journals
    code << content_tag(:label, Company.human_attribute_name("journals"))
    journals = @current_company.journals # .find(:all, :conditions=>["id IN (SELECT journal_id FROM journal_entry_lines WHERE company_id=? AND state=?)", @current_company.id, "draft"])
    params[field] = {} unless params[field].is_a? Hash
    no_journal = !journals.detect{|x| params[field].has_key?(x.id.to_s)}
    for journal in journals
      key = journal.id.to_s
      name, id = "#{field}[#{key}]", "#{field}_#{key}"
      if active = (params[field][key] == "1" or no_journal)
        params[field][key] = "1"
      else
        params[field].delete(key)
      end
      code << " " << check_box_tag(name, "1", active, :id=>id)
      code << " " << content_tag(:label, journal.name, :for=>id)
    end
    return code.html_safe
  end


  # Create a widget to select ranges of account
  # See Account#range_condition
  def accounts_range_crit
    id = :accounts
    params[id] = Account.clean_range_condition(params[id])
    code = ""
    code << content_tag(:label, tc(:accounts), :for=>id)
    code << " " << text_field_tag(id, params[id], :size=>30)
    return code.html_safe
  end




  # Imported from app/helpers/management_helper.rb


  def steps_tag(record, steps, options={})
    name = options[:name] || record.class.name.underscore
    state_method = options[:state_method] || :state
    state = record.send(state_method).to_s
    code = ''
    for step in steps
      title = tc("#{name}_steps.#{step[:name]}")
      classes  = "step"
      classes << " active" if step[:actions].detect{ |url| not url.detect{|k, v| params[k].to_s != v.to_s}} # url = {:action=>url.to_s} unless url.is_a? Hash
      if step[:states].include?(state) and record.id
        classes << " usable"
        title = link_to(title, step[:actions][0].merge(:id=>record.id)) 
      end
      code << content_tag(:td, '&nbsp;'.html_safe, :class=>'transition') unless code.blank?
      code << content_tag(:td, title, :class=>classes)
    end
    code = content_tag(:tr, code.html_safe)
    code = content_tag(:table, code.html_safe, :class=>:stepper)
    code.html_safe
  end

  SALES_STEPS = [
                 {:name=>:products,   :actions=>[{:controller=>:sales, :action=>:show, :step=>:products}, "sales#new", "sales#create", "sales#edit", "sales#update", "sale_lines#new", "sale_lines#create", "sale_lines#edit", "sale_lines#update", "sale_lines#destroy"], :states=>['aborted', 'draft', 'estimate', 'refused', 'order', 'invoice']},
                 {:name=>:deliveries, :actions=>[{:controller=>:sales, :action=>:show, :step=>:deliveries}, "outgoing_deliveries#show", "outgoing_deliveries#new", "outgoing_deliveries#create", "outgoing_deliveries#edit", "outgoing_deliveries#update"], :states=>['order', 'invoice']},
                 {:name=>:summary,    :actions=>[{:controller=>:sales, :action=>:show, :step=>:summary}], :states=>['invoice']}
                ].collect{|s| {:name=>s[:name], :actions=>s[:actions].collect{|u| (u.is_a?(String) ? {:controller=>u.split('#')[0].to_sym, :action=>u.split('#')[1].to_sym} : u)}, :states=>s[:states]}}.freeze

  def sales_steps(sale=nil)
    sale ||= @sale
    steps_tag(sale, SALES_STEPS, :name=>:sales)
  end

  PURCHASE_STEPS = [
                    {:name=>:products,   :actions=>[{:controller=>:purchases, :action=>:show, :step=>:products}, "purchases#new", "purchases#create", "purchases#edit", "purchases#update", "purchase_lines#new", "purchase_lines#create", "purchase_lines#edit", "purchase_lines#update", "purchase_lines#destroy"], :states=>['aborted', 'draft', 'estimate', 'refused', 'order', 'invoice']},
                    {:name=>:deliveries, :actions=>[{:controller=>:purchases, :action=>:show, :step=>:deliveries}, "incoming_deliveries#new", "incoming_deliveries#create", "incoming_deliveries#edit", "incoming_deliveries#update"], :states=>['order', 'invoice']},
                    {:name=>:summary,    :actions=>[{:controller=>:purchases, :action=>:show, :step=>:summary}], :states=>['invoice']}
                   ].collect{|s| {:name=>s[:name], :actions=>s[:actions].collect{|u| (u.is_a?(String) ? {:controller=>u.split('#')[0].to_sym, :action=>u.split('#')[1].to_sym} : u)}, :states=>s[:states]}}.freeze

  def purchase_steps(purchase=nil)
    purchase ||= @purchase
    steps_tag(purchase, PURCHASE_STEPS, :name=>:purchase)
  end



  def product_stocks_options(product)
    options = []
    options += product.stocks.collect{|x| [x.label, x.id]}
    options += @current_company.warehouses.find(:all, :conditions=>["(product_id=? AND reservoir=?) OR reservoir=?", product.id, true, false]).collect{|x| [x.name, -x.id]}
    return options
  end

  def toggle_tag(name=:orientation, modes = [:vertical, :horizontal])
    raise ArgumentError.new("Invalid name") unless name.to_s.match(/^[a-z\_]+$/)
    pref = @current_user.preference("interface.toggle.#{name}", modes[0].to_s)
    code = ""
    for mode in modes
      # code << link_to("", params.merge(name=>mode), :title=>tl("#{name}.#{mode}"), :class=>"icon im-#{mode}#{' current' if mode.to_s==pref.value}")
      if mode.to_s==pref.value
        code << content_tag(:a, nil, :title=>tl("#{name}.#{mode}"), :class=>"icon im-#{mode} current")
      else
        code << link_to("", params.merge(name=>mode), :title=>tl("#{name}.#{mode}"), :class=>"icon im-#{mode}")
      end
    end
    content_tag(:div, code.html_safe, :class=>"toggle tg-#{name}")
  end


  # Imported from app/helpers/relations_helper.rb
  def condition_label(condition)
    if condition.match(/^generic/)
      klass, attribute = condition.split(/\-/)[1].classify.constantize, condition.split(/\-/)[2]
      return tl("conditions.filter_on_attribute_of_class", :attribute=>klass.human_attribute_name(attribute), :class=>klass.model_name.human)
    else
      return tl("conditions.#{condition}")
    end
  end




  # Take an extra argument which will translate
  def number_to_money(amount, currency, options={})
    return unless amount and currency

    options.symbolize_keys!

    defaults  = I18n.translate('number.format'.to_sym, :locale => options[:locale], :default => {})
    defaultt  = I18n.translate('number.currency.format'.to_sym, :locale => options[:locale], :default => {})
    defaultt[:negative_format] ||= "-" + defaultt[:format] if defaultt[:format]
    formatcy  = I18n.translate("number.currency.formats.#{currency}".to_sym, :locale => options[:locale], :default => {})
    formatcy[:negative_format] ||= "-" + formatcy[:format] if formatcy[:format]

    prec = {}
    prec[:separator] = formatcy[:separator] || defaultt[:separator] || defaults[:separator]
    prec[:delimiter] = formatcy[:delimiter] || defaultt[:delimiter] || defaults[:delimiter]
    prec[:precision] = formatcy[:precision] || Numisma[currency].precision || defaultt[:precision]
    format           = formatcy[:format] || defaultt[:format] || defaults[:format]
    negative_format  = formatcy[:negative_format] || defaultt[:negative_format] || defaults[:negative_format] || "-" + format
    unit             = formatcy[:unit] || Numisma[currency].unit || currency

    # defaults  = {}.merge(defaults).merge!(formatcy)
    # defaults.merge!(defaultt)
    # defaults.merge!(formatcy)
    # defaults[:negative_format] = "-" + options[:format] if options[:format]
    # options   = defaults.merge!(options)
    
    # unit      = formatcy[:unit] || Numisma[currency].unit || currency
    # format    = options.delete(:format)

    # options[:precision] ||= Numisma[currency].precision

    # raise [amount, currency, prec, unit, format, negative_format].inspect

    if amount.to_f < 0
      format = negative_format # options.delete(:negative_format)
      amount = amount.respond_to?("abs") ? amount.abs : amount.sub(/^-/, '')
    end
    
    #begin
    # value = number_with_precision(amount, prec.merge(:raise => true))
    value = amount.to_s
    integers, decimals = value.split(/\./)
    # TODO: Find a better way to delimite thousands
    decimals = decimals.gsub(/0+$/, '').ljust(prec[:precision], '0').reverse.split(/(?=\d{3})/).reverse.collect{|x| x.reverse}.join(prec[:delimiter])
    value = integers.gsub(/^0+[1-9]+/, '').gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{prec[:delimiter]}")
    value += prec[:separator] + decimals unless decimals.blank?
    format.gsub(/%n/, value).gsub(/%u/, unit).gsub(/%s/, '&nbsp;').html_safe
    # rescue InvalidNumberError => e
    #   if options[:raise]
    #     raise
    #   else
    #     formatted_number = format.gsub(/%n/, e.number).gsub(/%u/, unit).gsub(/%s/, '&nbsp;')
    #     e.number.to_s.html_safe? ? formatted_number.html_safe : formatted_number
    #   end
    # end
  end


end

