# frozen_string_literal: true

module Ekylibre
  module Utils
    module DateSoftParse
      refine ::DateTime.singleton_class do
        def soft_parse(*args, &block)
          DateTime.parse(*args, &block)
        rescue ArgumentError
          nil
        end
      end

      refine ::Date.singleton_class do
        def soft_parse(*args, &block)
          Date.parse(*args, &block)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
