require 'test_helper'
module Backend
  class PreferencesControllerTest < ActionController::TestCase
    test_restfully_all_actions only: []

    test 'update' do
      patch :update, id: User::PREFERENCE_SHOW_MAP_INTERVENTION_FORM, value: 'true'
      assert_equal TrueClass, @user.preference(User::PREFERENCE_SHOW_MAP_INTERVENTION_FORM).value.class, 'Preference should be true'

      patch :update, id: User::PREFERENCE_SHOW_MAP_INTERVENTION_FORM, value: 'false'
      assert_equal FalseClass, @user.preference(User::PREFERENCE_SHOW_MAP_INTERVENTION_FORM).value.class, 'Preference should be false'
    end
  end
end
