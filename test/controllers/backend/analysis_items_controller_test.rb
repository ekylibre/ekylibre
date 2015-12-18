require 'test_helper'
module Backend
  class AnalysisItemsControllerTest < ActionController::TestCase
    test_restfully_all_actions new: { mode: :index_xhr, params: { indicator_name: 'net_mass' } }
  end
end
