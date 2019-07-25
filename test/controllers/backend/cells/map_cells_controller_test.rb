require 'test_helper'
module Backend
  module Cells
    class MapCellsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions except: :update
    end
  end
end
