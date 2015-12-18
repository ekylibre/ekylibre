require 'test_helper'

module Backend
  class ImportsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: :run, progress: :show
  end
end
