require 'test_helper'

class Backend::GeoreadingsControllerTest < ActionController::TestCase
  test_restfully_all_actions new: { nature: :polygon }
end
