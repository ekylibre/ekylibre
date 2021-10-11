require 'test_helper'
module Backend
  module Cells
    class PfiInterventionsCellsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions except: %i[compute_pfi_interventions compute_pfi_report]
    end
  end
end
