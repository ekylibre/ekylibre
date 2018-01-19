# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2015 Brice Texier
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

module Backend
  class FormBuilder < SimpleForm::FormBuilder
    def referenced_nomenclature(association, options = {})
      klass = @object.class
      reflection = klass.nomenclature_reflections[association]
      raise ArgumentError, "Invalid nomenclature reflection: #{association}" unless reflection
      options[:collection] ||= reflection.klass.selection
      options[:label] ||= klass.human_attribute_name(association)
      input(reflection.foreign_key, options)
    end

    def list_input(association, options = {})
      # TODO
    end

    # Display a selector with "new" button
    def referenced_association(association, options = {})
      return self.association(association, options) if options[:as] == :hidden
      options = referenced_association_input_options(association, options)
      input(options[:reflection].foreign_key, options)
    end

    # Display a selector with "new" button
    def referenced_association_field(association, options = {})
      return self.association(association, options) if options[:as] == :hidden
      options = referenced_association_input_options(association, options)
      html_options = options[:input_html].merge(options.slice(:as, :reflection))
      input_field(options[:reflection].foreign_key, html_options)
    end

    # Adds nested association support
    def nested_association(association, *args)
      options = args.extract_options!
      reflection = find_association_reflection(association)
      raise "Association #{association.inspect} not found" unless reflection
      if block_given?
        ActiveSupport::Deprecation.warn "Nested association don't take code block anymore. Use partial '#{association.to_s.singularize}_fields' instead."
      end
      # raise ArgumentError.new("Reflection #{reflection.name} must be a has_many") if reflection.macro != :has_many
      item = association.to_s.singularize
      partial = options[:partial] || item + '_fields'
      options[:locals] ||= {}
      html = simple_fields_for(association, options[:collection]) do |nested|
        @template.render(partial, options[:locals].merge(f: nested))
      end
      html_options = { id: "#{association}-field", class: "nested-#{association} nested-association" }
      if reflection.macro == :has_many
        unless options[:new].is_a?(FalseClass)
          html << @template.content_tag(:div, class: 'links') do
            @template.link_to_add_association(options[:button_label] || "labels.add_#{item}".t, self, association, 'data-no-turbolink' => true, partial: partial, render_options: { locals: options[:locals] }, class: "nested-add add-#{item}")
          end
        end
        if options[:minimum]
          html_options[:data] ||= {}
          html_options[:data][:association_insertion_minimum] = options[:minimum]
        end
        if options[:maximum]
          html_options[:data] ||= {}
          html_options[:data][:association_insertion_maximum] = options[:maximum]
        end
      end
      @template.content_tag(:div, html, html_options)
    end

    # Adds custom fields
    def custom_fields
      return nil unless @object.customizable?
      custom_fields = @object.class.custom_fields
      return nil unless custom_fields.any?
      @template.content_tag(:div, class: 'custom-fields') do
        simple_fields_for(:custom_fields, OpenStruct.new(@object.custom_fields)) do |cff|
          custom_fields.map do |custom_field|
            options = { as: custom_field.nature.to_sym, required: custom_field.required?, label: custom_field.name }
            if custom_field.choice?
              options[:collection] = custom_field.choices.collect { |c| [c.name, c.value] }
            end

            if custom_field.nature.to_sym == :number
              options[:as] = :string
              options[:input_html] = { pattern: '[0-9]+([.][0-9]+)?' }
            end

            cff.input(custom_field.column_name, options)
          end.join.html_safe
        end
      end
    end

    def attachments_field_set
      @template.field_set(:attachments) do
        attachments
      end
    end

    def attachments
      nested_association :attachments
    end

    def reading(options = {})
      indicator = Nomen::Indicator.find!(@object.indicator_name)
      @template.render(partial: 'backend/shared/reading_form', locals: { f: self, indicator: indicator, hidden: (options[:as] == :hidden) })
    end

    def variant_quantifier_of(association, *args, &block)
      input("#{association}_quantifier", wrapper: :append) do
        variant_quantifier_of_field(association, *args, &block)
      end
    end

    def variant_quantifier_of_field(association, *args)
      options = args.extract_options!
      unless reflection = find_association_reflection(association)
        raise "Association #{association.inspect} not found"
      end
      indicator_column = options[:indicator_column] || "#{association}_indicator"
      unit_column = options[:unit_column] || "#{association}_unit"
      html_options = { data: { variant_quantifier: "#{@object.class.name.underscore}_#{reflection.foreign_key}" } }
      # Adds quantifier
      %i[population working_duration].each do |quantifier|
        html_options[:data]["quantifiers_#{quantifier}".to_sym] = true if options[quantifier]
      end
      # Specify scope
      html_options[:data][:use_closest] = options[:closest] if options[:closest]
      option_tags = nil
      if variant = @object.send(association)
        quantifier_id = "#{@object.send(indicator_column)}-#{@object.send(unit_column)}"
        option_tags = variant.unified_quantifiers(options.slice(:population, :working_duration)).map do |quantifier|
          # Please update app/views/backend/product_nature_variants/quantifiers view if you change something here
          attrs = { value: "#{quantifier[:indicator][:name]}-#{quantifier[:unit][:name]}", data: { indicator: quantifier[:indicator][:name], unit: quantifier[:unit][:name], unit_symbol: quantifier[:unit][:symbol] } }
          attrs[:selected] = true if attrs[:value] == quantifier_id
          @template.content_tag(:option, :unit_and_indicator.tl(indicator: quantifier[:indicator][:human_name], unit: quantifier[:unit][:human_name]), attrs)
        end.join.html_safe
      end
      html = @template.select_tag("#{association}_quantifier", option_tags, html_options)
      html << input_field(indicator_column, as: :hidden, class: 'quantifier-indicator')
      html << input_field(unit_column, as: :hidden, class: 'quantifier-unit')
      html
    end

    # Updates default input method
    def input(attribute_name, options = {}, &block)
      options[:input_html] ||= {}
      if options[:show]
        options[:input_html]['data-show'] = clean_targets(options.delete(:show))
      end
      if options[:hide]
        options[:input_html]['data-hide'] = clean_targets(options.delete(:hide))
      end
      unless options.key?(:disabled)
        if @object.is_a?(ActiveRecord::Base) && !@object.new_record? &&
           @object.class.readonly_attributes.include?(attribute_name.to_s)
          options[:disabled] = true unless options[:as] == :hidden
        end
      end
      autocomplete = options[:autocomplete]
      if autocomplete
        autocomplete = {} if autocomplete.is_a?(TrueClass)
        autocomplete[:column] ||= attribute_name.to_s
        autocomplete[:action] ||= :autocomplete
        autocomplete[:format] ||= :json
        options[:input_html]['data-autocomplete'] = @template.url_for(autocomplete)
      end
      super(attribute_name, options, &block)
    end

    def picture(attribute_name = :picture, options = {})
      format = options.delete(:format) || :thumb
      input(attribute_name, options) do
        html = file_field(attribute_name)
        if @object.send(attribute_name).file?
          html << @template.content_tag(:div, @template.image_tag(@object.send(attribute_name).url(format)), class: 'preview picture')
        end
        html
      end
    end

    def items_list(attribute_name, options = {})
      prefix = @lookup_model_names.first +
               @lookup_model_names[1..-1].collect { |x| "[#{x}]" }.join +
               "[#{attribute_name}][]"
      if options[:selection]
        selection = options[:selection]
      elsif options[:of]
        selection = []
        if options[:of].to_s =~ /\#/
          array = options[:of].to_s.split('#')
          selection = Nomen[array.first].property_natures[array.second].selection
        else
          selection = Nomen[options[:of]].selection
        end
      else
        raise 'Need selection'
      end
      selection -= Indicateable::DEPRECATED if attribute_name == :variable_indicators_list || attribute_name == :frozen_indicators_list
      list = @object.send(attribute_name) || []
      input(attribute_name, options) do
        @template.content_tag(:span, class: 'control-group symbol-list') do
          selection.collect do |human_name, name|
            checked = list.include?(name.to_sym)
            @template.label_tag(nil, class: "nomenclature-item#{' checked' if checked}") do
              @template.check_box_tag(prefix, name, checked) +
                @template.content_tag(:span, human_name)
            end
          end.join.html_safe
        end
      end
    end

    def abilities_list(attribute_name = :abilities_list, options = {})
      prefix = @lookup_model_names.first +
               @lookup_model_names[1..-1].collect { |x| "[#{x}]" }.join +
               "[#{attribute_name}][]"
      input(attribute_name, options) do
        data_lists = {}
        @template.content_tag(:span, class: 'control-group abilities-list') do
          abilities_for_select = Nomen::Ability.list.sort_by(&:human_name).map do |a|
            attrs = { value: a.name }
            if a.parameters
              a.parameters.each do |parameter|
                if parameter == :variety
                  data_lists[parameter] ||= Nomen::Variety.selection
                elsif parameter == :issue_nature
                  data_lists[parameter] ||= Nomen::IssueNature.selection
                else
                  raise "Unknown parameter type for an ability: #{parameter.inspect}"
                end
              end
              attrs[:data] = { ability_parameters: a.parameters.join(', ') }
            end
            @template.content_tag(:option, a.human_name, attrs)
          end.join.html_safe
          widget = @template.content_tag(:span, class: 'abilities') do
            if list = @object.send(attribute_name)
              list.collect do |a|
                ar = a.to_s.split(/[\(\,\s\)]+/).compact
                ability = Nomen::Ability[ar.shift]
                @template.content_tag(:div, data: { ability: ability.name }, class: :ability) do
                  html = @template.label_tag ability.human_name
                  html << @template.hidden_field_tag(prefix, a, class: 'ability-value')
                  ar.each_with_index do |p, index|
                    html << @template.select_tag(nil, @template.options_for_select(data_lists[ability.parameters[index]], p), data: { ability_parameter: index })
                  end
                  html << @template.link_to('#', data: { remove_closest: '.ability' }) do
                    @template.content_tag(:i)
                  end
                  html
                end
              end.join.html_safe
            end
          end
          attrs = {}
          widget << @template.select_tag('ability-creator', abilities_for_select, name: nil)
          widget << ' '.html_safe
          widget << @template.link_to(:add.tl, '#ability-creator', data: { add_ability: prefix })
          data_lists.each do |key, selection|
            widget << @template.content_tag(:datalist, @template.options_for_select(selection), data: { ability_parameter_list: key })
          end
          widget
        end
      end
    end

    def shape(attribute_name = :shape, options = {})
      geometry(attribute_name, options)
    end

    def polygon(attribute_name, options = {})
      geometry(attribute_name, options)
    end

    def linestring(attribute_name, options = {})
      geometry(attribute_name, options.merge(draw: { polygon: false, polyline: true }))
    end

    def geometry(attribute_name, options = {})
      editor = options[:editor] || {}
      editor[:controls] ||= {}
      editor[:controls][:draw] ||= {}
      editor[:controls][:draw][:draw] = options[:draw] || {}
      editor[:controls][:importers] ||= { formats: %i[gml kml geojson], title: :import.tl, okText: :import.tl, cancelText: :close.tl }
      editor[:controls][:importers][:content] ||= @template.importer_form(editor[:controls][:importers][:formats])

      editor[:withoutLabel] = true

      geom = @object.send(attribute_name)
      if geom
        geometry = Charta.new_geometry(geom)
        editor[:edit] = geometry.to_json_object
        editor[:view] = { center: geometry.centroid, zoom: 16 }
      else
        if sibling = @object.class.where("#{attribute_name} IS NOT NULL").first
          editor[:view] = { center: Charta.new_geometry(sibling.send(attribute_name)).centroid }
        elsif zone = CultivableZone.first
          editor[:view] = { center: zone.shape_centroid }
        end
      end
      show = options.delete(:show)
      unless show.is_a?(FalseClass)
        show ||= @object.class.where.not(attribute_name => nil)
        union = Charta.empty_geometry
        if show.any?
          if show.is_a?(Hash) && show.key?(:series)
            editor[:show] = show
          else
            union = show.geom_union(attribute_name)
            editor[:show] = union.to_json_object unless union.empty?
          end
        else
          editor[:show] = {}
          editor[:show][:series] = {}
        end
        editor[:useFeatures] = true
      end
      editor[:back] ||= MapLayer.available_backgrounds.collect(&:to_json_object)
      editor[:overlays] ||= MapLayer.available_overlays.collect(&:to_json_object)

      no_map = options.delete(:no_map)
      map_options = {}
      map_options = { input_html: { data: { map_editor: editor } } } unless no_map
      input(attribute_name, options.deep_merge(map_options))
    end

    def shape_field(attribute_name = :shape, options = {})
      raise @object.send(attribute_name)
      geometry = Charta.new_geometry(@object.send(attribute_name) || Charta.empty_geometry)
      options[:input_html] ||= {}
      options[:input_html][:data] ||= {}
      options[:input_html][:data][:map_editor] ||= {}
      options[:input_html][:data][:map_editor] ||= {}
      options[:input_html][:data][:map_editor][:back] ||= MapLayer.available_backgrounds.collect(&:to_json_object)
      options[:input_html][:data][:map_editor][:overlays] ||= MapLayer.available_overlays.collect(&:to_json_object)

      # return self.input(attribute_name, options.merge(input_html: {data: {spatial: geometry.to_json_object}}))
      input_field(attribute_name, options.merge(input_html: { data: { map_editor: { edit: geometry.to_json_object } } }))
    end

    def geolocation(attribute_name = :geolocation, options = {})
      point(attribute_name, options)
    end

    def geolocation_field(attribute_name = :geolocation, options = {})
      point_field(attribute_name, options)
    end

    def point(attribute_name, options = {})
      marker = {}
      if geom = @object.send(attribute_name)
        marker[:marker] = Charta.new_geometry(geom).to_json_object['coordinates'].reverse
        marker[:view] = { center: marker[:marker] }
      else
        siblings = @object.class.where("#{attribute_name} IS NOT NULL").order(id: :desc)
        if siblings.any?
          marker[:view] = { center: Charta.new_geometry(siblings.first.send(attribute_name)).centroid }
        elsif zone = CultivableZone.first
          marker[:view] = { center: zone.shape_centroid }
        end
        marker[:marker] = marker[:view][:center] if marker[:view]
      end
      marker[:background] ||= MapLayer.available_backgrounds.collect(&:to_json_object)
      input(attribute_name, options.merge(input_html: { data: { map_marker: marker } }))
    end

    def point_field(attribute_name, options = {})
      marker = {}
      if geom = @object.send(attribute_name)
        coordinates = Charta.new_geometry(geom).to_json_object['coordinates']
        marker[:marker] = coordinates.reverse if coordinates
        marker[:view] = { center: marker[:marker] }
      else
        if sibling = @object.class.where("#{attribute_name} IS NOT NULL").first
          marker[:view] = { center: Charta.new_geometry(sibling.send(attribute_name)).centroid }
        elsif zone = CultivableZone.first
          marker[:view] = { center: zone.shape_centroid }
        end
        marker[:marker] = marker[:view][:center] if marker[:view]
      end
      marker[:background] ||= MapLayer.available_backgrounds.collect(&:to_json_object).first
      marker[:background] &&= MapLayer.default_background.to_json_object
      input_field(attribute_name, options.merge(data: { map_marker: marker }))
    end

    def money(attribute_name, *args)
      options = args.extract_options!
      currency_attribute_name = args.shift || options[:currency_attribute] || :currency
      input(attribute_name, options.merge(wrapper: :append)) do
        html = input_field(attribute_name)
        html << input_field(currency_attribute_name, collection: Nomen::Currency.items.values.collect { |c| [c.human_name, c.name.to_s] }.sort)
        html
      end
    end

    def datetime_range(*args)
      options = args.extract_options!
      start_attribute_name = args.shift || :started_at
      stop_attribute_name = args.shift || :stopped_at
      attribute_name = args.shift || options[:name] || :period
      input(attribute_name, options.merge(wrapper: :append)) do
        @template.content_tag(:span, :from.tl, class: 'add-on') +
          input_field(start_attribute_name, options[:start_input_html] || options[:input_html]) +
          @template.content_tag(:span, :to.tl, class: 'add-on') +
          input_field(stop_attribute_name, options[:stop_input_html] || options[:input_html])
      end
    end

    def date_range(start_attribute_name = :started_on, stop_attribute_name = :stopped_on, *args)
      options = args.extract_options!
      attribute_name = args.shift || options[:name] || :period
      input(attribute_name, options.merge(wrapper: :append)) do
        @template.content_tag(:span, :from.tl, class: 'add-on') +
          input(start_attribute_name, wrapper: :simplest) +
          @template.content_tag(:span, :to.tl, class: 'add-on') +
          input(stop_attribute_name, wrapper: :simplest)
      end
    end

    def delta_field(value_attribute, delta_attribute, unit_name_attribute, unit_values, *args)
      options = args.extract_options!
      attribute_name = args.shift || options[:name]

      input(attribute_name, options.merge(wrapper: :append)) do
        input(value_attribute, wrapper: :simplest) +
          @template.content_tag(:span, :delta.tl, class: 'add-on') +
          input(delta_attribute, wrapper: :simplest) +
          unit_field(unit_name_attribute, unit_values, args)
      end
    end

    # Load a partial
    def subset(name, options = {}, &block)
      options[:id] ||= name
      if options[:depend_on]
        options['data-depend-on'] = options.delete(:depend_on)
      end
      if block_given?
        return @template.content_tag(:div, capture(&block), options)
      else
        return @template.content_tag(:div, @template.render(partial: "#{name}_form", locals: { f: self, object: @object }), options)
      end
    end

    def backend_fields_for(*args, &block)
      options = args.extract_options!
      options[:wrapper] = self.options[:wrapper] if options[:wrapper].nil?
      options[:defaults] ||= self.options[:defaults]

      options[:builder] ||= if self.class < ActionView::Helpers::FormBuilder
                              self.class
                            else
                              Backend::FormBuilder
                            end
      fields_for(*(args << options), &block)
    end

    def product_form
      model = object.class
      until @template.lookup_context.exists?("backend/#{model.name.tableize}/form", [], true)
        model = model.superclass
        break if model == ActiveRecord::Base || model == Ekylibre::Record::Base
      end
      @template.render "backend/#{model.name.tableize}/form", f: self
    end

    # Build a frame for all product _forms
    def product_form_frame(options = {}, &block)
      html = ''.html_safe

      variant = @object.variant
      unless variant
        variant_id = @template.params[:variant_id]
        variant = ProductNatureVariant.where(id: variant_id.to_i).first if variant_id
      end

      full_name = nil
      if @template.params[:person_id]
        person = Entity.find(@template.params[:person_id])
        if person
          @object.born_at ||= person.born_at
          full_name = Entity.find(@template.params[:person_id]).full_name
        end
      end

      options[:input_html] ||= {}
      options[:input_html][:class] ||= ''

      if variant
        @object.nature ||= variant.nature
        whole_indicators = variant.whole_indicators
        # Add product type selector
        form = @template.field_set options[:input_html] do
          fs = input(:variant_id, value: variant.id, as: :hidden)
          # Add name
          fs << (full_name.nil? ? input(:name) : input(:name, input_html: { value: full_name }))
          # Add work number
          fs << input(:work_number) unless options[:work_number].is_a?(FalseClass)
          # Add variant selector
          fs << variety(scope: variant)

          fs << input(:born_at)
          fs << input(:dead_at)

          fs << nested_association(:labellings)

          # error message for indicators
          if Rails.env.development?
            fs << @object.errors.inspect if @object.errors.any?
          end

          # Adds owner fields
          if @object.initializeable?
            fs << @template.render(partial: 'backend/shared/initial_values_form', locals: { f: self })
          end

          # Add custom fields
          fs << custom_fields

          fs << attachments

          fs
        end
        html << form

        # Add form body
        html += if block_given?
                  @template.capture(&block)
                else
                  @template.render(partial: 'backend/shared/default_product_form', locals: { f: self })
                end

        # Add first indicators
        indicators = variant.variable_indicators.delete_if do |i|
          whole_indicators.include?(i) || %i[geolocation shape].include?(i.name.to_sym)
        end
        if object.new_record? && indicators.any?

          if @object.readings.empty?
            indicators.each do |indicator|
              @object.readings.build(indicator_name: indicator.name)
            end
          end

          html << @template.field_set(:indicators) do
            fs = ''.html_safe
            @object.readings.each do |reading|
              indicator = reading.indicator
              # error message for indicators
              if Rails.env.development?
                fs << reading.errors.inspect if reading.errors.any?
              end
              fs << backend_fields_for(:readings, reading) do |indfi|
                indfi.input(:product_id, as: :hidden) + indfi.reading
              end
            end
            fs
          end
        end

      else
        clear_actions!
        variants = ProductNatureVariant.of_variety(@object.class.name.underscore)
        if variants.any?
          html << @template.field_set(:choose_a_type_of_product) do
            #           buttons = ''.html_safe
            #           for variant in ProductNatureVariant.of_variety(@object.class.name.underscore)
            #             buttons << @template.link_to(variant.name, { action: :new, variant_id: variant.id }, class: 'btn')
            #           end
            #           buttons
            choices = {}
            choices[:action] ||= :unroll
            choices[:controller] ||= :product_nature_variants

            new_url = {}
            new_url[:controller] ||= @object.class.name.underscore.pluralize.downcase
            new_url[:action] ||= :new

            choices[:scope] = { of_variety: @object.class.name.underscore.to_sym } if @object.class.name.present?

            input_id = :variant_id

            html_options = {}
            html_options[:data] ||= {}
            @template.content_tag(:div, class: 'control-group') do
              @template.content_tag(:label, Product.human_attribute_name(:variant), class: 'control-label') +
                @template.content_tag(:div, class: 'controls') do
                  input_field(:variant, html_options.deep_merge(as: :string, id: input_id, data: { selector: @template.url_for(choices), redirect_on_change_url: @template.url_for(new_url) }))
                end
            end
          end
        end

      end

      html
    end

    def variety(options = {})
      scope = options[:scope]
      varieties = Nomen::Variety.selection(scope ? scope.variety : nil)
      child_scope = options[:child_scope]
      if child_scope
        varieties.keep_if { |(_l, n)| child_scope.all? { |c| c.variety? && Nomen::Variety.find(c.variety) <= n } }
      end
      @object.variety ||= scope.variety if scope
      @object.variety ||= varieties.first.last if @object.new_record? && varieties.first
      if options[:derivative_of] || (scope && scope.derivative_of)
        derivatives = Nomen::Variety.selection(scope ? scope.derivative_of : nil)
        @object.derivative_of ||= scope.derivative_of if scope
        @object.derivative_of ||= derivatives.first.last if @object.new_record? && derivatives.first
        if child_scope
          derivatives.keep_if { |(_l, n)| child_scope.all? { |c| c.derivative_of? && Nomen::Variety.find(c.derivative_of) <= n } }
        end
      end
      if !derivatives.nil? && derivatives.any?
        return input(:variety, wrapper: :append, class: :inline) do
          field = ('<span class="add-on">' <<
              ERB::Util.h(:x_of_y.tl(x: '{@@@@VARIETY@@@@}', y: '{@@@@DERIVATIVE@@@@}')) <<
              '</span>')
          field.gsub!('{@@', '</span>')
          field.gsub!('@@}', '<span class="add-on">')
          field.gsub!('<span class="add-on"></span>', '')
          field.gsub!('@@VARIETY@@', input_field(:variety, as: :select, collection: varieties))
          field.gsub!('@@DERIVATIVE@@', input(:derivative_of, as: :select, collection: derivatives, wrapper: :nested))
          field.html_safe
        end
      else
        return input(:variety, collection: varieties)
      end
    end

    def access_control_list(name = :rights)
      prefix = @lookup_model_names.first + @lookup_model_names[1..-1].collect { |x| "[#{x}]" }.join
      html = ''.html_safe
      reference = (@object.send(name) || {}).with_indifferent_access
      for resource, rights in Ekylibre::Access.resources.sort { |a, b| Ekylibre::Access.human_resource_name(a.first) <=> Ekylibre::Access.human_resource_name(b.first) }
        resource_reference = reference[resource] || []
        html << @template.content_tag(:div, class: 'control-group booleans') do
          @template.content_tag(:label, class: 'control-label') do
            Ekylibre::Access.human_resource_name(resource)
          end +
            @template.content_tag(:div, class: 'controls') do
              rights.collect do |interaction, right|
                checked = resource_reference.include?(interaction.to_s)
                attributes = { class: "chk-access chk-access-#{interaction}", data: { access: "#{interaction}-#{resource}" } }
                if right.dependencies
                  attributes[:data][:need_accesses] = right.dependencies.join(' ')
                end
                attributes[:class] << ' active' if checked
                @template.content_tag(:label, attributes) do
                  @template.check_box_tag("#{prefix}[#{name}][#{resource}][]", interaction, checked) +
                    ERB::Util.h(Ekylibre::Access.human_interaction_name(interaction).strip)
                end
              end.join.html_safe
            end
        end
      end
      html
    end

    def fields(partial = 'form')
      @template.content_tag(:div, @template.render(partial, f: self), class: 'form-fields')
    end

    def yes_no_radio(attribute_name, options = {})
      input(attribute_name, options.merge(as: :radio_buttons, collection: [[::I18n.t('boolean.polar.true_class'), true], [I18n.t('boolean.polar.false_class'), false]]))
    end

    def actions
      return nil unless @actions.any?
      @template.form_actions do
        html = ''.html_safe
        for action in @actions
          html += if action[:type] == :block
                    action[:content].html_safe
                  else
                    @template.send(action[:type], *action[:args])
                  end
          html += ' '.html_safe
        end
        html
      end
    end

    def add(type = :block, *args, &block)
      @actions ||= []
      if type == :block
        @actions << { type: type, content: @template.capture(&block) }
      else
        type = { submit: :submit_tag, link: :link_to }[type] || type
        @actions << { type: type, args: args }
      end
      true
    end

    def clear_actions!
      @actions = []
    end

    protected

    def clean_targets(targets)
      if targets.is_a?(String)
        return targets
      elsif targets.is_a?(Symbol)
        return "##{targets}"
      elsif targets.is_a?(Array)
        return targets.collect { |t| clean_targets(t) }.join(', ')
      else
        return targets.to_json
      end
      targets
    end

    # Compute all needed options for referenced_association
    def referenced_association_input_options(association, options = {})
      reflection = find_association_reflection(association)
      raise "Association #{association.inspect} not found" unless reflection
      if reflection.macro != :belongs_to
        raise ArgumentError, "Reflection #{reflection.name} must be a belongs_to"
      end

      choices = options.delete(:source) || {}
      choices = { scope: choices } if choices.is_a?(Symbol)
      choices[:action] ||= :unroll
      choices[:controller] ||= reflection.class_name.underscore.pluralize

      model = @object.class

      options[:input_html] ||= {}
      options[:input_html][:data] ||= {}
      options[:input_html][:data][:use_closest] = options[:closest] if options[:closest]
      options[:input_html][:data][:selector] = @template.url_for(choices)
      unless options[:new].is_a?(FalseClass)
        new_url = options[:new].is_a?(Hash) ? options[:new] : {}
        new_url[:controller] ||= choices[:controller]
        new_url[:action] ||= :new
        options[:input_html][:data][:selector_new_item] = @template.url_for(new_url)
      end
      # options[:input_html][:data][:value_parameter_name] = options[:value_parameter_name] || reflection.foreign_key
      options[:input_html][:data][:selector_id] = model.name.underscore + '_' + reflection.foreign_key.to_s
      options[:as] = :string
      options[:reflection] = reflection
      options
    end

    def unit_field(unit_name_attribute, units_values, *_args)
      if units_values.is_a?(Array)
        return input(unit_name_attribute, collection: units_values, include_blank: false, wrapper: :simplest)
      end
      @template.content_tag(:span, units_values.tl, class: 'add-on')
    end
  end
