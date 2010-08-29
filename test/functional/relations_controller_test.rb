require 'test_helper'

class RelationsControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions :custom_field_sort=>:delete, :custom_field_choice_up=>:delete, :custom_field_choice_down=>:delete, :except=>[:change_minutes]
end
