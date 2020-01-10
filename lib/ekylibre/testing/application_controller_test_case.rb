module Ekylibre
  module Testing
    class ApplicationControllerTestCase < ActionController::TestCase
      include FactoryBot::Syntax::Methods
      include Ekylibre::Testing::Concerns::FixturesCleanerModule

      class WithFixtures < ActionController::TestCase
        include FactoryBot::Syntax::Methods
        include Ekylibre::Testing::Concerns::FixturesModule
        include Ekylibre::Testing::Concerns::ModelActionTestModule
      end
    end
  end
end