require 'test_helper'

class PhytosanitaryRegisterFieldsTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'intervention early_reentry requires ppe description when true' do
    intervention = Intervention.new(early_reentry: true)
    intervention.valid?
    refute_empty intervention.errors[:early_reentry_ppe_description]
  end

  test 'intervention early_reentry allows blank ppe description when false' do
    intervention = Intervention.new(early_reentry: false)
    intervention.valid?
    assert_empty intervention.errors[:early_reentry_ppe_description]
  end

  test 'intervention beneficiary_siret accepts 14 digits' do
    intervention = Intervention.new(beneficiary_siret: '12345678901234')
    intervention.valid?
    assert_empty intervention.errors[:beneficiary_siret]
  end

  test 'intervention beneficiary_siret rejects non-14-digit values' do
    intervention = Intervention.new(beneficiary_siret: '12345')
    intervention.valid?
    assert_not_empty intervention.errors[:beneficiary_siret]
  end

  test 'intervention beneficiary_siret allows blank' do
    intervention = Intervention.new(beneficiary_siret: '')
    intervention.valid?
    assert_empty intervention.errors[:beneficiary_siret]
  end

  test 'intervention target phenological_bbch_stage accepts values in 0..99' do
    [0, 50, 99].each do |stage|
      target = InterventionTarget.new(phenological_bbch_stage: stage)
      target.valid?
      assert_empty target.errors[:phenological_bbch_stage], "BBCH stage #{stage} should be valid"
    end
  end

  test 'intervention target phenological_bbch_stage rejects values outside 0..99' do
    [-1, 100, 150].each do |stage|
      target = InterventionTarget.new(phenological_bbch_stage: stage)
      target.valid?
      assert_not_empty target.errors[:phenological_bbch_stage], "BBCH stage #{stage} should be invalid"
    end
  end

  test 'intervention target phenological_bbch_stage allows nil' do
    target = InterventionTarget.new(phenological_bbch_stage: nil)
    target.valid?
    assert_empty target.errors[:phenological_bbch_stage]
  end

  test 'intervention input application_mode accepts known values' do
    InterventionInput::APPLICATION_MODES.each do |mode|
      input = InterventionInput.new(application_mode: mode)
      assert_equal mode.to_s, input.application_mode
    end
  end

  test 'intervention input application_mode rejects unknown values' do
    input = InterventionInput.new
    input.application_mode = 'unknown_mode'
    assert_nil input.application_mode
  end

  test 'worker certiphyto_valid_at? returns true when number set and not expired' do
    worker = products(:workers_001)
    worker.certiphyto_number = 'CP-12345'
    worker.certiphyto_expires_on = Date.today + 1.year
    assert worker.certiphyto_valid_at?(Date.today)
  end

  test 'worker certiphyto_valid_at? returns false when expired' do
    worker = products(:workers_001)
    worker.certiphyto_number = 'CP-12345'
    worker.certiphyto_expires_on = Date.today - 1.day
    refute worker.certiphyto_valid_at?(Date.today)
  end

  test 'worker certiphyto_valid_at? returns false when number missing' do
    worker = products(:workers_001)
    worker.certiphyto_number = nil
    worker.certiphyto_expires_on = Date.today + 1.year
    refute worker.certiphyto_valid_at?(Date.today)
  end

  test 'worker requires certiphyto_expires_on when certiphyto_number is set' do
    worker = products(:workers_001)
    worker.certiphyto_number = 'CP-12345'
    worker.certiphyto_expires_on = nil
    worker.valid?
    refute_empty worker.errors[:certiphyto_expires_on]
  end
end
