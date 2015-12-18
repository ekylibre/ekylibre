require 'test_helper'

module Backend
  class ActivitiesControllerTest < ActionController::TestCase
    test_restfully_all_actions family: { mode: :index, name: :mussel_farming, format: :json }
  end
end