end

# This hack permits to change default presentation of the DateTime input
module SimpleForm
  module Inputs
    class DateTimeInput
      def input_html_options
        value = object.send(attribute_name)
        # format = @options[:format] || :default
        # unless format.is_a?(Symbol)
        #   raise ArgumentError, "Option :format must be a Symbol referencing a translation 'date.formats.<format>'"
        # end
        # if localized_value = value
        #   localized_value = localized_value.l(format: format)
        # end
        # format = I18n.translate("#{input_type == :datetime ? :time : input_type}.formats.#{format}")
        # # format = I18n.translate("time.formats.#{format}")
        # Formize::DATE_FORMAT_TOKENS.each{|js, rb| format.gsub!(rb, js)}
        # Formize::TIME_FORMAT_TOKENS.each{|js, rb| format.gsub!(rb, js)}
        options = {
          # data: {
          #   format: format,
          #   human_value: localized_value
          # },
          lang: 'i18n.iso2'.t,
          value: value.blank? ? nil : value.l(format: "%Y-%m-%d#{' %H:%M' if input_type == :datetime}"),
          type: input_type,
          size: @options.delete(:size) || (input_type == :date ? 10 : 16)
        }
        super.merge options
      end

      def label_target
        super
      end

      def input(_wrapper_options = nil)
        @builder.text_field(attribute_name, input_html_options)
        # @builder.send("#{input_type}_field", attribute_name, input_html_options)
      end
    end
  end
end
