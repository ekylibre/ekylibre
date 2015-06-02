require 'test_helper'
class Backend::AnalysisItemsControllerTest < ActionController::TestCase
  test_restfully_all_actions new: {mode: :index_xhr, params: {indicator_name: "net_mass"}}
end
