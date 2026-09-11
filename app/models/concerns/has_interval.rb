# frozen_string_literal: true

module HasInterval
  extend ActiveSupport::Concern

  module ClassMethods
    def has_interval(*columns)
      columns.each do |column|
        # Rails 6.1 désérialise les colonnes `interval` de PostgreSQL en
        # `ActiveSupport::Duration` (OID::Interval) ; jusqu'à Rails 6.0 elles
        # arrivaient sous forme de chaîne, qu'il fallait analyser.
        define_method column do
          value = self[column]
          case value
          when nil, '' then nil
          when ActiveSupport::Duration then value
          else ActiveSupport::Duration.parse(value)
          end
        end

        define_method "#{column}=" do |value|
          self[column] = if value.blank?
                           nil
                         elsif value.is_a?(ActiveSupport::Duration)
                           value.iso8601
                         elsif value.is_a?(String) && ActiveSupport::Duration.parse(value)
                           value
                         else
                           raise ArgumentError.new("Invalid duration: #{value}")
                         end
        end
      end
    end
  end
end
