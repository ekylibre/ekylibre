# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 Brice Texier
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

module Backend
  module BaseHelper
    def resource
      instance_variable_get('@' + controller_name.singularize)
    end

    def resource_model
      controller_name.classify.constantize
    end

    def collection
      instance_variable_get('@' + controller_name)
    end

    def historic_of(record = nil)
      record ||= resource
      render(partial: 'backend/shared/historic', locals: { resource: resource })
    end

    def root_models
      Ekylibre::Schema.models.collect { |a| [Ekylibre::Record.human_name(a.to_s.singularize), a.to_s.singularize] }.sort_by { |a| a[0].ascii }
    end

    def extensions_tag(place)
      Ekylibre::View::Addon.render("extensions_#{place}", self)
    end

    def navigation_tag
      render(partial: 'layouts/navigation')
    end

    # It's the menu generated for the current user
    # Therefore: No current user => No menu
    def menus
      Ekylibre.menu
    end

    # Sort list of array (with label and id) with accent
    def accented_sort(list)
      list.sort_by { |e, _i| I18n.transliterate e }
    end

    # BasicCalendar permits to fix some SimpleCalendar issues with param name
    # and partial.
    class BasicCalendar < SimpleCalendar::MonthCalendar
      # Overwrite default partial name
      def partial_name
        @options[:partial] || 'backend/shared/month_calendar'
      end

      def date_param_name
        @options[:param_name] ||= :start_date
      end

      def params
        @options[:params] ||= {}
      end

      def start_date
        view_context.params.fetch(date_param_name, Date.today).to_date
      end
    end

    # Emulate old simple_calendar API
    def basic_calendar(all_records, options = {}, &block)
      # options[:events] = all_records
      options[:param_name] ||= :started_on
      BasicCalendar.new(self, options).render do |event_on, _records|
        records = all_records.select do |event|
          event_on == event.started_at.to_date
        end
        content_tag(:div) do
          content_tag(:span, event_on.day, class: 'day-number') +
            records.collect do |event|
              capture(event, &block)
            end.join.html_safe
        end
      end
    end

    def part_authorized?(part)
      part.children.each do |group|
        group.children.each do |item|
          return true if authorized?(item.default_page.to_hash)
        end
      end
      false
    end

    def side_tag
      render(partial: 'layouts/side')
    end

    def add_snippets(place, _options = {})
      Ekylibre::Snippet.at(place).each do |s|
        snippet(s.name, { icon: :plug }.merge(s.options)) do
          render(file: s.path)
        end
      end
    end

    def side_menu(*args, &_block)
      return '' unless block_given?
      main_options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
      menu = Menu.new
      yield menu

      main_name = args[0].to_s.to_sym
      main_options[:icon] ||= main_name.to_s.parameterize.tr('_', '-')

      html = ''.html_safe
      for name, url, options in menu.items
        li_options = {}
        li_options[:class] = 'active' if options.delete(:active)

        kontroller = (url.is_a?(Hash) ? url[:controller] : nil) || controller_name
        options[:title] ||= ::I18n.t("actions.#{kontroller}.#{name}".to_sym, { default: ["labels.#{name}".to_sym] }.merge(options.delete(:i18n) || {}))
        if icon = options.delete(:icon)
          item[:title] = content_tag(:i, '', class: 'icon-' + icon.to_s) + ' '.html_safe + h(item[:title])
        end
        url[:action] ||= name if name != :back && url.is_a?(Hash)
        html << content_tag(:li, link_to(options[:title], url, options), li_options) if authorized?(url)
      end

      if html.present?
        html = content_tag(:ul, html)
        snippet(main_name, main_options) { html }
      end

      nil
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

    def snippet(name, options = {}, &block)
      collapsed = current_user.preference("interface.snippets.#{name}.collapsed", false, :boolean).value
      collapsed = false if collapsed && options[:title].is_a?(FalseClass)

      options[:class] ||= ''
      options[:icon] ||= name
      options[:class] << " snippet-#{options[:icon]}"
      options[:class] << ' active' if options[:active]

      html = ''
      html << "<div id='#{name}' class='snippet#{' ' + options[:class].to_s if options[:class]}#{' collapsed' if collapsed}'>"

      unless options[:title].is_a?(FalseClass)
        html << "<a href='#{url_for(controller: '/backend/snippets', action: :toggle, id: name)}' class='snippet-title' data-toggle-snippet='true'>"
        html << "<i class='collapser'></i>"
        html << '<h3><i></i>' + (options[:title] || "snippets.#{name}".t(default: ["labels.#{name}".to_sym])) + '</h3>'
        html << '</a>'
      end

      html << "<div class='snippet-content'" + (collapsed ? ' style="display: none"' : '') + '>'
      begin
        html << capture(&block)
      rescue Exception => e
        html << content_tag(:small, "#{e.class.name}: #{e.message}")
      end
      html << '</div>'

      html << '</div>'
      content_for(:aside, html.html_safe)
      nil
    end

    # chart for variables readings
    def variable_readings(resource)
      indicators = resource.variable_indicators.delete_if { |i| !%i[measure decimal].include?(i.datatype) }
      series = []
      now = (Time.zone.now + 7.days)
      window = 1.day
      min = (resource.born_at ? resource.born_at : now - window)
      min = now - window if (now - min) < window
      indicators.each do |indicator| # [:population, :nitrogen_concentration].collect{|i| Nomen::Indicator[i] }
        items = ProductReading.where(indicator_name: indicator.name, product: resource).where('? < read_at AND read_at < ?', min, now).order(:read_at)
        next unless items.any?
        data = []
        data << [min.to_usec, resource.get(indicator, at: min).to_d.to_s.to_f]
        data += items.each_with_object({}) do |pair, hash|
          hash[pair.read_at.to_usec] = pair.value.to_d
          hash
        end.collect { |k, v| [k, v.to_s.to_f] }
        data << [now.to_usec, resource.get(indicator, at: now).to_d.to_s.to_f]
        series << { name: indicator.human_name, data: data, step: 'left' }
      end
      return no_data if series.empty?

      line_highcharts(series, legend: {}, y_axis: { title: { text: :indicator.tl } }, x_axis: { type: 'datetime', title: { enabled: true, text: :months.tl }, min: min.to_usec })
    end

    # chart for product movements
    def movements_chart(resource)
      populations = resource.populations.reorder(:started_at)
      series = []
      now = (Time.zone.now + 7.days)
      window = 1.day
      min = (resource.born_at ? resource.born_at : now - window) - 7.days
      min = now - window if (now - min) < window
      if populations.any?
        data = []
        data += populations.each_with_object({}) do |pair, hash|
          time_pos = pair.started_at < min ? min : pair.started_at
          hash[time_pos.to_usec] = pair.value.to_d
          hash
        end.collect { |k, v| [k, v.to_s.to_f] }
        # current population
        data << [now.to_usec, resource.population.to_d.to_s.to_f]
        series << { name: resource.name, data: data.sort_by(&:first), step: 'left' }
      end
      return no_data if series.empty?
      line_highcharts(series, legend: {}, y_axis: { title: { text: :indicator.tl } }, x_axis: { type: 'datetime', title: { enabled: true, text: :months.tl }, min: min.to_usec })
    end

    def main_campaign_selector
      content_for(:heading_toolbar) do
        campaign_selector
      end
    end

    def campaign_selector(campaign = nil, options = {})
      unless Campaign.any?
        @current_campaign = Campaign.find_or_create_by!(harvest_year: Date.current.year)
        current_user.current_campaign = @current_campaign
      end
      campaign ||= current_campaign
      render 'backend/shared/campaign_selector', campaign: campaign, param_name: options[:param_name] || :current_campaign
    end

    def main_period_selector(*intervals)
      content_for(:heading_toolbar) do
        period_selector(*intervals)
      end
    end

    def heading_toolbar(&block)
      content_for(:heading_toolbar, &block)
    end

    def form_action_content(side = :after, &block)
      content_for(:"#{side}_form_actions", &block)
    end

    def period_selector(*intervals)
      options = intervals.extract_options!
      current_period = current_user.current_period.to_date
      current_interval = current_user.current_period_interval.to_sym
      current_user.current_campaign = Campaign.find_or_create_by!(harvest_year: current_period.year)

      default_intervals = %i[day week month year]
      intervals = default_intervals if intervals.empty?
      intervals &= default_intervals
      current_interval = intervals.last unless intervals.include?(current_interval)

      render 'backend/shared/period_selector', current_period: current_period, intervals: intervals, period_interval: current_interval
    end

    def main_financial_year_selector(financial_year)
      content_for(:heading_toolbar) do
        financial_year_selector(financial_year)
      end
    end

    def financial_year_selector(financial_year_id = nil, options = {})
      unless FinancialYear.any?
        @current_financial_year = FinancialYear.on(Date.current)
      end
      current_user.current_financial_year = @current_financial_year || FinancialYear.find_by(id: financial_year_id)
      render 'backend/shared/financial_year_selector', financial_year: current_user.current_financial_year, param_name: options[:param_name] || :current_financial_year
    end

    def financial_year_started_on_stopped_on
      fy = FinancialYear.current
      { data: { started_on: fy.started_on, stopped_on: fy.stopped_on } }
    end

    def lights(status, html_options = {})
      if html_options.key?(:class)
        html_options[:class] << " lights lights-#{status}"
      else
        html_options[:class] = "lights lights-#{status}"
      end
      content_tag(:span, html_options) do
        content_tag(:span, nil, class: 'go') +
          content_tag(:span, nil, class: 'caution') +
          content_tag(:span, nil, class: 'stop')
      end
    end

    def state_bar(resource, options = {})
      machine = resource.class.state_machine
      state = resource.state
      state = machine.state(state.to_sym) unless state.is_a?(StateMachine::State) || state.nil?
      render 'state_bar', states: machine.states, current_state: state, resource: resource, renamings: options[:renamings]
    end

    def main_state_bar(resource, options = {})
      content_for(:main_statebar, state_bar(resource, options))
    end

    def main_state_bar_tag
      content_for(:main_statebar) if content_for?(:main_statebar)
    end

    def main_list(*args)
      options = args.extract_options!
      list *args, options.deep_merge(content_for: { settings: :meta_toolbar, pagination: :meta_toolbar, actions: :main_toolbar })
    end

    def janus(*args, &_block)
      options = args.extract_options!
      name = args.shift || ("#{controller_path}-#{action_name}-" + caller.first.split(/\:/).second).parameterize

      lister = Ekylibre::Support::Lister.new(:face)
      yield lister
      faces = lister.faces

      return '' unless faces.any?

      faces_names = faces.map { |f| f.args.first.to_s }

      active_face = nil
      if pref = current_user.preferences.find_by(name: "interface.janus.#{name}.current_face")
        face = pref.value.to_s
        active_face = face if faces_names.include? face
      end
      active_face ||= faces_names.first

      load_all_faces = false # For performance

      # Adds views
      html_code = faces.map do |face|
        face_name = face.args.first.to_s
        classes = ['face']
        classes << 'active' if active_face == face_name
        unless load_all_faces || active_face == face_name # load_all_faces toggle a few lines above
          next content_tag(:div, nil, id: "face-#{face_name}", data: { face: face_name }, class: classes)
        end
        content_tag(:div, id: "face-#{face_name}", data: { face: face_name }, class: classes, &face.block)
      end.join.html_safe

      # Adds toggle buttons
      if faces.count > 1
        content_for :view_toolbar do
          content_tag(:div, data: { janus: url_for(controller: '/backend/januses', action: :toggle, id: name, default: faces_names.first) }, class: 'btn-group') do
            faces.collect do |face|
              face_name = face.args.first.to_s
              classes = ['btn', 'btn-default']
              classes << 'active' if face_name == active_face
              get_url = url_for(controller: '/backend/januses', action: :toggle, default: faces_names.first, id: name, face: face_name, redirect: request.fullpath)
              link_to(get_url, data: { janus_href: face_name, toggle: 'face' }, class: classes, title: face_name.tl) do
                content_tag(:i, '', class: "icon icon-#{face_name}") + ' '.html_safe + face_name.tl
              end
            end.join.html_safe
          end
        end
      end
      html_code
    end

    def resource_info(name, options = {}, &block)
      value = options[:value] || resource.send(name)
      return nil if value.blank? && !options[:force]
      nomenclature = options.delete(:nomenclature)
      if nomenclature.is_a?(TrueClass)
        value = Nomen.find(name.to_s.pluralize, value)
      elsif nomenclature.is_a?(Symbol)
        value = Nomen.find(nomenclature, value)
      end
      label = options.delete(:label) || resource_model.human_attribute_name(name)
      if block_given?
        info(label, capture(value, &block), options)
      else
        info(label, value.respond_to?(:l) ? value.l : value, options)
      end
    end

    def labels_info(labels)
      if labels.any?
        content_tag(:div, class: 'info-labels') do
          labels.map do |label|
            content_tag(:div, label.name, class: 'label', style: "background-color: #{label.color}; color: #{contrasted_color(label.color)}") + ' '.html_safe
          end.join.html_safe
        end
      end
    end

    def info(label, value, options = {}, &_block)
      css_class = "#{options.delete(:level) || :med}-info"
      options[:class] = if options[:class]
                          options[:class].to_s + ' ' + css_class
                        else
                          css_class
                        end
      options[:class] << ' important' if options.delete(:important)
      content_tag(:div, options) do
        content_tag(:span, label, class: 'title') +
          content_tag(:span, value, class: 'value')
      end
    end

    def infos(options = {}, &block)
      css_class = 'big-infos'
      if options[:class]
        options[:class] += ' ' + css_class
      else
        options[:class] = css_class
      end
      content_tag(:div, options, &block)
    end

    def chronology_period(margin, width, background_color, url_options = {}, html_options = {})
      direction = reading_ltr? ? 'left' : 'right'
      period_margin = 100 * margin.round(6)
      period_width = 100 * width.round(6)

      style = "#{direction}: #{period_margin}%;"
      style += "width: #{period_width}%;"
      style += "background-color: #{background_color}"

      element_class = html_options[:class] || ''
      title = html_options[:title] || ''
      nested_element = html_options[:nested_element] || nil

      if nested_element.nil?
        link_to('', url_options, style: style, class: "period #{element_class}", title: title)
      else
        link_to(url_options, style: style, class: "period #{element_class}", title: title) do
          nested_element
        end
      end
    end

    def chronology_period_icon(positioned_at, picto_class, html_options = {})
      style = ''

      if positioned_at != 'initial'

        direction = reading_ltr? ? 'left' : 'right'
        period_icon_margin = 100 * positioned_at.round(6)
        style = "#{direction}: #{period_icon_margin}%;"
      end

      element_class = html_options[:class] || 'period'
      title = html_options[:title] || ''
      url = html_options[:url] || nil

      content_tag(:div, style: style, class: element_class, title: title) do
        if url.nil?
          content_tag(:i, '', class: "picto picto-#{picto_class}")
        else

          link_to(url) do
            content_tag(:i, '', class: "picto picto-#{picto_class}")
          end
        end
      end
    end

    def user_preference_value(name, default = nil)
      preference = current_user.preferences.find_by(name: name)
      preference ? preference.value : default
    end

    # Build a JSON for a data-tour parameter and put it on <body> element
    def tour(name, _options = {})
      preference = current_user.preference("interface.tours.#{name}.finished", false, :boolean)
      return if preference.value
      object = {}
      object[:defaults] ||= {}
      object[:defaults][:classes] ||= 'shepherd-theme-arrows'
      object[:defaults][:show_cancel_link] = true unless object[:defaults].key?(:show_cancel_link)
      unless object[:defaults][:buttons]
        buttons = []
        buttons << {
          text: :next.tl,
          classes: 'btn btn-primary',
          action: 'next'
        }
        object[:defaults][:buttons] = buttons
      end
      lister = Ekylibre::Support::Lister.new(:step)
      yield lister
      return nil unless lister.any?
      steps = lister.steps.map do |step|
        id = step.args.first
        on = (step.options[:on] || 'center').to_s
        if reading_ltr?
          if on =~ /right/
            on.gsub!('right', 'left')
          else
            on.gsub!('left', 'right')
          end
        end
        attributes = {
          id: id,
          title: "tours.#{name}.#{id}.title".tl,
          text: "tours.#{name}.#{id}.content".tl,
          attachTo: {
            element: step.options[:element] || '#' + id.to_s,
            on: on.tr('_', ' ')
          }
        }
        if step == lister.steps.last
          attributes[:buttons] = [{ text: :finished.tl, classes: 'btn btn-primary', action: 'next' }]
        end
        attributes
      end
      object[:name] = name
      object[:url] = finish_backend_tour_path(id: name)
      object[:steps] = steps
      content_for(:tour, object.jsonize_keys.to_json)
    end
  end
end
