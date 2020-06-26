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
      raise ArgumentError, "Unknown reflection for #{model.name}: #{association.inspect}"
    end
    if reflection.macro != :belongs_to
      raise ArgumentError, "Reflection #{reflection.name} must be a belongs_to"
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
    radio_button_tag(object_name, method, TrueClass, id: "#{object_name}_#{method}_#{checked_value}") << ' ' <<
      content_tag(:label, ::I18n.translate('general.y'), for: "#{object_name}_#{method}_#{checked_value}") << ' ' <<
      radio_button_tag(object_name, method, FalseClass, id: "#{object_name}_#{method}_#{unchecked_value}") << ' ' <<
      content_tag(:label, ::I18n.translate('general.n'), for: "#{object_name}_#{method}_#{unchecked_value}")
  end

  def number_to_accountancy(value, currency = nil, allow_blank = true)
    number = value.to_f
    (number.zero? && allow_blank ? '' : number.l(currency: currency || Preference[:currency]))
  end

  def number_to_management(value)
    number = value.to_f
    number.l
  end

  def human_age(born_at, options = {})
    options[:default] ||= '&ndash;'.html_safe
    return options[:default] if born_at.nil? || !born_at.is_a?(Time)
    at = options[:at] || Time.zone.now
    sign = ''
    if born_at > at
      sign = '-'
      at, born_at = born_at, at
    end
    vals = []
    remaining_at = born_at + 0.seconds
    %w[year month day hour minute second].each do |magnitude|
      count = 0
      while remaining_at + 1.send(magnitude) < at
        remaining_at += 1.send(magnitude)
        count += 1
      end
      if count > 0 && (!options[:display] || vals.size < options[:display])
        vals << "x_#{magnitude.pluralize}".tl(count: count)
      end
    end
    sign + vals.to_sentence
  end

  def human_interval(seconds, options = {})
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
    vals << (seconds / 1.minute).round.to_s.rjust(2, '0')
    seconds -= 1.minute * (seconds / 1.minute).floor
    # vals << seconds.round.to_s.rjust(2, "0")
    vals.join(':')
  end

  def reading_direction
    t('i18n.dir')
  end

  def reading_ltr?
    reading_direction == 'ltr'
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
    locales = ::I18n.available_locales.sort_by(&:to_s)
    # locales = ::I18n.valid_locales.sort{|a,b| a.to_s <=> b.to_s}
    locale = nil # ::I18n.locale
    if params[:locale].to_s =~ /^[a-z][a-z][a-z]$/
      locale = params[:locale].to_sym if locales.include? params[:locale].to_sym
    end
    locale ||= ::I18n.locale || ::I18n.default_locale
    options = locales.collect do |l|
      content_tag(:option, ::I18n.translate('i18n.name', locale: l), { :value => l, :dir => ::I18n.translate('i18n.dir', locale: l), :selected => false, 'data-redirect' => url_for(locale: l) }.merge(locale == l ? { selected: true } : {}))
    end.join.html_safe
    select_tag('locale', options, 'data-use-redirect' => 'true')
  end

  def link_to_remove_nested_association(name, f, options = {})
    link_to_remove_association(content_tag(:i) + h("labels.remove_#{name}".t(default: :destroy.ta)), f, options.deep_merge(data: { no_turbolink: true }, class: 'nested-remove'))
  end

  # Re-writing of link_to helper
  def link_to(*args, &block)
    if block_given?
      options = args.first || {}
      html_options = args.second
      link_to(capture(&block), options, html_options)
    else
      name = args[0]
      options = args[1] || {}
      html_options = args[2] || {}

      if options.is_a?(Hash) && !authorized?(options)
        if html_options[:remove]
          return ''
        else
          html_options[:class] = if html_options[:class].is_a?(Array)
                                   html_options[:class] + ['forbidden']
                                 else
                                   html_options[:class].to_s + ' forbidden'
                                 end
          html_options.delete('disabled')
          html_options[:disabled] = true
          return content_tag(:a, name, html_options)
        end
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

      href_attr = 'href="' + url + '"' unless href
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

  def available_languages(native_language = true)
    [:fra, :eng].map do |l|
      [native_language ? I18n.t('i18n.name', locale: l) : Nomen::Language.find(l).human_name, l]
    end.sort_by(&:second)
  end

  # Returns a selection from names list
  def nomenclature_as_options(nomenclature_name, *args)
    options = args.extract_options!
    nomenclature = Nomen[nomenclature_name]
    items = args.shift || nomenclature.all
    items.collect do |name|
      item = nomenclature.find(name)
      [item.human_name, item.name]
    end.sort_by(&:first)
  end

  # Returns a selection from names list
  def enumerize_as_options(model, attribute, *args)
    options = args.extract_options!
    enum = model.to_s.camelize.constantize.send(attribute)
    items = args.shift || enum.values
    items.collect do |name|
      [name.l, name]
    end.sort_by(&:first)
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
      default << "activerecord.attributes.#{model_name}.#{attribute.to_s[0..-7]}".to_sym if attribute.to_s =~ /_label$/
      default << "attributes.#{attribute}".to_sym
      default << "attributes.#{attribute}_id".to_sym
      label = "activerecord.attributes.#{model_name}.#{attribute}".t(default: default)
      if value.is_a? ActiveRecord::Base
        record = value
        value = record.send(options[:label] || %i[label name code number inspect].detect { |x| record.respond_to?(x) })
        options[:url] = { action: :show } if options[:url].is_a? TrueClass
        if options[:url].is_a? Hash
          options[:url][:id] ||= record.id
          # raise [model_name.pluralize, record, record.class.name.underscore.pluralize].inspect
          options[:url][:controller] ||= record.class.name.underscore.pluralize
        end
      elsif value.is_a? Nomen::Item
        value = value.human_name
      else
        options[:url] = { action: :show } if options[:url].is_a? TrueClass
        if options[:url].is_a? Hash
          options[:url][:controller] ||= object.class.name.underscore.pluralize
          options[:url][:id] ||= object.id
        end
      end
      value_class << ' code' if attribute.to_s == 'code'
    end
    title = None()
    if [TrueClass, FalseClass].include? value.class
      value = content_tag(:div, '', class: "checkbox-#{value}")
    elsif value.respond_to?(:text)
      value = value.send(:text)
      title = Some(value)
    elsif attribute.to_s =~ /(^|_)currency$/
      value = Nomen::Currency[value].human_name
      title = Some(value)
    elsif attribute.to_s =~ /^state$/ && !options[:force_string]
      value = I18n.translate("models.#{model_name}.states.#{value}")
      title = Some(value)
    elsif options[:currency] && value.is_a?(Numeric)
      value = ::I18n.localize(value, currency: (options[:currency].is_a?(TrueClass) ? object.send(:currency) : options[:currency].is_a?(Symbol) ? object.send(options[:currency]) : options[:currency]))
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif value.respond_to?(:strftime) || value.respond_to?(:l) || value.is_a?(Numeric)
      value = value.l
      title = Some(value)
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif options[:duration]
      duration = value
      duration *= 60 if options[:duration] == :minutes
      duration *= 3600 if options[:duration] == :hours
      hours = (duration / 3600).floor.to_i
      minutes = (duration / 60 - 60 * hours).floor.to_i
      seconds = (duration - 60 * minutes - 3600 * hours).round.to_i
      value = :duration_in_hours_and_minutes.tl(hours: hours, minutes: minutes, seconds: seconds)
      title = Some(value)
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif value.is_a? String
      classes = []
      classes << 'code' if attribute.to_s == 'code'
      classes << value.class.name.underscore
      title = Some(value)
      value = link_to(value.to_s, options[:url]) if options[:url]
      value = content_tag(:div, value.html_safe, class: classes.join(' '))
    end
    [label, value, title]
  end


  # @param [Boolean] text_ellipsis
  #   Default to false. If true, the text value of the attributes does not expand the container size and has an ellipsis if it overflows
  def attributes_list(*args, columns: [], text_ellipsis: false, **options, &block)
    record = args.shift || resource
    attribute_list = AttributesList.new(record)

    if block_given?
      unless block.arity == 1
        raise ArgumentError, 'One parameter needed for attribute_list block'
      end
      yield attribute_list
    end
    if resource.customizable? && !options[:custom_fields].is_a?(FalseClass) &&
      !attribute_list.items.detect { |item| item[0] == :custom_fields }
      attribute_list.custom_fields
    end
    unless options[:stamps].is_a?(FalseClass)
      attribute_list.attribute :creator, label: :full_name
      attribute_list.attribute :created_at
      attribute_list.attribute :updater, label: :full_name
      attribute_list.attribute :updated_at
      # attribute_list.attribute :lock_version
    end
    unless columns.empty?
      columns.each do |c|
        next unless record.respond_to? c
        attribute_list.attribute c
      end
    end
    code = ''
    items = attribute_list.items # .delete_if { |x| x[0] == :custom_fields }
    if items.any?
      items.each do |item|
        label, value, title = if item[0] == :custom
                                [*attribute_item(*item[1])[0..1], None()]
                              elsif item[0] == :attribute
                                attribute_item(record, *item[1])
                              end
        if value.present? || (item[2].is_a?(Hash) && item[2][:show] == :always)
          code << content_tag(:dl, content_tag(:dt, label) + content_tag(:dd, value, title: title.or_nil, class: text_ellipsis ? 'text-ellipsis' : ''))
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

    def custom_fields
      raise 'Cannot show custom fields on ' + @object.class.name unless @object.customizable?
      @object.class.custom_fields.each do |custom_field|
        value = @object.custom_value(custom_field)
        if value && custom_field.nature == :boolean
          value = true if value == '1'
          value = false if value == '0'
        end
        custom(custom_field.name, value) if value.present?
      end
      @items << [:custom_fields]
    end
  end

  def svg(_options = {}, &block)
    content_tag(:svg, capture(&block))
  end

  def button_group(options = {}, &block)
    options[:class] = options[:class].to_s + ' btn-group'
    content_tag(:div, options, &block)
  end

  def dropdown_toggle_button(name = nil, options = {})
    class_attribute = options[:main_class] ? options[:main_class] : 'btn btn-default'
    class_attribute << ' dropdown-toggle'
    class_attribute << ' ' + options[:class].to_s if options[:class].present?
    class_attribute << ' sr-only' if name.blank?
    class_attribute << ' icn btn-' + options[:icon].to_s if options[:icon]
    content_tag(:button, name, class: class_attribute,
                data: { toggle: 'dropdown', disable_with: options[:disable_with] },
                aria: { haspopup: 'true', expanded: 'false' })
  end

  def dropdown_menu(items)
    content_tag(:ul, class: 'dropdown-menu') do
      items.map do |item|
        if item.name == :item
          args = item.args
          options = args.extract_options!
          item_options = {}
          item_options[:class] = options.delete(:as) if options.key?(:as)
          item_options.merge!(options.delete(:html_options)) if options.key?(:html_options)
          content_tag(:li, link_to(*args, options, &item.block), item_options)
        elsif item.name == :separator
          content_tag(:li, '', class: 'separator')
        else
          raise 'Cannot handle that type of menu item: ' + item.name.inspect
        end
      end.join.html_safe
    end
  end

  def dropdown_menu_button(name, options = {})
    menu = Ekylibre::Support::Lister.new(:item, :separator)
    yield menu
    return nil unless menu.any?
    menu_size = menu.size
    default_item = menu.detect_and_extract! do |item|
      item.args[2].is_a?(Hash) && item.args[2][:by_default]
    end
    raise 'Need a name or a default item' unless name || default_item
    if name.is_a?(Symbol)
      options[:icon] ||= name unless options[:icon].is_a?(FalseClass)
      name = options[:label] || name.ta(default: ["labels.#{name}".to_sym])
    end
    item_options = default_item.args.third if default_item
    item_options ||= {}
    if options[:class]
      if item_options[:class]
        item_options[:class] << ' ' + options[:class].to_s
      else
        item_options[:class] = options[:class].to_s
      end
    end
    item_options[:tool] = options[:icon] if options.key?(:icon)
    html_options = { class: 'btn-group' + (options[:dropup] ? ' dropup' : '') }
    html_options[:class] << ' ' + options[:class].to_s if options[:class]
    html_options[:id] = options[:id] if options[:id]
    content_tag(:div, html_options) do
      if default_item
        html = tool_to(default_item.args.first, default_item.args.second,
                       item_options, &default_item.block)
        if menu_size > 1
          html << dropdown_toggle_button + dropdown_menu(menu.items)
        end
        html
      elsif menu.list.size == 1 && menu.first.type == :item && !options[:force_menu]
        default_item = menu.first
        tool_to(name, default_item.args.second,
                (default_item.args.third || {}).merge(item_options),
                &default_item.block)
      else
        dropdown_toggle_button(name, options.slice(:icon, :disable_with, :class, :main_class)) +
          dropdown_menu(menu.list)
      end
    end
  end

  def dropdown_button(*args)
    options = args.extract_options!
    l = Ekylibre::Support::Lister.new(:link_to)
    yield l
    minimum = 0
    if args[0].nil?
      return nil unless l.any?
      minimum = 1
      args = l.first.args
    end

    if l.size > minimum
      return content_tag(:div, class: 'btn-group') do # btn-group btn-group-dropdown  #{args[2][:class]}
        html = ''.html_safe
        html << tool_to(*args)
        html << dropdown_toggle_button
        html << content_tag(:ul, class: 'dropdown-menu', role: 'menu') do
          l.collect do |link|
            content_tag(:li, send(link.name, *link.args, &link.block))
          end.join.html_safe
        end
        html
      end
    else
      return tool_to(*args)
    end
  end

  def pop_menu(options = {})
    menu = Ekylibre::Support::Lister.new(:item, :separator)
    default_class = options[:class] || 'pop-menu'

    yield menu

    content_tag(:nav, '', class: default_class) do
      content_tag(:ul, class: 'menu', role: 'menu') do
        html = ''.html_safe
        menu.list.each do |item|
          if item.name == :item

            options = item.args.extract_options!
            html << content_tag(:li, link_to(*item.args, options[:link_url], options[:link_options]), options[:item_options])

          elsif item.name == :separator
            html << content_tag(:li, '', class: 'separator')
          end
        end

        html
      end
    end
  end

  def last_page(menu)
    # session[:last_page][menu.to_s]||
    url_for(controller: :dashboards, action: menu)
  end

  def search_results(search, _options = {}, &block)
    content_tag(:div, class: :search) do
      # Show results
      html = ''.html_safe
      if search[:records]
        html << content_tag(:ul, class: :results) do
          counter = 'a'
          search[:records].collect do |result|
            id = 'result-' + counter
            counter.succ!
            content_tag(:li, class: 'result', id: id) do
              (block.arity == 2 ? capture(result, id, &block) : capture(result, &block)).html_safe
            end
          end.join.html_safe
        end
      end

      # Pagination
      if search[:last_page] && search[:last_page] > 1
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
            pagination << link_to(p.to_s, { q: params[:q], page: p }, attrs)
          end
          pagination << content_tag(:span, '&hellip;'.html_safe) if page_max < search[:last_page]
          pagination.html_safe
        end
      end

      # Return HTML
      html
    end
  end

  def picto_tag(name, font_size: 18, color: '#333', pointer: false, data: {})
    style = "font-size: #{font_size}px; color: #{color}; line-height: unset;"
    style << "cursor: pointer" if pointer
    content_tag(:i, nil, class: "picto picto-#{name}", style: style, data: data)
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
      partial += content_tag(:div, main_attachments, class: 'panel-footer') if options[:attachment]
      partial
    end
    html
  end

  def main_attachments
    # Modal to display file
    modal(:file_preview, data: { attachment_thumblink_target: true }) do
      content_tag :div, nil, class: 'modal-body'
    end

    render(partial: 'attachments')
  end

  def main_title(value = nil)
    if value || block_given?
      if block_given?
        content_for(:main_title, &block)
      else
        content_for(:main_title, value)
      end
    else
      (content_for?(:main_title) ? content_for(:main_title) : controller.human_action_name)
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
    raise StandardError, 'A subheading has already been given.' if content_for?(:subheading)
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

  def table_of(array, html_options = {}, &block)
    coln = html_options.delete(:columns) || 3
    html = ''
    item = ''
    size = 0
    for item in array
      item << content_tag(:td, capture(item, &block))
      size += 1
      next unless size >= coln
      html << content_tag(:tr, item).html_safe
      item = ''
      size = 0
    end
    html << content_tag(:tr, item).html_safe if item.present?
    content_tag(:table, html, html_options).html_safe
  end

  # TOOLBAR

  def menu_to(name, url, options = {})
    raise ArgumentError, "##{__method__} cannot use blocks" if block_given?
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
    raise ArgumentError, "##{__method__} cannot use blocks" if block_given?
    icon = options.key?(:tool) ? options.delete(:tool) : options.key?(:icon) ? options.delete(:icon) : nil
    icon ||= url[:action] if url.is_a?(Hash) && !icon.is_a?(FalseClass)
    options[:class] = (options[:class].blank? ? 'btn btn-default' : options[:class].to_s + ' btn btn-default')
    options[:class] << ' icn btn-' + icon.to_s if icon
    if url.is_a?(Hash)
      if url.key?(:redirect)
        url.delete(:redirect) if url[:redirect].nil?
      else
        url[:redirect] = request.fullpath
      end
    end
    link_to(name, url, options)
  end

  def toolbar_tag(name, wrap: true)
    toolbar = "#{name}_toolbar".to_sym
    return unless content_for?(toolbar)

    if wrap.is_a? TrueClass
      content_tag(:div, content_for(toolbar), class: "#{name.to_s.parameterize}-toolbar toolbar toolbar-wrapper")
    else
      html = content_for(toolbar)
      noko = Nokogiri::HTML.fragment(html)
      wrapper = noko.children.select { |e| e.matches?(".toolbar-wrapper") }.first
      return toolbar_tag(name, wrap: true) if wrapper.nil? # If no wrapper element and wrap is false, thats an error, just wrap everything
      other_content = noko.children.select { |e| e.matches?(":not(.toolbar-wrapper)") }
      other_content.each { |node| wrapper.add_child node } if wrapper
      noko.to_html.html_safe
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
    toolbar_tag(:main, wrap: false)
  end

  # Create the main toolbar with the same API as toolbar
  def main_toolbar(**options, &block)
    content_for(:main_toolbar, toolbar({class: 'main-toolbar', **options}, &block))
    nil
  end

  def error_messages(object)
    object = instance_variable_get("@#{object}") unless object.respond_to?(:errors)
    return unless object.respond_to?(:errors)
    if (count = object.errors.size).zero?
      ''
    else
      I18n.with_options scope: %i[errors template] do |locale|
        header_message = locale.t :header, count: count, model: object.class.model_name.human
        introduction = locale.t(:body)
        messages = object.errors.full_messages.map do |msg|
          content_tag(:li, msg)
        end.join.html_safe
        message = ''
        message << content_tag(:h3, header_message) if header_message.present?
        message << content_tag(:p, introduction) if introduction.present?
        message << content_tag(:ul, messages)

        html = ''
        html << content_tag(:div, '', class: :icon)
        html << content_tag(:div, message.html_safe, class: :message)
        html << content_tag(:div, '', class: :end)
        return content_tag(:div, html.html_safe, class: 'flash error')
      end
    end
  end

  def form_actions(options = {}, &block)
    content_tag(:div, class: "form-actions #{options[:class]}") do
      html = ''.html_safe
      html << content_for(:before_form_actions) if content_for?(:before_form_actions)
      html << capture(&block)
      html << content_for(:after_form_actions) if content_for?(:after_form_actions)
      html
    end
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

  def ekylibre_form_for(object, *args, &block)
    options = args.extract_options!

    if options[:namespace] == :none
      return simple_form_for(object, *(args << options.merge(builder: Backend::FormBuilder)), &block)
    end

    namespace = options[:namespace]
    namespace ||= :backend

    simple_form_for([namespace, object], *(args << options.merge(builder: Backend::FormBuilder)), &block)
  end

  # Wraps a label and its input in a standard wrapper
  def field(label, input = nil, options = {}, &block)
    ActiveSupport::Deprecation.warn('field helper is deprecated, its time to switch to form objects!')

    options[:label] ||= {}
    options[:controls] ||= {}

    if block_given?
      content = capture &block
    elsif input.is_a? Hash
      content = field_tag input
    else
      content = input
    end

    content_tag(:div,
                content_tag(:label, label, class: "control-label #{options[:label].fetch(:class, '')}") +
                  content_tag(:div, content, class: "controls #{options[:controls].fetch(:class, '')}"),
                class: 'control-group')
  end

  def field_set(*args, &block)
    options = args.extract_options!
    options[:fields_class] ||= 'fieldset-fields'
    name = args.shift || 'general-informations'.to_sym
    buttons = [options[:buttons] || []].flatten
    buttons << link_to('', '#', :class => 'toggle', 'data-toggle' => 'fields')
    classes = ['fieldset', name.to_s, options.fetch(:class, [])].flatten
    classes << (options[:collapsed] ? ' collapsed' : ' not-collapsed')
    name_sym = name.to_s.tr('-', '_').to_sym
    wrap(content_tag(:div,
                     content_tag(:div,
                                 link_to(content_tag(:i) + h(name.is_a?(Symbol) ? name_sym.tl(default: ["form.legends.#{name_sym}".to_sym, "attributes.#{name_sym}".to_sym, name_sym.to_s.humanize]) : name.to_s), '#', :class => 'title', 'data-toggle' => 'fields') +
                                   content_tag(:span, buttons.join.html_safe, class: :buttons),
                                 class: 'fieldset-legend') +
                     content_tag(:div, capture(&block), class: options[:fields_class]), class: classes, id: name), options[:in])
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
    if condition =~ /^generic/
      klass = condition.split(/\-/)[1].pluralize.classify.constantize
      attribute = condition.split(/\-/)[2]
      tl('conditions.filter_on_attribute_of_class', attribute: klass.human_attribute_name(attribute), class: klass.model_name.human)
    else
      tl("conditions.#{condition}")
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
    if (id = args.shift) && !options[:id]
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
        content_tag(:div, class: 'modal-dialog' + (options[:size] == :large ? ' modal-lg' : options[:size] == :small ? ' modal-sm' : '')) do
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

        title = content_tag(:h4, title, class: 'modal-title', id: title_id)

        close_button = button_tag({ class: 'close', aria: { label: :close.tl }, data: { dismiss: 'modal' }, type: 'button' }.deep_merge(options[:close_html] || {})) do
          content_tag(:span, '&times;'.html_safe, aria: { hidden: 'true' })
        end

        if options[:flex]
          title + close_button
        else
          close_button + title
        end
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

  def even_cells(*cells, **options)
    options = default_evening_options(options)
    filler = content_tag(
      options[:filler_tag],
      options[:filler_content],
      class: options[:filler_class]
    )
    size = cells.size
    # Number of depth levels we're going to need
    # log2(number of elements)
    # +1 here for proper handling of odds
    n = Math.log(size + 1, 2).round

    unbalanced = cells.count(nil).odd? && size.even?

    # You can't balance a odd number of elements inside an odd numbered grid
    cells.delete_at(cells.find_index(nil)) if unbalanced

    empties = cells.count(nil)
    filled = size - empties
    return safe_join(cells.map { |_| filler }) if filled.zero?
    return safe_join(cells.map { |cell| content_tag(options[:cell_tag], cell, class: options[:cell_class]) }) if empties.zero?

    result = []
    # We strive to put everything in the middle
    # `filled <= (n - 1) * 2 - 1` tells us if there's
    # enough roomin the inner levels to handle the elements
    # or if we should take some of the burden.
    if filled <= (n - 1) * 2 - 1
      result << filler
      result << even_cells(*(cells.compact + [nil] * (empties - 2)), **options)
      result << filler
    else
      result << content_tag(
        options[:cell_tag],
        cells.compact.first,
        class: options[:cell_class]
      )
      result << even_cells(*(cells.compact[1...-1] + [nil] * empties), **options)
      result << content_tag(
        options[:cell_tag],
        cells.compact.last,
        class: options[:cell_class]
      )
    end
    # Continuation of the `odd in even` problem mentioned above.
    result << filler if unbalanced

    safe_join(result)
  end

  def no_turbolink?
    if content_for(:no_turbolink)
      { data: { no_turbolink: true } }
    else
      { data: nil }
    end
  end

  private

    def default_evening_options(options)
      defaults = {}
      defaults[:filler_tag] = options[:filler_tag] || :div
      defaults[:filler_class] = options[:filler_class] || :"even-filler"
      defaults[:filler_content] = options[:filler_content] || nil

      defaults[:cell_tag] = options[:cell_tag] || :div
      defaults[:cell_class] = options[:cell_class] || :"even-cell"
      defaults
    end
end
