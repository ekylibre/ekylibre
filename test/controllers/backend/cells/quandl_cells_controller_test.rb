require 'test_helper'
module Backend
  module Cells
    class QuandlCellsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      # TODO: Re-activate #show test
      test_restfully_all_actions except: :show
    end
  end
end
