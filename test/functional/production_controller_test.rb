require 'test_helper'

class ProductionControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions(
                   :land_parcel_divide=>:update,
                   :production_chain_work_center_down=>:delete,
                   # :production_chain_work_center_play=>:delete,
                   :production_chain_work_center_up=>:delete,
                   :except=>[:operation_line_create, :operation_use_create]
                   )
end
