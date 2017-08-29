require 'test_helper'
# require 'active_job/test_helper'
module Backend
  class ExportsControllerTest < ActionController::TestCase
    include ActiveJob::TestHelper
    test 'Show with pdf Should create a job' do
      sign_in_user
      request.env['HTTP_REFERER'] = 'http://test.com/sessions/new'
      get :show, id: 'fr_pcg82_balance_sheet', format: 'pdf'
      assert_enqueued_jobs 1
      assert_response :redirect
    end

    test 'Show with option to show preview to true should respond with success' do
      sign_in_user
      set_pref(true)
      get :show, id: 'fr_pcg82_balance_sheet'
      assert_response :success
    end

    test 'Show with option to show preview to false should respond with success' do
      sign_in_user
      set_pref(false)
      get :show, id: 'fr_pcg82_balance_sheet'
      assert_response :success
    end

    def sign_in_user
      @user = create(:user)
      sign_in(@user)
    end

    def set_pref(value)
      pref = @user.preferences.find_or_initialize_by(name: 'show_export_preview')
      pref.boolean_value = value
      pref.nature = :boolean
      pref.save
    end
  end
end
