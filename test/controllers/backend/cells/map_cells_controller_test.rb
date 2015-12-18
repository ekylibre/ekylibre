require 'test_helper'
module Backend
  module Cells
    class MapCellsControllerTest < ActionController::TestCase
      test_restfully_all_actions except: :update
    end
  end
end
