require 'test_helper'
class Backend::SaleCreditsControllerTest < ActionController::TestCase
  test_restfully_all_actions new: { credited_sale_id: identify(:sales_001) }, index: :redirect, except: :create, fixture_options: {prefix: :sales}, show: :redirected_get
end
