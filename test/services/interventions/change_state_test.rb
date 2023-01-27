require 'test_helper'

module Interventions
  class ChangeStateTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    setup do
      @intervention_request = create(:intervention, :request)
      @intervention_record = create(:intervention, nature: :record)
      @user = User.first
    end

    test 'If intervention is request and has associated intervention record: It returns nil ' do
      @intervention_request.record_interventions << create(:intervention, nature: :record)
      intervention = Interventions::ChangeState.call(intervention: @intervention_request, new_state: :record)
      assert(intervention.nil?)
    end

    test 'If intervention is a record and new state is rejected and there is option for delete_option: It deletes both interventions' do
      intervention_record = create(:intervention, nature: :record)
      @intervention_request.record_interventions << intervention_record
      intervention = Interventions::ChangeState.call(intervention: intervention_record, new_state: :rejected, delete_option: :delete_request)
      refute(Intervention.find_by_id(intervention_record.id))
      refute(Intervention.find_by_id(@intervention_request.id))
    end

    test 'If intervention is a record and new state is rejected and there is no option for delete_option: intervention request take record parameters' do
      intervention_record = create(:intervention, nature: :record)
      @intervention_request.record_interventions << intervention_record
      intervention = Interventions::ChangeState.call(intervention: intervention_record, new_state: :rejected)
      assert_equal(intervention_record.parameters, @intervention_request.parameters)
      refute(Intervention.find_by_id(intervention_record.id))
    end

    test 'If intervention is a request and new state is rejected: It changes state' do
      intervention = Interventions::ChangeState.call(intervention: @intervention_request, new_state: :rejected)
      assert(@intervention_request.reload.rejected?)
    end

    test 'If intervention is a request, it duplicates intervention, sets state and sets nature to reccord' do
      intervention = Interventions::ChangeState.call(intervention: @intervention_request, new_state: :validated, validator: @user)
      record_intervention = @intervention_request.reload.record_interventions.first
      assert(record_intervention.validated?)
      assert(record_intervention.record?)
      assert_equal(@user.id, record_intervention.validator.id)
      assert_equal(@intervention_request.id, record_intervention.request_intervention_id)
      assert_equal(record_intervention.id, intervention.id)
    end

    test 'If intervention is a record and new state is validated, it sets the validator and change state' do
      intervention = Interventions::ChangeState.call(intervention: @intervention_record, new_state: :validated, validator: @user)
      updated_intervention =  @intervention_record.reload
      assert(updated_intervention.validated?)
      assert_equal(@user.id, updated_intervention.validator.id)
      assert_equal(updated_intervention.id, intervention.id)
    end
  end
end
