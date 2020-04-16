module Accountancy
  module ConditionBuilder
    class AccountConditionBuilder < Base

      # Build an SQL condition to restrict accounts to some ranges
      # Example : 1-3 41 43
      def range_condition(range, table_name:)
        conditions = []
        if range.blank?
          connection.quoted_true
        else
          range = Account.clean_range_condition(range)

          range.split(/\s+/).each do |expr|
            if expr =~ /\-/
              start, finish = expr.split(/\-+/)[0..1]
              max = [start.length, finish.length].max

              conditions << "SUBSTR(#{table_name}.number, 1, #{max}) BETWEEN #{quote(start.ljust(max, '0'))} AND #{quote(finish.ljust(max, 'Z'))}"
            else
              conditions << "#{table_name}.number LIKE #{quote(expr + '%%')}"
            end
          end

          if conditions.empty?
            connection.quoted_false
          else
            '(' + conditions.join(' OR ') + ')'
          end
        end
      end
    end
  end
end