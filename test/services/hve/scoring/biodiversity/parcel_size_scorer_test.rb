require 'test_helper'

class Hve::Scoring::Biodiversity::ParcelSizeScorerTest < ActiveSupport::TestCase
  class FakeSau
    attr_accessor :small_or_grassland_share, :total_sau_ha, :small_parcels_ha, :permanent_grassland_ha
    def initialize(share:, total: 100, small: 0, grassland: 0)
      @small_or_grassland_share = share
      @total_sau_ha = total
      @small_parcels_ha = small
      @permanent_grassland_ha = grassland
    end
  end

  def setup
    @campaign = Campaign.find_or_create_by!(harvest_year: 2099)
    @audit = HveAudit.create!(campaign: @campaign, referentiel_version: 'V4.4', status: 'draft')
  end

  test 'below 40% scores 0' do
    r = Hve::Scoring::Biodiversity::ParcelSizeScorer.new(audit: @audit, sau: FakeSau.new(share: 30)).call
    assert_equal 0, r[:points]
  end

  test '60% scores 3' do
    r = Hve::Scoring::Biodiversity::ParcelSizeScorer.new(audit: @audit, sau: FakeSau.new(share: 65)).call
    assert_equal 3, r[:points]
  end

  test '80%+ scores 5 (cap)' do
    r = Hve::Scoring::Biodiversity::ParcelSizeScorer.new(audit: @audit, sau: FakeSau.new(share: 92)).call
    assert_equal 5, r[:points]
  end
end
