require 'test_helper'
module Backend
  class CompaniesControllerTest < ActionController::TestCase
    # TODO: Re-activate #edit and #update tests
    test_restfully_all_actions class_name: 'Entity', except: %i[edit update]
  end
end
