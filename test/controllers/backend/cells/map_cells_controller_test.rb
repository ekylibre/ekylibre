require 'test_helper'
class Backend::Cells::MapCellsControllerTest < ActionController::TestCase
  test_restfully_all_actions except: :update
end
