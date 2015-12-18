require 'test_helper'
module Pasteque
  module V5
    class TicketsControllerTest < ActionController::TestCase
      test_restfully_pasteque_actions class_name: 'Affair'
    end
  end
end
