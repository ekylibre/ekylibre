module HasInterval
  extend ActiveSupport::Concern

  module ClassMethods
    def has_interval(*columns)
      columns.each do |column|
        define_method column do
          self[column].present? ? ActiveSupport::Duration.parse(self[column]) : nil
        end

        define_method "#{column}=" do |value|
          self[column] = if value.blank?
                           nil
                         elsif value.is_a?(ActiveSupport::Duration)
                           value.iso8601
                         elsif value.is_a?(String) && ActiveSupport::Duration.parse(value)
                           value
                         else
                           raise ArgumentError, "Invalid duration: #{value}"
                         end
        end
      end
    end
  end
end
