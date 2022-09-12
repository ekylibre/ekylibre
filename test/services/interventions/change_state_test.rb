require 'test_helper'

module Interventions
  class ChangeStateTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    setup do
      @intervention = create(:intervention, :request)
      @user = User.first
    end

    test 'Return nil if intervention is request has recorded intervention' do
      @intervention.record_interventions << create(:intervention, nature: :record)
      intervention = Interventions::ChangeState.call(intervention: @intervention, new_state: :record)
      assert(intervention.nil?)
    end

    test 'If intervention is a record and new state is rejected and there is option for delete_option: It deletes both interventions' do
      intervention_record = create(:intervention, nature: :record)
      @intervention.record_interventions << intervention_record
      intervention = Interventions::ChangeState.call(intervention: intervention_record, new_state: :rejected, delete_option: :delete_request)
      refute(Intervention.find_by_id(intervention_record.id))
      refute(Intervention.find_by_id(@intervention.id))
    end

    test 'If intervention is a record and new state is rejected and there is no option for delete_option: intervention request take record parameters' do
      intervention_record = create(:intervention, nature: :record)
      @intervention.record_interventions << intervention_record
      intervention = Interventions::ChangeState.call(intervention: intervention_record, new_state: :rejected)
      assert_equal(intervention_record.parameters, @intervention.parameters)
    end

    test 'If intervention is a request and new state is rejected: It changes state' do
      intervention = Interventions::ChangeState.call(intervention: @intervention, new_state: :rejected)
      assert(@intervention.reload.rejected?)
    end

    test 'If intervention is a request and new state is validated, it sets the validator and change state' do
      intervention = Interventions::ChangeState.call(intervention: @intervention, new_state: :validated, validator: @user)
      record_intervention = @intervention.reload.record_interventions.first
      assert(record_intervention.validated?)
      assert_equal( @user.id, record_intervention.validator.id)
    end

    test 'If intervention is a request, it duplicates intervention and sets state and sets nature to reccord' do
      intervention = Interventions::ChangeState.call(intervention: @intervention, new_state: :validated, validator: @user)
      record_intervention = @intervention.reload.record_interventions.first
      assert(record_intervention.validated?)
      assert(record_intervention.record?)
      assert_equal(@user.id, record_intervention.validator.id)
      assert_equal(@intervention.id, record_intervention.request_intervention_id)
    end

  end
end
