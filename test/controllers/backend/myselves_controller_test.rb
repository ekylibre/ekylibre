require 'test_helper'

module Backend
  class MyselvesControllerTest < ActionController::TestCase
    test_restfully_all_actions show: :index, except: [:update, :change_password]
  end
end
