require 'test_helper'

module Backend
  class GeoreadingsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions new: { nature: :polygon }
  end
end
