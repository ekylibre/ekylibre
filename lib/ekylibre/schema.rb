module Ekylibre
  module Schema
    autoload :TABLES, 'ekylibre/schema/reference'
    autoload :MODELS, 'ekylibre/schema/reference'
    autoload :Column, 'ekylibre/schema/column'

    class << self

      def models
        MODELS
      end

      def references(table = nil, column = nil)
        if table.present? and column.present?
          if t = TABLES[table]
            if c = t[column]
              return c.references
            end
          end
          return nil
        else
          return @@references ||= TABLES.inject({}) do |h, table|
            h[table.first] = table.second
            h
          end.freeze
        end
      end

      def tables
        TABLES
      end

      def table_names
        @table_names ||= tables.keys.map(&:to_sym)
      end


      def model_names
        @@model_names ||= models.collect{|m| m.to_s.camelcase.to_sym}.sort.freeze
      end

    end

  end

end
