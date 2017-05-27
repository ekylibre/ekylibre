require 'test_helper'
module Backend
  class PurchaseAffairsControllerTest < ActionController::TestCase
    test_restfully_all_actions do |o|
      o.select mode: :show,    params: { third_id: identify(:entities_001), deal_type: 'purchase' }
      o.attach mode: :touch,   params: { deal_id:  identify(:purchases_001), deal_type: 'purchase' }
      o.detach mode: :destroy, params: { deal_id:  6, deal_type: 'purchase', id: 15 }
      o.finish id: 16
    end

    test 'should not attach invalid deal' do
      affair = affairs(:purchase_affairs_001)
      assert affair.valid?, 'PurchaseAffair 001 must be valid'
      post :attach, id: affair.id
      assert (flash['notifications'] && flash['notifications']['error'].any?), "Error expected with no given deal (got #{flash.inspect})"
    end

    test 'should not detach invalid deal' do
      affair = affairs(:purchase_affairs_001)
      assert affair.valid?, 'PurchaseAffair 001 must be valid'
      post :detach, id: affair.id
      assert (flash['notifications'] && flash['notifications']['error'].any?), "Error expected with no given deal (got #{flash.inspect})"
    end
  end
end
