require 'test_helper'
module Backend
  class TrialBalancesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: :show

    test 'with period' do
      get :show, params: { period: '2007-01-01_2015-12-31', states: %i[draft confirmed closed].map { |e| [e, "1"] }.to_h }
    end

    test 'export to ODS' do
      get :show, params: { period: '2007-01-01_2015-12-31', format: :ods }
    end
  end
end
