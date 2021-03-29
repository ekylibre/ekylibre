# frozen_string_literal: true

module Ekylibre
  module Utils
    module HashReverse
      refine ::Hash do
        def reverse
          self.flat_map { |key, values| values.map { |v| [v, key] } }
              .group_by(&:first)
              .map do |key, values|
                raise StandardError.new "Duplicate value for key #{key}: #{values.join(', ')}" if values.size > 1

                [key, values.first.second]
              end
              .to_h
        end
      end
    end
  end
end
