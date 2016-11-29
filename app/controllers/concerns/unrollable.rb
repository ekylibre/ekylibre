module Unrollable
  extend ActiveSupport::Concern

  module ClassMethods
    # Create unroll action for all scopes in the model corresponding to the controller
    # including the default scope
    def unroll(*columns)
      available_options = [:model, :max, :order, :partial, :fill_in, :scope]
      options = columns.last.is_a?(Hash) ? columns.last : {}
      options = options.slice!(available_options) if (options.keys - available_options).empty?

      model = (options.delete(:model) || controller_name).to_s.classify.constantize
      default_scope = options.delete(:scope) || 'unscoped'
      max = options[:max] || 80
      available_methods = model.column_names.map(&:to_sym)

      columns = Unrollable.compactify(columns)

      if columns.blank?
        default_columns = [:title, :label, :full_name, :name, :code, :number, :reference_number]
        columns = default_columns & available_methods
        no_columns = "Cannot unroll #{model.name} records. No column available (#{columns.inspect})."
        raise no_columns unless columns
      end

      # Normalize parameters
      filters  = Unrollable.filterify(columns, model)
      includes = Unrollable.includify(columns)

      order = filters.map { |f| f[:search] }.compact unless options[:order]

      roots = filters.select { |f| f[:root] }
      fill_in = options[:fill_in] || (roots.first && roots.first[:column_name])
      fill_in &&= fill_in.to_sym unless fill_in.nil?

      fill_in = nil unless options.key?(:fill_in)

      if fill_in.present? && filters.none? { |c| c[:name] == fill_in }
        raise StandardError, "Label (#{filters.inspect}) of unroll must include the primary column: #{fill_in.inspect}"
      end

      searchable_filters = filters.select { |c| c[:pattern] && c[:column_type] != :boolean }
      no_filters = "No searchable filters for #{controller_path}#unroll.\nFilters: #{filters.inspect}\nColumns: #{columns.inspect}"
      raise no_filters unless searchable_filters.any?

      unroll = lambda do
        items = model.send(default_scope)
        unless includes.empty?
          items = items.includes(includes).references(includes)
        end
        items = items.reorder(order)

        scopes = Unrollable.extract_scopes_from(params)
        excluded_records = params[:exclude]

        begin
          items = Unrollable.scoped(items, scopes, model)
        rescue InvalidScopeException => e
          logger.error e.message
          head :bad_request
          return false
        end

        items = Unrollable.excluding(items, excluded_records)

        search_term = params[:q].to_s.strip
        keys = search_term.mb_chars.downcase.normalize.split(/[\\s\\,]+/)
        source = Unrollable.true?(params[:keep]) ? items : model
        items = Unrollable.keeping(source, params[:id])

        unless params[:id]
          items = Unrollable.matching(items, keys, searchable_filters)
          items = Unrollable.sorted(items, keys, searchable_filters)
        end

        respond_to do |format|
          format.html do
            render(
              partial: 'unrolled',
              locals: {
                max: max,
                items: items,
                fill_in: fill_in,
                keys: keys,
                filters: filters,
                render_partial: options[:partial],
                search: search_term.capitalize,
                model_name: model.name.underscore
              },
              layout: false
            )
          end

          format.json { render json: items.map { |item| { label: UnrollHelper.label_item(item, filters, controller_path), id: item.id } } }
          format.xml  { render  xml: items.map { |item| { label: UnrollHelper.label_item(item, filters, controller_path), id: item.id } } }
        end
      end

      define_method :unroll, &unroll
    end
  end

  class InvalidScopeException < StandardError; end

  class << self
    def scoped(items, scopes, model)
      items = items.dup
      scopes.symbolize_keys.each do |scope, parameter|
        unless with_parameters?(scope, model)
          return bad_scope(scope, model) unless true?(parameter)
          next items = items.send(scope)
        end

        return bad_scope(scope, model) unless multiple_params_in?(parameter)

        parameters = extract_parameters_from(parameter)
        items = items.send(scope, *parameters)
      end
      items
    end

    def excluding(items, record_ids)
      return items unless record_ids
      items.dup.where.not(id: record_ids)
    end

    def keeping(items, id)
      return items unless id
      items.dup.where(id: id)
    end

    def matching(items, keys, searchables)
      return items unless keys.present?
      filters = condition_set(keys, searchables, :pattern)

      items.dup.where(filters)
    end

    def sorted(items, keys, searchables)
      return items unless keys.present?
      order = condition_set(keys, searchables, :start_pattern)
      order = ActiveRecord::Base.send(:sanitize_sql_array, order)

      items.dup.reorder(order)
    end

    def condition_set(keys, searchables, pattern_column)
      conditions = ['(']
      keys.each_with_index do |key, index|
        conditions[0] << ') AND (' if index > 0
        conditions[0] << searchables
                         .map { |column| "unaccent(CAST(#{column[:search]} AS VARCHAR)) ILIKE unaccent(?)" }
                         .join(' OR ')
        conditions += searchables
                      .map { |column| "#{column[pattern_column].gsub('X', key)}" }
      end
      conditions[0] << ')'
      conditions
    end

    def bad_scope(scope, model)
      raise InvalidScopeException, "Scope #{scope.inspect} is unknown for #{model.name}. #{model.scopes.map(&:name).inspect} are expected."
    end

    def with_parameters?(scope, model)
      false if model.simple_scopes.map(&:name).include?(scope)
      true  if model.complex_scopes.map(&:name).include?(scope)
    end

    def true?(object)
      object.to_s == 'true'
    end

    def symbolized(array)
      array.map { |element| element.is_a?(Hash) ? element.symbolize_keys : element }
    end

    def multiple_params_in?(parameter)
      parameter.is_a?(String) || parameter.is_a?(Array)
    end

    def extract_parameters_from(parameter)
      params = parameter.strip.split(/\s*\,\s*/) if parameter.is_a? String
      symbolized(params || parameter)
    end

    def extract_scopes_from(params)
      return {} unless params[:scope]
      scope_is_without_params = params[:scope].is_a?(String) || params[:scope].is_a?(Symbol)
      return { params[:scope] => true } if scope_is_without_params
      params[:scope]
    end

    # Converts parameters to a list of value
    def filterify(object, model, parents = [])
      if object.is_a?(Array)
        object.map { |o| filterify(o, model, parents) }.flatten

      elsif object.is_a?(Hash)
        object.map do |k, v|
          unless reflection = model.reflect_on_association(k)
            raise "Cannot find a reflection #{k} for #{model.name}"
          end
          fmodel = reflection.class_name.constantize
          filterify(v, fmodel, parents + [k.to_sym])
        end.flatten

      elsif object.is_a?(Symbol) || object.is_a?(String)

        infos = object.to_s.split(':')
        name = infos[2] || [parents.last, infos.first].compact.join('_')

        to_call = (parents + [infos.first]).map(&:to_sym)

        filter = {
          name: name.to_sym,
          expression: ->(item) { to_call.reduce(Maybe(item), &:send).l.or_else('') },
          root: parents.empty?
        }
        return filter if infos.second == '!'
        unless definition = model.columns_definition[infos.first]
          raise "Cannot find column definition for #{model.table_name}##{infos.first}"
        end
        filter[:search]  = "#{model.table_name}.#{infos.first}"
        filter[:pattern] = infos.second || '%X%'
        filter[:start_pattern] = infos.second || 'X%'
        filter[:column_name] = definition.name
        filter[:column_type] = definition.type
        filter
      else
        raise "What a parameter? #{object.inspect}"
      end
    end

    # Converts parameters to a valid :includes option for ARel
    def includify(object)
      if object.is_a?(Array)
        a = object.map { |o| includify(o) }.compact
        (a.size == 1 ? a.first : a)
      elsif object.is_a?(Hash)
        n = object.each_with_object({}) do |pair, h|
          h[pair.first] = includify(pair.second)
          h
        end
        n.each_with_object([]) do |pair, a|
          a << (pair.second.nil? ? pair.first : { pair.first => pair.second })
          a
        end
      elsif object.is_a?(Symbol) || object.is_a?(String)
        nil
      else
        raise "What a parameter? #{object.inspect}"
      end
    end

    # Converts parameters to a valid :includes option for ARel
    def compactify(object)
      if object.is_a?(Array)
        a = object.map { |o| compactify(o) }.compact
        (a.empty? ? nil : a)
      elsif object.is_a?(Hash)
        (object.keys.empty? ? nil : object.each_with_object({}) { |p, h| h[p.first] = compactify(p.second); h })
      elsif object.is_a?(Symbol) || object.is_a?(String)
        object
      else
        raise "What a parameter? #{object.inspect}"
      end
    end
  end
end
