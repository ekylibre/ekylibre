require 'test_helper'

class HveAuditItemTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  def audit
    @audit ||= HveAudit.create!(
      campaign_id: campaigns(:campaigns_001).id,
      referentiel_version: 'V4.4',
      status: 'draft'
    )
  end

  test 'value_used falls back to value_raw when no manual override' do
    item = HveAuditItem.create!(
      audit: audit, code: '4.1', theme: 'biodiversity',
      value_raw: 6.5, points: 3, points_max: 9, auto_computed: true
    )
    assert_equal 6.5, item.value_used.to_f
  end

  test 'value_used picks value_manual when present' do
    item = HveAuditItem.create!(
      audit: audit, code: '4.2', theme: 'biodiversity',
      value_raw: 6.5, value_manual: 7.0, points: 4, points_max: 5, auto_computed: false
    )
    assert_equal 7.0, item.value_used.to_f
  end

  test 'enforces uniqueness on (hve_audit_id, code)' do
    HveAuditItem.create!(audit: audit, code: '5.1', theme: 'phytosanitary', points: 2, points_max: 2)
    duplicate = HveAuditItem.new(audit: audit, code: '5.1', theme: 'phytosanitary')
    refute duplicate.valid?
    assert duplicate.errors[:code].any?
  end

  test 'rejects unknown theme' do
    item = HveAuditItem.new(audit: audit, code: '9.9', theme: 'climate')
    refute item.valid?
    assert item.errors[:theme].any?
  end
end
