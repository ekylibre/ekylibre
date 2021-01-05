require 'test_helper'
module Backend
  class InspectionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #show test
    test_restfully_all_actions new: { params: { activity_id: 1 } }, except: %i[create export show]

    test 'export to ODS' do
      get :export, params: { id: Inspection.pluck(:id).join(','), format: :ods }
    end
  end
end
