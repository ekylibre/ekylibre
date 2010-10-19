require 'test_helper'

class RelationsControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions :custom_field_sort=>:delete, :except=>[:change_minutes]
end
