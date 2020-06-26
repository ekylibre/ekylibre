module ActiveExchanger
  class CsvParser
    require 'csv'

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def normalize(rows)
      rows.map do |row|
        normalize_row(row)
      end.reduce([[], []]) {|(acc_data, acc_errors), (data, errors)| [[*acc_data, data], [*acc_errors, errors]] }
    end

    # Returns the row as a struct AND an array of invalid fields. Empty array if no errors
    def normalize_row(row)
      h = {}
      invalid_fields = []

      config.each do |c|
        key = c[:name]
        value = row[c[:col]]
        type = c[:type]
        constraint = c[:constraint]

        value = value.blank? ? nil : transform(value, type)
        valid = constraint ? validate(value, constraint) : true

        invalid_fields << key if valid == false
        h[key] = value
      end

      [h.to_struct, invalid_fields]
    end

    def transform(value, type)
      case type
      when :integer
        value.to_i
      when :float
        value.tr(',', '.').to_f
      when :date
        value.to_date
      else
        value
      end
    end

    # Returns true if value is valid, false if not
    def validate(value, constraint)
      case constraint
      when :not_nil
        value.present?
      when :greater_or_equal_to_zero
        value.is_a?(Numeric) && value >= 0
      else
        false
      end
    end
  end
end
