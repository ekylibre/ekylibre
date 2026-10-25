require 'test_helper'

class HveBiodiversityItemTest < ActiveSupport::TestCase
  def setup
    @campaign = Campaign.find_or_create_by!(harvest_year: 2099)
    @audit = HveAudit.create!(
      campaign_id: @campaign.id,
      referentiel_version: 'V4.4',
      status: 'draft'
    )
    HveIaeCoefficient.create!(iae_family: 'ligneux', iae_type: 'haie', unit: 'm', coefficient: 0.001)
    HveIaeCoefficient.create!(iae_family: 'aquatique', iae_type: 'mare', unit: 'ha', coefficient: 1.5)
  end

  test 'auto-resolves coefficient and computes equivalent for linear haie' do
    item = HveBiodiversityItem.create!(
      audit: @audit, iae_family: 'ligneux', iae_type: 'haie',
      surface_or_length: 2_000, unit: 'm'
    )
    assert_equal 0.001, item.coefficient.to_f
    # 2 000 m × 0.001 = 2 ha-équivalent
    assert_in_delta 2.0, item.equivalent_iae_ha.to_f, 0.001
  end

  test 'auto-resolves coefficient and computes equivalent for hectare mare' do
    item = HveBiodiversityItem.create!(
      audit: @audit, iae_family: 'aquatique', iae_type: 'mare',
      surface_or_length: 0.5, unit: 'ha'
    )
    assert_equal 1.5, item.coefficient.to_f
    # 0.5 ha × 1.5 = 0.75 ha-équivalent
    assert_in_delta 0.75, item.equivalent_iae_ha.to_f, 0.001
  end

  test 'explicit coefficient overrides the lookup' do
    item = HveBiodiversityItem.create!(
      audit: @audit, iae_family: 'ligneux', iae_type: 'haie',
      surface_or_length: 1_000, unit: 'm', coefficient: 0.005
    )
    assert_equal 0.005, item.coefficient.to_f
    assert_in_delta 5.0, item.equivalent_iae_ha.to_f, 0.001
  end

  test 'equivalent is nil when no matching coefficient exists' do
    item = HveBiodiversityItem.create!(
      audit: @audit, iae_family: 'rocheux', iae_type: 'unknown_type',
      surface_or_length: 100, unit: 'm'
    )
    assert_nil item.coefficient
    assert_nil item.equivalent_iae_ha
  end

  test 'rejects non-positive surface_or_length' do
    item = HveBiodiversityItem.new(
      audit: @audit, iae_family: 'ligneux', iae_type: 'haie',
      surface_or_length: 0, unit: 'm'
    )
    refute item.valid?
    assert item.errors[:surface_or_length].any?
  end
end
