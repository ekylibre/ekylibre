module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter 
      # By default, the SQL is used
      def substr(string, from, count)
        return "SUBSTR(#{string}, #{from.to_i}, #{count.to_i})"
      end

      def trim(string)
        return "TRIM(#{string})"
      end

      def length(string)
        return "LENGTH("+string+")"
      end

      def concatenate(*strings)
        return strings.join("||")
      end

      def not_boolean(string)
        "NOT (#{string})"
      end
    end

  end
end

