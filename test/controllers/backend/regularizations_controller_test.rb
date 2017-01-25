require 'test_helper'
module Backend
  class RegularizationsControllerTest < ActionController::TestCase
    test_restfully_all_actions(
      create: { journal_entry_id: 7, affair_id: 15, redirect: '/backend/purchases/52' },
      show: :redirected_get
    )
  end
end
