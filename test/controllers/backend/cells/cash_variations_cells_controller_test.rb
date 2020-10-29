require 'test_helper'
module Backend
  module Cells
    class CashVariationsCellsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions only: :show
    end
  end
end
