# frozen_string_literal: true

module Ekylibre
  module Record
    module Bookkeep
      class EntryRecorder
        attr_reader :list

        def initialize
          @list = []
        end

        def add_debit(*args)
          @list << [:add_debit, *args]
        end

        def add_credit(*args)
          @list << [:add_credit, *args]
        end
      end
    end
  end
end
