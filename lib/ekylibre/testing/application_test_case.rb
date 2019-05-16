module Ekylibre
  module Testing
    class ApplicationTestCase < ActiveSupport::TestCase
      include FactoryBot::Syntax::Methods
      include Ekylibre::Testing::Concerns::FixturesCleanerModule

      class WithFixtures < ActiveSupport::TestCase
        include FactoryBot::Syntax::Methods
        include Ekylibre::Testing::Concerns::FixturesModule
        include Ekylibre::Testing::Concerns::ModelActionTestModule
      end
    end
  end
end
