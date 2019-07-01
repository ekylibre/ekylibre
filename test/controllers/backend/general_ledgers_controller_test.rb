require 'test_helper'
module Backend
  class GeneralLedgersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions show: :index, list_journal_entry_items: :list
  end
end
