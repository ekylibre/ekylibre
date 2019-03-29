require 'test_helper'
module Backend
  class InspectionsControllerTest < ActionController::TestCase
    # TODO: Re-activate #show test
    test_restfully_all_actions new: { params: { activity_id: 1 } }, except: %i[create export show]

    test 'export to ODS' do
      get :export, id: Inspection.pluck(:id).join(','), format: :ods
    end
  end
end
