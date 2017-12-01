module Unrollable
  # Represents a selector Filter to silt through items.
  class Filter
    include Toolbelt

    attr_reader :search, :column

    def initialize(attribute, model, parents_of_attribute)
      @attribute = attribute
      @parents = parents_of_attribute
      @search = "#{model.table_name}.#{attribute}"
      @column = model.columns_definition[@attribute]

      raise "No column definition for #{search}." unless @column
    end

    def title
      @column.name
    end

    def name
      lineage.last(2).join('_').to_sym
    end

    def root?
      @parents.empty?
    end

    def searchable?
      @column.type != :boolean
    end

    def value_of(item)
      unbreakable_item = Maybe(item)
      value = lineage.reduce(unbreakable_item, &:send)

      return value.to_date.l.or_else('') if !value.is_none? && value.get.is_a?(ActiveSupport::TimeWithZone)

      value.or_else('')
    end

    class << self
      def searchables_in(filters, controller)
        searchables = filters.select(&:searchable?)
        searchables.blank? ? raise(<<-NO_SEARCHABLE_FILTERS) : searchables
          No searchable filters for #{controller}#unroll.
          Filters: #{filters.inspect}
          Columns: #{filters.map(&:column)}
        NO_SEARCHABLE_FILTERS
      end
    end

    protected

    def lineage
      @parents + [@attribute]
    end
  end
end
