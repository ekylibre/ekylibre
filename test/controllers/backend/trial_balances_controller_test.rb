require 'test_helper'
module Backend
  class TrialBalancesControllerTest < ActionController::TestCase
    test_restfully_all_actions show: :index, except: %i[generate_report generate_report_file generate_document  archive_report find_open_document_template]

    test 'with period' do
      get :show, params: { period: '2007-01-01_2015-12-31', states: %i[draft confirmed closed] }
    end

    test 'export to ODS' do
      get :show, params: { period: '2007-01-01_2015-12-31', format: :ods }
    end
  end
end
