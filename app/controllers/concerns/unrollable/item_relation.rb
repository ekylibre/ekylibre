module Unrollable
  class InvalidScopeException < StandardError
  end

  # Wrapper around an ActiveRecord relation with easy-to-use filtering methods.
  class ItemRelation
    include Toolbelt

    attr_accessor :items

    def initialize(items)
      @items = items
    end

    def filter_through(model, includes, order, scopes, excludes)
      self
        .includes(includes)
        .reorder(order)
        .scoped(scopes, model)
        .excluding(excludes)
    end

    def includes(columns)
      includes = columns.to_includes
      includes.any? ? self.class.new(@items.includes(includes).references(includes)) : self
    end

    def scoped(scopes, model)
      items = @items
      scopes.symbolize_keys.each do |scope, parameter|
        unless with_parameters?(scope, model)
          return bad_scope(scope, model) unless true?(parameter)
          next items = items.send(scope)
        end

        return bad_scope(scope, model) unless multiple_params_in?(parameter)

        parameters = Unrollable::Extracting.parameters_from(parameter)
        items = items.send(scope, *parameters)
      end
      self.class.new(items)
    end

    def excluding(record_ids)
      return self unless record_ids
      self.class.new(@items.where.not(id: record_ids))
    end

    def keeping(id)
      return nil unless id
      self.class.new(@items.where(id: id))
    end

    def ordered_matches(keys, searchables, query = nil)
      return @items if keys.blank?

      request = conditions_for(keys, searchables).join(' AND ')
      where_request = request.gsub('[!BEGIN!]', '%')
      order_request = "(#{request.gsub('[!BEGIN!]', '')}) DESC"

      exact_match_request = exact_conditions_for(query, searchables)
      self.class.new(@items.where(where_request).reorder([exact_match_request, order_request].join(',')))
    end

    # Forwarding the unknown to the AR::Relation
    def method_missing(method, *args, &block)
      return super unless @items.respond_to?(method)
      result = @items.send(method, *args, &block)
      result.respond_to?(:to_sql) ? self.class.new(result) : result
    end

    def respond_to_missing?(method, include_private = false)
      @items.respond_to?(method, include_private) || super
    end

    protected

    def conditions_for(keys, searchables)
      keys.map { |key| searchables.map { |filter| unaccented_match(filter.search, key) }.join(' OR ') }
          .map { |condition| "(#{condition})" }
    end

    def exact_conditions_for(keys, searchables)
      searchables.map { |filter| exact_unaccented_match(filter.search, keys) }
                 .map { |condition| "(#{condition})" }.join(',')
    end

    def unaccented_match(term, pattern)
      "unaccent(CAST(#{term} AS VARCHAR)) ILIKE unaccent(#{ActiveRecord::Base.sanitize("[!BEGIN!]#{pattern}%")})"
    end

    def exact_unaccented_match(term, pattern)
      "unaccent(CAST(#{term} AS VARCHAR)) NOT ILIKE unaccent(#{ActiveRecord::Base.sanitize(pattern.to_s)})"
    end

    def bad_scope(scope, model)
      raise InvalidScopeException, <<-BAD_SCOPE
        Scope #{scope.inspect} is unknown for #{model.name}. #{model.scopes.map(&:name).inspect} are expected."
      BAD_SCOPE
    end

    def multiple_params_in?(parameter)
      parameter.is_a?(String) || parameter.is_a?(Array)
    end

    def with_parameters?(scope, model)
      model.complex_scopes.map(&:name).include?(scope)
    end
  end
end
