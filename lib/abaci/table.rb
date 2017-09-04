module Abaci
  class Table
    def initialize(file)
      rows = CSV.read(file)
      columns = rows.shift
      @columns = []
      columns.each do |column|
        @columns << Column.new(column)
      end

      @rows = []
      rows.each do |row|
        values = {}
        @columns.each_with_index do |c, i|
          values[c.name] = c.cast(row[i].strip) if row[i].present?
        end
        @rows << Row.new(values)
      end
    end

    def select(&block)
      @rows.select(&block)
    end

    def detect(&block)
      @rows.detect(&block)
    end

    def collect(&block)
      @rows.collect(&block)
    end
    alias map collect

    def each(&block)
      @rows.each(&block)
    end

    # Filter rows with given properties
    def where(properties)
      @rows.select do |row|
        valid = true
        for name, value in properties
          property_value = row[name]
          if value.is_a?(Array)
            one_found = false
            for val in value
              if val.is_a?(Nomen::Item)
                one_found = true if property_value == val.name.to_sym
              else
                one_found = true if property_value == val
              end
            end
            valid = false unless one_found
          elsif value.is_a?(Nomen::Item)
            valid = false unless property_value == value.name.to_sym
          else
            valid = false unless property_value == value
          end
        end
        valid
      end
    end
  end
end
