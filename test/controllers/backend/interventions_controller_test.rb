require 'test_helper'

class Backend::InterventionsControllerTest < ActionController::TestCase

  test_restfully_all_actions compute: :create, set: :show, except: :run

end

