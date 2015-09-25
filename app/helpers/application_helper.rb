# coding: utf-8
# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ##### END LICENSE BLOCK #####

module ApplicationHelper
  delegate :current_theme, to: :controller

  delegate :current_user, to: :controller

  # Helper which check authorization of an action
  def authorized?(url_options = {})
    controller.authorized?(url_options)
  end

  def selector_tag(name, choices = nil, options = {}, html_options = {})
    choices ||= :unroll
    choices = { action: choices } if choices.is_a?(Symbol)
    html_options[:data] ||= {}
    html_options[:data][:selector] = url_for(choices)
    html_options[:data][:selector_new_item] = url_for(options[:new]) if options[:new]
    text_field_tag(name, options[:value], html_options)
  end

  def selector(object_name, association, choices, options = {}, html_options = {})
    object = options[:object] || instance_variable_get("@#{object_name}")
    model = object.class
    unless reflection = object.class.reflect_on_association(association)
      fail ArgumentError, "Unknown reflection for #{model.name}: #{association.inspect}"
    end
    if reflection.macro != :belongs_to
      fail ArgumentError, "Reflection #{reflection.name} must be a belongs_to"
    end
    text_field(object_name, reflection.foreign_key, html_options.merge('data-selector' => url_for(choices)))
  end

  # LEGALS_ITEMS = [h("Ekylibre " + Ekylibre.version),  h("Ruby on Rails " + Rails.version),  h("Ruby "+ RUBY_VERSION.to_s)].join(" &ndash; ".html_safe).freeze

  def legals_sentence
    # "Ekylibre " << Ekylibre.version << " - Ruby on Rails " << Rails.version << " - Ruby #{RUBY_VERSION} - " << ActiveRecord::Base.connection.adapter_name << " - " << ActiveRecord::Migrator.current_version.to_s
    nbsp = '&nbsp;'.html_safe # ,  h("Ruby on Rails") + nbsp + Rails.version, ("HTML" + nbsp + "5").html_sa, h("CSS 3")
    [h('Ekylibre') + nbsp + Ekylibre.version].join(' &ndash; ').html_safe # ,  h("Ruby") + nbsp + RUBY_VERSION.to_s
    # return content_tag(:span, content_tag(:i, '') + nbsp + h("Ekylibre"), class: "brand") + nbsp + h(Ekylibre.version)
  end

  def choices_yes_no
    [[::I18n.translate('general.y'), true], [I18n.t('general.n'), false]]
  end

  def radio_yes_no(name, value = nil)
    radio_button_tag(name, 1, value.to_s == '1', id => "#{name}_1") <<
      content_tag(:label, ::I18n.translate('general.y'), for: "#{name}_1") <<
      radio_button_tag(name, 0, value.to_s == '0', id => "#{name}_0") <<
      content_tag(:label, ::I18n.translate('general.n'), for: "#{name}_0")
  end

  def radio_check_box(object_name, method, _options = {}, checked_value = '1', unchecked_value = '0')
    # raise StandardError.new eval("@#{object_name}.#{method}").inspect
    radio_button_tag(object_name, method, TrueClass, id: "#{object_name}_#{method}_#{checked_value}") << ' ' <<
      content_tag(:label, ::I18n.translate('general.y'), for: "#{object_name}_#{method}_#{checked_value}") << ' ' <<
      radio_button_tag(object_name, method, FalseClass, id: "#{object_name}_#{method}_#{unchecked_value}") << ' ' <<
      content_tag(:label, ::I18n.translate('general.n'), for: "#{object_name}_#{method}_#{unchecked_value}")
  end

  def number_to_accountancy(value, currency = nil)
    number = value.to_f
    (number.zero? ? '' : number.l(currency: currency || Preference[:currency]))
  end

  def number_to_management(value)
    number = value.to_f
    number.l
  end

  def human_age(seconds, options = {})
    return options[:default] || '&ndash;'.html_safe if seconds.nil?
    vals = []
    if (seconds.to_f / 1.year).floor > 0.0 && (!options[:display] || vals.size < options[:display])
      vals << :x_years.tl(count: (seconds / 1.year).floor)
      seconds -= 1.year * (seconds / 1.year).floor
    end
    if (seconds.to_f / 1.month).floor > 0.0 && (!options[:display] || vals.size < options[:display])
      vals << :x_months.tl(count: (seconds / 1.month).floor)
      seconds -= 1.month * (seconds / 1.month).floor
    end
    if (seconds.to_f / 1.day).floor > 0.0 && (!options[:display] || vals.size < options[:display])
      vals << :x_days.tl(count: (seconds / 1.day).floor)
      seconds -= 1.day * (seconds / 1.day).floor
    end
    if (seconds.to_f / 1.hour).floor > 0.0 && (!options[:display] || vals.size < options[:display])
      vals << :x_hours.tl(count: (seconds / 1.hour).floor)
      seconds -= 1.hour * (seconds / 1.hour).floor
    end
    vals.to_sentence
  end

  def human_duration(seconds, options = {})
    return options[:default] || '&ndash;'.html_safe if seconds.nil?
    vals = []
    vals << (seconds / 1.hour).floor
    seconds -= 1.hour * (seconds / 1.hour).floor
    vals << (seconds / 1.minute).floor.to_s.rjust(2, '0')
    seconds -= 1.minute * (seconds / 1.minute).floor
    # vals << seconds.round.to_s.rjust(2, "0")
    vals.join(':')
  end

  # def locale_selector
  #   # , :selected => ::I18n.locale)
  #   locales = ::I18n.available_locales.sort{|a,b| a.to_s <=> b.to_s}
  #   locale = nil # ::I18n.locale
  #   if params[:locale].to_s.match(/^[a-z][a-z][a-z]$/)
  #     locale = params[:locale].to_sym if locales.include? params[:locale].to_sym
  #   end
  #   locale ||= ::I18n.locale||::I18n.default_locale
  #   options = locales.collect do |l|
  #     content_tag(:option, ::I18n.translate("i18n.name", :locale => l), {:value => l, :dir => ::I18n.translate("i18n.dir", :locale => l)}.merge(locale == l ? {:selected => true} : {}))
  #   end.join.html_safe
  #   select_tag("locale", options, "data-redirect" => url_for())
  # end

  def locale_selector_tag
    locales = ::I18n.available_locales.sort { |a, b| a.to_s <=> b.to_s }
    # locales = ::I18n.valid_locales.sort{|a,b| a.to_s <=> b.to_s}
    locale = nil # ::I18n.locale
    if params[:locale].to_s.match(/^[a-z][a-z][a-z]$/)
      locale = params[:locale].to_sym if locales.include? params[:locale].to_sym
    end
    locale ||= ::I18n.locale || ::I18n.default_locale
    options = locales.collect do |l|
      content_tag(:option, ::I18n.translate('i18n.name', locale: l), { :value => l, :dir => ::I18n.translate('i18n.dir', locale: l), :selected => false, 'data-redirect' => url_for(locale: l) }.merge(locale == l ? { selected: true } : {}))
    end.join.html_safe
    select_tag('locale', options, 'data-use-redirect' => 'true')
  end

  def link_to_remove_nested_association(name, f)
    link_to_remove_association(content_tag(:i) + h("labels.remove_#{name}".t), f, 'data-no-turbolink' => true, :class => "nested-remove remove-#{name}")
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
        return (html_options[:remove] ? '' : content_tag(:a, name, class: html_options[:class].to_s + ' forbidden', disabled: true)) unless authorized?(options)
      end

      html_options = convert_options_to_data_attributes(options, html_options)
      begin
        url = url_for(options)
      rescue ActionController::UrlGenerationError => uge
        # Trying to fail gracefully in production
        raise uge unless Rails.env.production?
        ExceptionNotifier::Notifier.exception_notification(request.env, uge).deliver
        request.env['exception_notifier.delivered'] = true
        return content_tag(:a, name, class: html_options[:class].to_s + ' invalid invalid-route', disabled: true)
      end

      if html_options
        html_options = html_options.stringify_keys
        href = html_options['href']
        tag_options = tag_options(html_options)
      else
        tag_options = nil
      end

      href_attr = "href=\"" + url + "\"" unless href
      "<a #{href_attr}#{tag_options}>".html_safe + (name || url) + '</a>'.html_safe
    end
  end

  def li_link_to(*args)
    options = args[1] || {}
    # if authorized?({:controller => controller_name, :action => action_name}.merge(options))
    if authorized?({ controller: controller_path, action: :index }.merge(options))
      content_tag(:li, link_to(*args).html_safe)
    else
      ''
    end
  end

  def countries
    nomenclature_as_options(:countries)
  end

  def currencies
    nomenclature_as_options(:currencies)
  end

  def languages
    nomenclature_as_options(:languages)
  end

  # Returns a selection from names list
  def nomenclature_as_options(nomenclature_name, *args)
    options = args.extract_options!
    nomenclature = Nomen[nomenclature_name]
    items = args.shift || nomenclature.all
    items.collect do |name|
      item = nomenclature.find(name)
      [item.human_name, item.name]
    end.sort { |a, b| a.first <=> b.first }
  end

  # Returns a selection from names list
  def enumerize_as_options(model, attribute, *args)
    options = args.extract_options!
    enum = model.to_s.camelize.constantize.send(attribute)
    items = args.shift || enum.values
    items.collect do |name|
      [name.l, name]
    end.sort { |a, b| a.first <=> b.first }
  end

  def back_url
    :back
  end

  def link_to_back(options = {})
    options[:label] ||= :back
    link_to(options[:label].is_a?(String) ? options[:label] : options[:label].tl, back_url)
  end

  def attribute_item(object, attribute, options = {})
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
      default = ["activerecord.attributes.#{model_name}.#{attribute}_id".to_sym]
      default << "activerecord.attributes.#{model_name}.#{attribute.to_s[0..-7]}".to_sym if attribute.to_s.match(/_label$/)
      default << "attributes.#{attribute}".to_sym
      default << "attributes.#{attribute}_id".to_sym
      label = "activerecord.attributes.#{model_name}.#{attribute}".t(default: default)
      if value.is_a? ActiveRecord::Base
        record = value
        value = record.send(options[:label] || [:label, :name, :code, :number, :inspect].detect { |x| record.respond_to?(x) })
        options[:url] = { action: :show } if options[:url].is_a? TrueClass
        if options[:url].is_a? Hash
          options[:url][:id] ||= record.id
          #  raise [model_name.pluralize, record, record.class.name.underscore.pluralize].inspect
          options[:url][:controller] ||= record.class.name.underscore.pluralize
        end
      else
        options[:url] = { action: :show } if options[:url].is_a? TrueClass
        if options[:url].is_a? Hash
          options[:url][:controller] ||= object.class.name.underscore.pluralize
          options[:url][:id] ||= object.id
        end
      end
      value_class << ' code' if attribute.to_s == 'code'
    end
    if [TrueClass, FalseClass].include? value.class
      value = content_tag(:div, '', class: "checkbox-#{value}")
    elsif value.respond_to?(:text)
      value = value.send(:text)
    elsif attribute.to_s.match(/(^|_)currency$/)
      value = Nomen::Currency[value].human_name
    elsif options[:currency] && value.is_a?(Numeric)
      value = ::I18n.localize(value, currency: (options[:currency].is_a?(TrueClass) ? object.send(:currency) : options[:currency].is_a?(Symbol) ? object.send(options[:currency]) : options[:currency]))
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif value.respond_to?(:strftime) || value.is_a?(Numeric)
      value = value.l
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif options[:duration]
      duration = value
      duration *= 60 if options[:duration] == :minutes
      duration *= 3600 if options[:duration] == :hours
      hours = (duration / 3600).floor.to_i
      minutes = (duration / 60 - 60 * hours).floor.to_i
      seconds = (duration - 60 * minutes - 3600 * hours).round.to_i
      value = :duration_in_hours_and_minutes.tl(hours: hours, minutes: minutes, seconds: seconds)
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif value.is_a? String
      classes = []
      classes << 'code' if attribute.to_s == 'code'
      classes << value.class.name.underscore
      value = link_to(value.to_s, options[:url]) if options[:url]
      value = content_tag(:div, value.html_safe, class: classes.join(' '))
    end
    [label, value]
  end

  def attributes_list(*args, &block)
    options = args.extract_options!
    record = args.shift || resource
    columns = options[:columns] || 3
    attribute_list = AttributesList.new(record)
    unless block.arity == 1
      fail ArgumentError, 'One parameter needed for attribute_list block'
    end
    yield attribute_list if block_given?
    unless options[:without_custom_fields]
      unless attribute_list.items.detect { |item| item[0] == :custom_fields }
        attribute_list.custom_fields
      end
    end
    unless options[:without_stamp] || options[:without_stamps] || options[:stamps].is_a?(FalseClass)
      attribute_list.attribute :creator, label: :full_name
      attribute_list.attribute :created_at
      attribute_list.attribute :updater, label: :full_name
      attribute_list.attribute :updated_at
      # attribute_list.attribute :lock_version
    end
    code = ''
    items = attribute_list.items.delete_if { |x| x[0] == :custom_fields }
    if items.any?
      for item in items
        label, value = if item[0] == :custom
                         attribute_item(*item[1])
                       elsif item[0] == :attribute
                         attribute_item(record, *item[1])
                       end
        if !value.blank? || (item[2].is_a?(Hash) && item[2][:show] == :always)
          code << content_tag(:dl, content_tag(:dt, label) + content_tag(:dd, value))
        end
      end
      code = content_tag(:div, code.html_safe, class: 'attributes-list')
    end
    code.html_safe
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

    def custom_fields(*_args)
      @object.custom_fields.each do |custom_field|
        value = @object.custom_value(custom_field)
        custom(custom_field.name, value) unless value.blank?
      end
      @items << [:custom_fields]
    end
  end

  def svg(_options = {}, &block)
    content_tag(:svg, capture(&block))
  end

  def dropdown_button(*args, &_block)
    l = Ekylibre::Support::Lister.new(:links)
    yield l
    minimum = 0
    if args[0].nil?
      return nil unless l.links.any?
      minimum = 1
      args = l.links.first.args
    end

    if l.links.size > minimum
      return content_tag(:div, class: 'btn-group') do # btn-group btn-group-dropdown  #{args[2][:class]}
        html = ''.html_safe
        html << tool_to(*args)
        html << link_to(content_tag(:i), '#dropdown', class: 'btn btn-default dropdown-toggle', data: { toggle: 'dropdown' })
        html << content_tag(:ul, class: 'dropdown-menu', role: 'menu') do
          l.links.collect do |link|
            content_tag(:li, send(link.name, *link.args, &link.block))
          end.join.html_safe
        end
        html
      end
    else
      return tool_to(*args)
    end
  end

  def last_page(menu)
    # session[:last_page][menu.to_s]||
    url_for(controller: :dashboards, action: menu)
  end

  def doctype_tag
    "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN\" \"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd\">".html_safe
  end

  def search_results(search, _options = {}, &block)
    content_tag(:div, class: :search) do
      # Show results
      html = ''.html_safe
      html << content_tag(:ul, class: :results) do
        counter = 'a'
        search[:records].collect do |result|
          id = 'result-' + counter
          counter.succ!
          content_tag(:li, class: 'result', id: id) do
            (block.arity == 2 ? capture(result, id, &block) : capture(result, &block)).html_safe
          end
        end.join.html_safe
      end if search[:records]

      # Pagination
      html << content_tag(:span, class: :pagination) do
        padding = 9
        gap = 4
        page_min = params[:page].to_i - padding
        page_min = 1 if page_min < gap
        page_max = params[:page].to_i + padding
        page_max = search[:last_page] if page_max > search[:last_page]

        pagination = ''
        if page_min > 1
          pagination << link_to(content_tag(:i) + tl(:beginning), { q: params[:q], page: 1 }, class: :beginning)
          pagination << content_tag(:span, '&hellip;'.html_safe) if page_min >= gap
        end
        for p in page_min..page_max
          attrs = {}
          attrs[:class] = 'active' if p == params[:page]
          pagination << link_to("#{p}", { q: params[:q], page: p }, attrs)
        end
        pagination << content_tag(:span, '&hellip;'.html_safe) if page_max < search[:last_page]
        pagination.html_safe
      end if search[:last_page] && search[:last_page] > 1

      # Return HTML
      html
    end
  end

  def icon_tags(options = {})
    # Favicon
    html = tag(:link, rel: 'icon', type: 'image/png', href: image_path('icon/favicon.png'), 'data-turbolinks-track' => true)
    html << "\n".html_safe + tag(:link, rel: 'shortcut icon', href: image_path('icon/favicon.ico'), 'data-turbolinks-track' => true)
    # Apple touch icon
    icon_sizes = { iphone: '57x57', ipad: '72x72', 'iphone-retina' => '114x114', 'ipad-retina' => '144x144' }
    unless options[:app].is_a?(FalseClass)
      for name, sizes in icon_sizes
        html << "\n".html_safe + tag(:link, rel: 'apple-touch-icon', sizes: sizes, href: image_path("icon/#{name}.png"), 'data-turbolinks-track' => true)
      end
    end
    if options[:precomposed]
      for name, sizes in icon_sizes
        html << "\n".html_safe + tag(:link, rel: 'apple-touch-icon-precomposed', sizes: sizes, href: image_path("icon/precomposed-#{name}.png"), 'data-turbolinks-track' => true)
      end
    end
    html
  end

  # Permits to use themes for Ekylibre
  #  stylesheet_link_tag 'application', 'list', 'list-colors'
  #  stylesheet_link_tag 'print', :media => 'print'
  def theme_link_tag(theme = nil)
    theme ||= current_theme
    return nil unless theme
    html = ''
    html << stylesheet_link_tag(theme_path('all.css', theme), media: :all, 'data-turbolinks-track' => true)
    html.html_safe
  end

  def theme_button(name, theme = nil)
    image_path(theme_path("buttons/#{name}.png", theme))
  end

  def theme_path(name, theme = nil)
    theme ||= current_theme
    "themes/#{theme}/#{name}"
  end

  def viewport_tag
    tag(:meta, name: 'viewport', content: 'width=device-width, initial-scale=1.0, maximum-scale=1.0')
  end

  def main_informations(options = {}, &block)
    html = content_tag(:div, class: 'panel', id: 'main-informations') do
      partial = content_tag(:div, class: 'panel-body', &block)
      if options.include? :attachment
        partial += main_attachments
      end
      partial
    end
    html
  end

  def main_attachments
    html = content_tag(:div, class: 'attachments-panel', id: 'main-attachments') do
      content_tag(:div, class: 'attachments-body') do
        content_tag(:button, class: 'attachment-logo file-upload-btn') do
          content_tag(:i) + file_field_tag(:attachments, name: "attachments[document_attributes][file]", multiple: true, data: { url: url_for( [:attachments, :backend, resource] ), attachment: true })
        end +
      content_tag(:div, class: 'attachment-files') do
              html = content_tag(:div, :no_attachments.tl, class: 'attachment-files-placeholder')

              resource.attachments.each do |attachment|
                html += content_tag(:div, class: 'file') do
                  content_tag(:div, class: 'file-body', data: { href: url_for([:attachment, :backend, resource, attachment_id: attachment.id]), 'attachment-thumblink': true }) do
                    content_tag(:div, class: 'thumbnail', style: "background-image: url(#{backend_document_url(attachment.document, format: :jpg) })" ) do
                    end +
                    content_tag(:span, class: 'name') do
                      link_to( nil, attachment.document.name, data: { href: url_for([:attachment, :backend, resource, attachment_id: attachment.id]), 'attachment-thumblink': true } )
                    end
                  end +
                  content_tag(:div, class: 'actions') do
                    link_to(nil, '', class: 'btn removebutton', data: { href: url_for([:attachment, :backend, resource, attachment_id: attachment.id]), 'attachment-file-destroy-button': true } )
                  end
                end
              end

              html += content_tag(:div, nil, class: 'attachment-files-bitrate')
              html
            end + content_tag(:div, class: 'attachment-btns') do
          content_tag(:button, content_tag(:i), class: 'expand-btn', data: {'attachment-expand': true})
        end

      end
    end

    # Modal to display file
    modal(:file_preview, data: {'attachment-thumblink-target': true}) do
      content_tag :div, nil, class: 'modal-body'
    end

    html.html_safe
  end

  def main_title(value = nil)
    if value || block_given?
      if block_given?
        content_for(:main_title, &block)
      else
        content_for(:main_title, value)
      end
    else
      return (content_for?(:main_title) ? content_for(:main_title) : controller.human_action_name)
    end
  end

  def title_tag
    r = [] # reverse_menus
    title = if current_user
              code = request.url.split(/(\:\/\/|\.)/).third
              if r.empty?
                :page_title_special.tl(company_code: code, action: main_title)
              else
                :page_title.tl(company_code: code, action: main_title, menu: "menus.#{r[0]}".tl)
              end
            else
              :page_title_by_default.tl(action: main_title)
            end
    content_tag(:title, title)
  end

  def heading_tag
    content_tag(:h1, main_title, id: :title)
  end

  def subheading(i18n_key, options = {})
    fail StandardError.new('A subheading has already been given.') if content_for?(:subheading)
    if options[:here]
      return subheading_tag(tl(i18n_key, options))
    else
      content_for(:subheading, tl(i18n_key, options))
    end
  end

  def subheading_tag(title = nil)
    if content_for?(:subheading) || title
      return content_tag(:h2, title || content_for(:subheading), id: :subtitle)
    end
    nil
  end

  def notification_tag(mode, messages = nil)
    unless messages
      if flash[:notifications].is_a?(Hash) && flash[:notifications][mode.to_s].is_a?(Array)
        messages = flash[:notifications][mode.to_s]
      end
    end
    messages = [messages] if messages.is_a?(String)
    code = ''.html_safe
    return code unless messages
    messages.each do |message|
      code << "<div class='flash #{mode}' data-alert=\"true\"><a href=\"#\" class=\"close\">&times;</a><div class='icon'></div><div class='message'><h3>#{mode.t(scope: 'notifications.levels')}</h3><p>#{h(message).gsub(/\n/, '<br/>')}</p></div></div>".html_safe
    end
    code
  end

  def notifications_tag
    notification_tag(:error) <<
      notification_tag(:warning) <<
      notification_tag(:success) <<
      notification_tag(:information)
  end

  def table_of(array, html_options = {}, &block)
    coln = html_options.delete(:columns) || 3
    html = ''
    item = ''
    size = 0
    for item in array
      item << content_tag(:td, capture(item, &block))
      size += 1
      if size >= coln
        html << content_tag(:tr, item).html_safe
        item = ''
        size = 0
      end
    end
    html << content_tag(:tr, item).html_safe unless item.blank?
    content_tag(:table, html, html_options).html_safe
  end

  # TOOLBAR

  def menu_to(name, url, options = {})
    fail ArgumentError.new("##{__method__} cannot use blocks") if block_given?
    icon = (options.key?(:menu) ? options.delete(:menu) : url.is_a?(Hash) ? url[:action] : nil)
    sprite = options.delete(:sprite) || 'icons-16'
    options[:class] = (options[:class].blank? ? 'mn' : options[:class] + ' mn')
    options[:class] += ' ' + icon.to_s if icon
    link_to(url, options) do
      (icon ? content_tag(:span, '', class: 'icon') + content_tag(:span, name, class: 'text') : content_tag(:span, name, class: 'text'))
    end
  end

  def are_you_sure_you_want_to(action_expr, options = {})
    options[:default] ||= []
    options[:default] = [options[:default]] unless options[:default].is_a?(Array)
    options[:default] << "are_you_sure_you_want_to_#{action_expr}".tl(options)
    "are_you_sure_you_want_to.#{action_expr}".tl(options)
  end

  # def tool(code = nil, &block)
  #   raise ArgumentError.new("Arguments XOR block code are accepted, but not together.") if (code and block_given?) or (code.blank? and !block_given?)
  #   code = capture(&block) if block_given?
  #   content_for(:main_toolbar_default, code)
  #   return true
  # end

  def tool_to(name, url, options = {})
    fail ArgumentError.new("##{__method__} cannot use blocks") if block_given?
    icon = (options.key?(:tool) ? options.delete(:tool) : url.is_a?(Hash) ? url[:action] : nil)
    options[:class] = (options[:class].blank? ? 'btn  btn-default' : options[:class].to_s + ' btn btn-default')
    options[:class] << ' btn-' + icon.to_s if icon
    if url.is_a?(Hash)
      if url.key?(:redirect)
        url.delete(:redirect) if url[:redirect].nil?
      else
        url[:redirect] = request.fullpath
      end
    end
    link_to(url, options) do
      # (icon ? content_tag(:span, '', :class => "icon")+content_tag(:span, name, :class => "text") : content_tag(:span, name, :class => "text"))
      (icon ? content_tag(:i) + h(' ') + h(name) : h(name))
    end
  end

  def toolbar_tool_to(name, url, options = {})
    return tool_to(name, url, options) if authorized?(url)
    nil
  end

  def toolbar_export(nature, _record = nil, _options = {}, &_block)
    exporter = Ekylibre::Support::Lister.new(:natures)
    yield exporter if block_given?
    if exporter.natures.any? && DocumentTemplate.of_nature(exporter.natures.map(&:name)).any?

      for nature in exporter.natures
        key = nature.args.shift
        unless key.is_a?(String)
          fail ArgumentError.new("Expected String for document key: #{key.class.name}:#{key.inspect}")
        end

        content_for(:popover, render('backend/shared/export', nature: nature, key: key))
      end

      default = exporter.natures.first
      return dropdown_button(content_tag(:i) + ' ' + :print.tl, "##{default.name}-printing", class: 'btn btn-print', data: { toggle: 'modal' }) do |l|
        exporter.natures.each do |nature|
          l.link_to(content_tag(:i) + ' ' + h(Nomen::DocumentNature.find(nature.name).human_name), "##{nature.name}-printing", data: { toggle: 'modal' })
        end if exporter.natures.size > 1
      end
    end
    nil
  end

  def toolbar_mail_to(*args)
    args[2] ||= {}
    email_address = ERB::Util.html_escape(args[0])
    extras = %w(cc bcc body subject).map do |item|
      option = args[2].delete(item) || next
      "#{item}=#{Rack::Utils.escape(option).gsub('+', '%20')}"
    end.compact
    extras = extras.empty? ? '' : '?' + ERB::Util.html_escape(extras.join('&'))
    tool_to(args[1], "mailto:#{email_address}#{extras}".html_safe, tool: :mail)
  end

  def toolbar_missing(action, *args)
    options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    record = args.shift
    url = {}
    url.update(options.delete(:params)) if options[:params].is_a? Hash
    url[:controller] ||= controller_path
    url[:action] ||= action
    url[:id] = record.id if record && record.class < ActiveRecord::Base
    variants = options.delete(:variants)
    action_label = options[:label] || action.to_s.t(scope: 'rest.actions')
    variants ||= { action_label => url } if authorized?(url)
    dropdown_button do |l|
      for name, url_options in variants || {}
        variant_url = url.merge(url_options)
        l.link_to(name, variant_url, options) if authorized?(variant_url)
      end
    end
  end

  def toolbar_tag(name)
    toolbar = "#{name}_toolbar".to_sym
    if content_for?(toolbar)
      return content_tag(:div, content_for(toolbar), class: "#{name.to_s.parameterize}-toolbar toolbar")
    end
  end

  # Build the heading toolbar
  def heading_toolbar_tag
    toolbar_tag(:heading)
  end

  # Build the meta toolbar
  def meta_toolbar_tag
    toolbar_tag(:meta)
  end

  # Build the view toolbar
  def view_toolbar_tag
    toolbar_tag(:view)
  end

  # Build the main toolbar
  def main_toolbar_tag
    toolbar_tag(:main)
  end

  # Create the main toolbar with the same API as toolbar
  def main_toolbar(options = {}, &block)
    content_for(:main_toolbar, toolbar(options.merge(wrap: false), &block))
    nil
  end

  # Build a tool bar composed of tool groups composed of tool
  def toolbar(options = {}, &_block)
    html = '[EmptyToolbarError]'
    toolbar = Toolbar.new
    yield toolbar if block_given?

    # To HTML
    html = ''.html_safe
    for group, tools in toolbar.tools
      tools_html = tools.collect { |t| (t[:block] ? send("toolbar_#{t[:type]}", *t[:args], &t[:block]) : send("toolbar_#{t[:type]}", *t[:args])) }.compact.join.html_safe
      unless tools_html.blank?
        html << content_tag(:div, tools_html.html_safe, class: "btn-group btn-group-#{group}")
      end
    end

    unless options[:wrap].is_a?(FalseClass)
      html = content_tag(:div, html, class: 'toolbar' << (options[:class] ? ' ' << options[:class].to_s : ''))
    end
    html
  end

  # This class permit to register the composition of a toolbar
  class Toolbar
    attr_reader :tools

    def initialize
      @tools = {}
      @group = '0'
    end

    # def link(*args)
    #   add(:link, *args)
    # end

    def tool_to(*args)
      add(:tool_to, *args)
    end

    def mail_to(*args)
      add(:mail_to, *args)
    end

    def export(*args, &block)
      args << {} unless args[-1].is_a?(Hash)
      args[-1][:group] ||= new_group
      @export = true
      add(:export, *args, &block)
    end

    def method_missing(method_name, *args, &_block)
      fail ArgumentError.new('Block can not be accepted') if block_given?
      args << {} unless args.last.is_a?(Hash)
      args.last[:group] ||= new_group if args.last[:variants]
      add(:missing, method_name.to_s.gsub(/\_+$/, '').to_sym, *args)
    end

    private

    def add(type, *args, &block)
      options = args[-1].is_a?(Hash) ? args[-1] : {}
      group = (options.delete(:group) || 'default').to_sym
      button = { type: type, args: args }
      button[:block] = block if block_given?
      @tools[group] ||= []
      @tools[group] << button
    end

    # Build an return a new group name
    def new_group
      @group.succ!
      "g#{@group}".to_sym
    end
  end

  def error_messages(object)
    object = instance_variable_get("@#{object}") unless object.respond_to?(:errors)
    return unless object.respond_to?(:errors)
    unless (count = object.errors.size).zero?
      I18n.with_options scope: [:errors, :template] do |locale|
        header_message = locale.t :header, count: count, model: object.class.model_name.human
        introduction = locale.t(:body)
        messages = object.errors.full_messages.map do |msg|
          content_tag(:li, msg)
        end.join.html_safe
        message = ''
        message << content_tag(:h3, header_message) unless header_message.blank?
        message << content_tag(:p, introduction) unless introduction.blank?
        message << content_tag(:ul, messages)

        html = ''
        html << content_tag(:div, '', class: :icon)
        html << content_tag(:div, message.html_safe, class: :message)
        html << content_tag(:div, '', class: :end)
        return content_tag(:div, html.html_safe, class: 'flash error')
      end
    else
      ''
    end
  end

  def form_actions(&block)
    content_tag(:div, capture(&block), class: 'form-actions')
  end

  def form_fields(&block)
    content_tag(:div, capture(&block), class: 'form-fields')
  end

  def backend_form_for(object, *args, &block)
    options = args.extract_options!
    simple_form_for([:backend, object], *(args << options.merge(builder: Backend::FormBuilder)), &block)
  end

  def backend_fields_for(object, *args, &block)
    options = args.extract_options!
    simple_fields_for(object, *(args << options.merge(builder: Backend::FormBuilder)), &block)
  end

  # Wraps a label and its input in a standard wrapper
  def field(label, input, _options = {}, &block)
    content_tag(:div,
                content_tag(:label, label, class: 'control-label') +
                content_tag(:div, (block_given? ? capture(&block) : input.is_a?(Hash) ? field_tag(input) : input), class: 'controls'),
                class: 'control-group')
  end

  def field_set(*args, &block)
    options = args.extract_options!
    options[:fields_class] ||= 'fieldset-fields'
    name = args.shift || 'general-informations'.to_sym
    buttons = [options[:buttons] || []].flatten
    buttons << link_to('', '#', :class => 'toggle', 'data-toggle' => 'fields')
    class_names = 'fieldset ' + name.to_s + (options[:class] ? ' ' + options[:class].to_s : '')
    class_names << (options[:collapsed] ? ' collapsed' : ' not-collapsed')
    name_sym = name.to_s.tr('-', '_').to_sym
    wrap(content_tag(:div,
                     content_tag(:div,
                                 link_to(content_tag(:i) + h(name.is_a?(Symbol) ? name_sym.tl(default: ["form.legends.#{name_sym}".to_sym, "attributes.#{name_sym}".to_sym, name_sym.to_s.humanize]) : name.to_s), '#', :class => 'title', 'data-toggle' => 'fields') +
                                 content_tag(:span, buttons.join.html_safe, class: :buttons),
                                 class: 'fieldset-legend') +
                     content_tag(:div, capture(&block), class: options[:fields_class]), class: class_names, id: name), options[:in])

    # "#{name}-fieldset"
  end

  def wrap(html, *levels)
    if levels.any?
      level = levels.shift
      return wrap(content_tag(:div, html, class: level), *levels)
    end
    html
  end

  def product_stocks_options(product)
    options = []
    options += product.stocks.collect { |x| [x.label, x.id] }
    options += Building.of_product(product).collect { |x| [x.name, -x.id] }
    options
  end

  def condition_label(condition)
    if condition.match(/^generic/)
      klass = condition.split(/\-/)[1].pluralize.classify.constantize
      attribute = condition.split(/\-/)[2]
      return tl('conditions.filter_on_attribute_of_class', attribute: klass.human_attribute_name(attribute), class: klass.model_name.human)
    else
      return tl("conditions.#{condition}")
    end
  end

  # Define a simple frame for modals
  def modal(*args, &block)
    options = args.extract_options!
    options[:aria] ||= {}
    options[:aria][:hidden] ||= 'true'
    options[:aria][:labelledby] ||= options.delete(:labelledby) if options[:labelledby]
    if options[:class].is_a? Array
      options[:class] << 'modal'
      options[:class] << 'fade'
    elsif options[:class].nil?
      options[:class] = 'modal fade'
    else
      options[:class] = options[:class].to_s + ' modal fade'
    end
    if id = args.shift and !options[:id]
      if id.is_a?(Symbol)
        options[:id] = id.to_s.dasherize
        options[:title] ||= id.tl
      else
        options[:id] = id
      end
    end
    title = options.delete(:title) || options.delete(:heading)
    options[:aria][:labelledby] ||= options[:id].underscore.camelcase(:lower)
    options[:tabindex] ||= '-1'
    options[:role] ||= 'dialog'
    header_options = options.slice(:close_button, :close_html).merge(title_id: options[:aria][:labelledby])
    content_for(:popover) do
      content_tag(:div, options) do
        content_tag(:div, class: 'modal-dialog') do
          content_tag(:div, class: 'modal-content') do
            if title
              modal_header(title, header_options) + capture(&block)
            else
              capture(&block)
            end
          end
        end
      end
    end
  end

  def modal_header(title, options = {})
    title_id = options[:title_id] || title.parameterize.underscore.camelcase(:lower)
    content_tag(:div, class: 'modal-header') do
      if options[:close_button].is_a? FalseClass
        content_tag(:h4, title, class: 'modal-title', id: title_id)
      else
        button_tag({ class: 'close', aria: { label: :close.tl }, data: { dismiss: 'modal' }, type: 'button' }.deep_merge(options[:close_html] || {})) do
          content_tag(:span, '&times;'.html_safe, aria: { hidden: 'true' })
        end + content_tag(:h4, title, class: 'modal-title', id: title_id)
      end
    end
  end

  def relative_distance_in_words(time)
    now = Time.zone.now
    if time > now
      'datetime.relative_distance_in_words.in_sometime'.t(distance: time_ago_in_words(time))
    else
      'datetime.relative_distance_in_words.sometime_ago'.t(distance: time_ago_in_words(time))
    end
  end
end
