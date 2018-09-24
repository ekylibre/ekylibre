require 'test_helper'

module Backend
  class NamingFormatsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: %i[create update destroy show]
  end
end
