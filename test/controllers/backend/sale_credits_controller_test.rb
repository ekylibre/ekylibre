require 'test_helper'
class Backend::SaleCreditsControllerTest < ActionController::TestCase
  test_restfully_all_actions new: { credited_sale_id: identify(:sales_001), redirect: '/backend/sales' }, except: :create, fixture_options: { prefix: :sales }
end
