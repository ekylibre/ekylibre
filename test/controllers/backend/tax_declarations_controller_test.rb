require 'test_helper'
module Backend
  class TaxDeclarationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[new generate_report generate_report_file generate_document archive_report find_open_document_template]
    # TODO: Add a #new test.
  end
end
