require 'test_helper'

module Backend
  class GeoreadingsControllerTest < ActionController::TestCase
    test_restfully_all_actions new: { nature: :polygon }
  end
end
