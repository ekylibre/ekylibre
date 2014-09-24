# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2013 Brice Texier
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

module BackendHelper

  def resource
    instance_variable_get('@' + self.controller_name.singularize)
  end

  def collection
    instance_variable_get('@' + self.controller_name)
  end

  def historic_of(record = nil)
    record ||= resource
    render(partial: "backend/shared/historic", locals: {resource: resource})
  end

  def root_models
    Ekylibre::Schema.table_names.collect{|a| [::I18n.t("activerecord.models.#{a.to_s.singularize}"), a.to_s.singularize]}.sort{|a,b| a[0].ascii <=> b[0].ascii}
  end

  def navigation_tag
    render(partial: "layouts/navigation")
  end

  def side_tag # (submenu = self.controller.controller_name.to_sym)
    path = reverse_menus
    return '' if path.nil?
    render(partial: 'layouts/side', locals: {path: path})
  end

  def module_authorized?(mod)
    for group, items in Ekylibre::Modules.groups_in(mod)
      for item, paths in items
        return true if authorized?(paths.first)
      end
    end
    return false
  end


  def side_menu(*args, &block)
    return "" unless block_given?
    main_options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    menu = Menu.new
    yield menu

    main_name = args[0].to_s.to_sym
    main_options[:icon] ||= main_name.to_s.parameterize.gsub(/\_/, '-')

    html = "".html_safe
    for name, url, options in menu.items
      li_options = {}
      li_options[:class] = 'active' if options.delete(:active)

      kontroller = (url.is_a?(Hash) ? url[:controller] : nil) || controller_name
      options[:title] ||= ::I18n.t("actions.#{kontroller}.#{name}".to_sym, {:default => ["labels.#{name}".to_sym]}.merge(options.delete(:i18n)||{}))
      if icon = options.delete(:icon)
        item[:title] = content_tag(:i, '', class: "icon-" + icon.to_s) + ' '.html_safe + h(item[:title])
      end
      if name != :back
        url[:action] ||= name if url.is_a?(Hash)
      end
      html << content_tag(:li, link_to(options[:title], url, options), li_options) if authorized?(url)
    end

    unless html.blank?
      html = content_tag(:ul, html)
      snippet(main_name, main_options) { html }
    end

    return nil
  end


  class Menu
    attr_reader :items

    def initialize
      @items = []
    end

    def link(name, url = {}, options = {})
      @items << [name, url, options]
    end
  end


  def snippet(name, options={}, &block)
    collapsed = current_user.preference("interface.snippets.#{name}.collapsed", false, :boolean).value
    collapsed = false if collapsed and options[:title].is_a?(FalseClass)

    options[:class] ||= ""
    options[:icon] ||= name
    options[:class] << " snippet-#{options[:icon]}"
    options[:class] << " active" if options[:active]

    html = ""
    html << "<div id='#{name}' class='snippet#{' ' + options[:class].to_s if options[:class]}#{' collapsed' if collapsed}'>"

    unless options[:title].is_a?(FalseClass)
      html << "<a href='#{url_for(:controller => "/backend/snippets", :action => :toggle, :id => name)}' class='snippet-title' data-toggle-snippet='true'>"
      html << "<i class='collapser'></i>"
      html << "<h3><i></i>" + (options[:title] || tl(name)) + "</h3>"
      html << "</a>"
    end

    html << "<div class='snippet-content'" + (collapsed ? ' style="display: none"' : '') + ">"
    begin
      html << capture(&block)
    rescue Exception => e
      html << content_tag(:small, "#{e.class.name}: #{e.message}")
    end
    html << "</div>"

    html << "</div>"
    content_for(:aside, html.html_safe)
    return nil
  end


  # Kujaku 孔雀
  # Search bar
  def kujaku(*args, &block)
    options = args.extract_options!
    url_options = options[:url] || {}
    name = args.shift || caller.first.split(":in ").first
    k = Kujaku.new(name)
    if block_given?
      yield k
    else
      k.text
    end
    return "" if k.criteria.size.zero?
    id = options[:id] || ("#{controller_path}-#{action_name}-" + caller.first.split(/\:/).second).parameterize # callerTime.now.to_i.to_s(36) + (10000*rand).to_i.to_s(36)

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
          code << " ".html_safe << content_tag(:span, radio.html_safe, class: :rad)
        end

      elsif c[:type] == :radio_buttons
        code = content_tag(:label, opts[:label]||tg(:state))
        params[c[:name]] ||= c[:states][0].to_s
        i18n_root = opts[:i18n_root]||"labels.#{controller_name}_states."
        for state in c[:states]
          radio  = radio_button_tag(c[:name], state, params[c[:name]] == state.to_s)
          radio << " ".html_safe << content_tag(:label, ::I18n.translate("#{i18n_root}#{state}"), :for => "#{c[:name]}_#{state}")
          code  << " ".html_safe << content_tag(:span, radio.html_safe, class: :rad)
        end

      elsif c[:type] == :check_boxes
        code = content_tag(:label, opts[:label] || tg(:selection))
        params[c[:name]] ||= []
        i18n_root = opts[:i18n_root]||"labels.#{controller_name}_selections."
        for selection in c[:selections]
          check_box  = check_box_tag("#{c[:name]}[]", selection, params[c[:name]].include?(selection.to_s))
          check_box << " ".html_safe << content_tag(:label, ::I18n.translate("#{i18n_root}#{selection}"), :for => "#{c[:name]}_#{selection}")
          code  << " ".html_safe << content_tag(:span, check_box.html_safe, class: :chk)
        end

      elsif c[:type] == :select
        code = content_tag(:label, opts[:label] || c[:name].tl(default: "labels.options".to_sym))
        params[c[:name]] ||= c[:selection].first.second if c[:selection] and c[:selection].first
        code << " ".html_safe << content_tag(:span, select_tag(c[:name], options_for_select(c[:selection], opts[:selected] || params[c[:name]])), class: :slc)

      elsif c[:type] == :text
        code = content_tag(:label, opts[:label]||tg(:search))
        name = c[:name]||:q
        p = current_user.pref("kujaku.criteria.#{c[:uid]}.default", params[name])
        params[name] ||= p.value
        p.set!(params[name])
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

      html_options = (c[:html_options]||{}).merge(class: "crit crit-#{c[:type]}")
      if index.zero?
        html_options[:class] << " crit-main"
        code = link_to(content_tag(:i), toggle_backend_kujaku_url(id), 'data-toggle' => 'kujaku') + code.html_safe if k.criteria.size > 1
        code << button_tag(content_tag(:i) + h(tl(:filter)), 'data-disable' => true, :name => nil, class: "filter")
      else
        html_options[:class] << " crit-other"
      end
      crits << content_tag(:div, code.html_safe, html_options)
    end
    tag = content_tag(:div, crits, class: :crits)
    tag = form_tag(url_options, :method => :get) { tag } unless options[:form].is_a?(FalseClass)


    return content_tag(:div, tag.to_s.html_safe, class: "kujaku" + (current_user.preference("interface.kujakus.#{id}.collapsed", (options.has_key?(:collapsed) ? !!options[:collapsed] : true), :boolean).value ? " collapsed" : ""), :id => id)
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
    #   @criteria << {:type => :mode, :modes => modes, options: options}
    # end

    def radio(*states)
      ActiveSupport::Deprecation.warn("Use radio_buttons instead of radio.")
      return radio_buttons(*states)
    end

    def radio_buttons(*states)
      options = states.extract_options!
      name = options.delete(:name) || :s
      add_criterion :radio_buttons, name: name, :states => states, options: options
    end

    def check_boxes(*selections)
      options = selections.extract_options!
      name = options.delete(:name) || :c
      add_criterion :check_boxes, name: name, :selections => selections, options: options
    end

    def select(*args)
      options = args.extract_options!
      selection = args.last.is_a?(Array) ? args.delete_at(-1) : []
      name = args.shift || options.delete(:name) || :o
      add_criterion :select, name: name, :selection => selection, options: options
    end

    def text(name=nil, options={})
      name ||= :q
      add_criterion :text, name: name, options: options
    end

    def date(name=nil, options={})
      name ||= :d
      add_criterion :date, name: name, options: options
    end

    def crit(name=nil, *args)
      add_criterion :crit, name: name, :args => args
    end

    def criterion(html_options={}, &block)
      raise ArgumentError.new("No block given") unless block_given?
      add_criterion :criterion, :block => block, :html_options => html_options
    end

    private

    def add_criterion(type=nil, options={})
      @criteria << options.merge(:type => type, :uid => "#{@uid}:" + @criteria.size.to_s)
    end
  end


  def variable_readings(resource)
    indicators = resource.variable_indicators.delete_if{|i| ![:measure, :decimal].include?(i.datatype)}
    series = []
    now, window = (Time.now + 7.days), 1.day
    min = (resource.born_at ? resource.born_at : now - window)
    min = now - window if (now - min) < window
    for indicator in indicators # [:population, :nitrogen_concentration].collect{|i| Nomen::Indicators[i] }
      items = ProductReading.where(indicator_name: indicator.name, product: resource).where("? < read_at AND read_at < ?", min, now).order(:read_at)
      next unless items.any?
      data = []
      data << [min.to_usec, resource.get(indicator, at: min).to_d.to_s.to_f]
      data += items.inject({}) do |hash, pair|
        hash[pair.read_at.to_usec] = pair.value.to_d
        hash
      end.collect{|k,v| [k, v.to_s.to_f] }
      data << [now.to_usec, resource.get(indicator, at: now).to_d.to_s.to_f]
      series << {name: indicator.human_name, data: data, step: "left"}
    end
    return no_data if series.empty?

    return line_chart(series, legend: {}, y_axis: {title: { text: :indicator.tl}}, x_axis: {type: 'datetime', title: { enabled: true, text: :months.tl}, min: min.to_usec})
  end



  # Permits to use deck as XUL defines it
  # https://developer.mozilla.org/fr/docs/XUL/deck
  def deck(options = {}, &block)
    add_deck(:default, &block)
    options["data-deck"] = options.delete(:deck) || 'default'
    return content_tag(:div, content_for(:deck), options)
  end

  # Add a new deck
  def add_deck(id, &block)
    content_for(:deck, content_tag(:div, capture(&block), :id => id))
  end




  def lights(status, html_options = {})
    if html_options.has_key?(:class)
      html_options[:class] << " lights lights-#{status}"
    else
      html_options[:class] = "lights lights-#{status}"
    end
    return content_tag(:span, html_options) do
      content_tag(:span, nil, class: "go") +
                  content_tag(:span, nil, class: "caution") +
                              content_tag(:span, nil, class: "stop")
                                        end
                            end

                end
