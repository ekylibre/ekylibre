require 'test_helper'
module Pasteque
  module V5
    class CustomersControllerTest < ActionController::TestCase
      test_restfully_pasteque_actions class_name: 'Entity'
    end
  end
end
