require 'test_helper'
class Backend::Calculators::NitrogenInputsControllerTest < ActionController::TestCase
  test_restfully_all_actions show: :redirect, except: [:edit, :update]
end
