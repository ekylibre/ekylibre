require 'test_helper'
module Backend
  class OutgoingPaymentListsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate the #export_to_sepa test
    test_restfully_all_actions except: %i[export_to_sepa generate_document generate_report find_open_document_template archive_report generate_report_file]
  end
end
