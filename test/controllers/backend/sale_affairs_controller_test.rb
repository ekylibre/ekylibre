require 'test_helper'
module Backend
  class SaleAffairsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #detach_gaps and #select tests
    test_restfully_all_actions except: %i[detach_gaps select finish] do |o|
      o.select mode: :show, params: { third_id: identify(:entities_001), deal_type: 'sale' }
      o.attach mode: :touch, params: { deal_id: identify(:sales_001), deal_type: 'sale' }
      o.detach mode: :destroy, params: { deal_id: 6, deal_type: 'purchase', id: 15 }
    end

    test 'finish action in touch' do
      Timecop.travel(DateTime.parse('2018-01-01T00:00:00Z')) do
        post :finish, { id: 20, locale: @locale }
        sale_affair = affairs(:sale_affairs_001)
        post :finish, { id: 20, locale: @locale }
        assert_response :redirect, show_context
      end
    end

    test 'should not attach invalid deal' do
      affair = affairs(:sale_affairs_001)
      assert affair.valid?, 'SaleAffair 001 must be valid'
      post :attach, params: { id: affair.id }
      assert (flash['notifications'] && flash['notifications']['error'].any?), "Error expected with no given deal (got #{flash.inspect})"
    end

    test 'should not detach invalid deal' do
      affair = affairs(:sale_affairs_001)
      assert affair.valid?, 'SaleAffair 001 must be valid'
      post :detach, params: { id: affair.id }
      assert (flash['notifications'] && flash['notifications']['error'].any?), "Error expected with no given deal (got #{flash.inspect})"
    end
  end
end
