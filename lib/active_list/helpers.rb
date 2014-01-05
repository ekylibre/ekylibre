module ActiveList
  module Helpers

    def recordify!(value, record_name)
      if value.is_a?(Symbol)
        return record_name + "." + value.to_s
      elsif value.is_a?(Code)
        return "(" + value.gsub(/RECORD/, record_name) + ")"
      else
        raise ArgumentError, "Code or Symbol must be given to be recordified)"
      end
    end

    def recordify(value, record_name)
      if value.is_a?(Symbol)
        return record_name + "." + value.to_s
      elsif value.is_a?(Code)
        return "(" + value.gsub(/RECORD/, record_name) + ")"
      else
        return value.inspect
      end
    end

    def urlify(value, record_name)
      if value.is_a?(Code)
        return "(" + value.gsub(/RECORD/, record_name) + ")"
      else
        return value.inspect
      end
    end

  end
end
