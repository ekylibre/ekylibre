module Ekylibre
  module Testing
    module Bookkeep
      class Entry
        attr_reader :debits, :credits

        def initialize(journal)
          @debits = []
          @credits = []
          @journal = journal
        end

        def add_debit(*args)
          debits << args
        end

        def add_credit(*args)
          credits << args
        end
      end
    end
  end
end
