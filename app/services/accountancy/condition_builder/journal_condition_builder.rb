# frozen_string_literal: true

module Accountancy
  module ConditionBuilder
    class JournalConditionBuilder < Base
      # Build an SQL condition based on options which should contains natures
      def nature_condition(natures, table_name:)
        if natures.blank?
          connection.quoted_true
        else
          "#{table_name}.nature IN (#{natures.keys.map { |nature| quote(nature) }.join(',')})"
        end
      end
    end
  end
end
