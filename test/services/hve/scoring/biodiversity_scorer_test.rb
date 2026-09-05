require 'test_helper'

class Hve::Scoring::BiodiversityScorerTest < ActiveSupport::TestCase
  def setup
    @campaign = Campaign.find_or_create_by!(harvest_year: 2099)
    @audit = HveAudit.create!(campaign: @campaign, referentiel_version: 'V4.4', status: 'draft')
    HveIaeCoefficient.find_or_create_by!(iae_family: 'ligneux', iae_type: 'haie', unit: 'm') { |c| c.coefficient = 0.001 }
  end

  test 'gate is closed when no biodiversity_items' do
    result = Hve::Scoring::BiodiversityScorer.call(audit: @audit)
    assert_equal 'closed', @audit.metadata['biodiversity_gate']
    assert_equal 0, result[:items].first[:points]    # IAE = 0
    assert_equal 8, @audit.items.count                # 8 items created
  end

  test 'idempotent — re-running produces same score' do
    HveBiodiversityItem.create!(audit: @audit, iae_family: 'ligneux', iae_type: 'haie',
                                 surface_or_length: 5_000, unit: 'm')
    first  = Hve::Scoring::BiodiversityScorer.call(audit: @audit)
    second = Hve::Scoring::BiodiversityScorer.call(audit: @audit)
    assert_equal first[:score], second[:score]
    assert_equal 8, @audit.items.count                # no duplicates
  end

  test 'preserves manual values across rerun' do
    item = @audit.items.create!(code: '4.6', theme: 'biodiversity', value_manual: 5, points: 0, points_max: 1, auto_computed: false)
    Hve::Scoring::BiodiversityScorer.call(audit: @audit)
    item.reload
    assert_equal 5, item.value_manual.to_i
    assert_equal 1, item.points.to_i  # 5 ruches → 1 pt
  end

  test 'score_biodiversity is updated on the audit' do
    HveBiodiversityItem.create!(audit: @audit, iae_family: 'ligneux', iae_type: 'haie',
                                 surface_or_length: 5_000, unit: 'm')
    Hve::Scoring::BiodiversityScorer.call(audit: @audit)
    @audit.reload
    refute_nil @audit.score_biodiversity
  end
end
