module Ekylibre
  module Testing
    class BookkeeperTestCase < ApplicationTestCase::WithFixtures
      attr_reader :bookkeeper

      private

        def bookkeep(resource)
          initialize_bookkeeper(resource)
          bookkeeper.call
        end

        def initialize_bookkeeper(resource)
          @recorder = Bookkeep::Recorder.new(resource)
          bookkeeper_klass = self.class.name.gsub(/Test$/, '').constantize
          @bookkeeper = bookkeeper_klass.new(@recorder)
        end

        def entries_bookkeeped
          @recorder.entries
        end
    end
  end
end
