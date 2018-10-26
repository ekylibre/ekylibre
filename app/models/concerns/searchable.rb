module Searchable
  extend ActiveSupport::Concern

  included do
    class << self
      attr_reader :searchable_columns
      attr_reader :search_includes
      attr_reader :search_references

      def search_on(*columns, **columns_with_options)
        @searchable_columns ||= []
        @search_includes    ||= []
        @search_references  ||= []

        @searchable_columns += columns
        @searchable_columns += columns_with_options.keys

        @search_includes   += columns_with_options.values.map { |opt| opt[:includes]   }.compact
        @search_references += columns_with_options.values.map { |opt| opt[:references] }.compact

        @search_includes.uniq!
        @search_references.uniq!
        @searchable_columns.uniq!
      end
    end
  end

  module ClassMethods
    def matching(query = '')
      raise "Can't perform a search without any column in searchable_columns. Set search by calling #search in #{self}" unless searchable_columns.any?
      query = Array(query)

      ordering = []
      searchables = Array(searchable_columns)
      conditions = searchables.map do |criterion|
        matches = query.map do |match|
          sanitize_sql_array(["(lower(unaccent(#{criterion})) ILIKE lower(unaccent(?)))", "%#{match}%"])
        end
        if matches.compact.present?
          ordering << matches.map { |ord| "COALESCE((CASE WHEN (#{ord}) THEN 1 END), 0)" }
          '(' + matches.join(' AND ') + ')'
        end
      end
      conditions.compact!

      query = where(conditions.join(' OR '))
              .reorder(ordering.join(' + ') + (ordering.any? ? ' DESC' : ''))

      query = query.includes(*search_includes)     if search_includes.any?
      query = query.references(*search_references) if search_references.any?
      query
    end
  end
end
