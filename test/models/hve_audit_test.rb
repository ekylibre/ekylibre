require 'test_helper'

class HveAuditTest < ActiveSupport::TestCase
  test 'recompute_verdict returns compliant when all scores meet threshold' do
    audit = HveAudit.new(
      campaign_id: campaigns(:current_campaign).id,
      referentiel_version: 'V4.4',
      status: 'draft',
      score_biodiversity: 12, score_phytosanitary: 15,
      score_fertilisation: 11, score_irrigation: 10,
      uses_cmr1_without_derogation: false
    )
    audit.recompute_verdict
    assert_equal 'compliant', audit.verdict
    assert audit.compliant?
  end

  test 'recompute_verdict returns non_compliant when any score is below threshold' do
    audit = HveAudit.new(
      campaign_id: campaigns(:current_campaign).id,
      referentiel_version: 'V4.4',
      status: 'draft',
      score_biodiversity: 9, score_phytosanitary: 15,
      score_fertilisation: 11, score_irrigation: 10,
      uses_cmr1_without_derogation: false
    )
    audit.recompute_verdict
    assert_equal 'non_compliant', audit.verdict
  end

  test 'recompute_verdict returns cmr1_blocked overriding scores' do
    audit = HveAudit.new(
      campaign_id: campaigns(:current_campaign).id,
      referentiel_version: 'V4.4',
      status: 'draft',
      score_biodiversity: 36, score_phytosanitary: 63,
      score_fertilisation: 53, score_irrigation: 34,
      uses_cmr1_without_derogation: true
    )
    audit.recompute_verdict
    assert_equal 'cmr1_blocked', audit.verdict
    refute audit.compliant?
  end

  test 'recompute_verdict returns non_compliant when scores are partial' do
    audit = HveAudit.new(
      campaign_id: campaigns(:current_campaign).id,
      referentiel_version: 'V4.4',
      status: 'draft',
      score_biodiversity: 12,
      score_phytosanitary: nil,
      score_fertilisation: nil,
      score_irrigation: nil,
      uses_cmr1_without_derogation: false
    )
    audit.recompute_verdict
    assert_equal 'non_compliant', audit.verdict
  end
end
