module Ekylibre
  module Testing
    module Bookkeep
      class Recorder
        attr_reader :resource, :entries

        def initialize(resource)
          @resource = resource
          @entries = []
        end

        def journal_entry(journal, options = {})
          return if (options.key?(:unless) && options[:unless])
          return if (options.key?(:if) && !options[:if])

          entry = Entry.new(journal: journal)
          yield entry
          @entries << entry
        end
      end
    end
  end
end