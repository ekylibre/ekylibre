module ActiveRecord
  module ConnectionAdapters
    class SQLServerAdapter
      def substr(string, from, count)
        return "SUBSTRING(#{string}, #{from.to_i}, #{count.to_i})"
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
