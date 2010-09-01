module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter 
      # By default, the SQL is used
      def substr(string, from, count)
        return "SUBSTR(#{string}, #{from.to_i}, #{from.to_i})"
      end

      def trim(string)
        return "TRIM(#{string})"
      end

      def length(string)
        return "LENGTH(#{string})"
      end

      def concatenate(*strings)
        return strings.join("||")
      end

      def not_boolean(string)
        "NOT (#{string})"
      end
    end


    class SQLServerAdapter
      def substr(string, from, count)
        return "SUBSTRING(#{string}, #{from.to_i}, #{from.to_i})"
      end

      def trim(string)
        return "LTRIM(RTRIM(#{string}))"
      end

      def length(string)
        return "LEN(#{string})"
      end

      def concatenate(*strings)
        return strings.join("+")
      end

      def not_boolean(string)
        "CASE WHEN (#{string})=#{quoted_true} THEN #{quoted_false} ELSE #{quoted_true} END"
      end
    end

  end
end

