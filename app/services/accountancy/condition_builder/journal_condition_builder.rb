module Accountancy
  module ConditionBuilder
    class JournalConditionBuilder < Base
      # Build an SQL condition based on options which should contains natures
      def nature_condition(natures, table_name:)
        if !natures.is_a?(Hash) || natures.empty?
          connection.quoted_true
        else
          "#{table_name}.nature IN (#{natures.keys.map { |nature| quote(nature) }.join(',')})"
        end
      end
    end
  end
end
