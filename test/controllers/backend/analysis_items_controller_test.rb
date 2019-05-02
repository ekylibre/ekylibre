require 'test_helper'
module Backend
  class AnalysisItemsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions new: { mode: :index_xhr, params: { indicator_name: 'net_mass' } }
  end
end
