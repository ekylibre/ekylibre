require 'test_helper'

class Hve::Scoring::Biodiversity::MainCropWeightScorerTest < ActiveSupport::TestCase
  class FakeSau
    attr_accessor :main_crop_share, :arable_ha
    def initialize(share:); @main_crop_share = share; @arable_ha = 100; end
  end

  def setup
    @campaign = Campaign.find_or_create_by!(harvest_year: 2099)
    @audit = HveAudit.create!(campaign: @campaign, referentiel_version: 'V4.4', status: 'draft')
  end

  test '≥60% scores 0 (monoculture)' do
    assert_equal 0, score_for(75)
  end

  test '40-49% scores 2' do
    assert_equal 2, score_for(45)
  end

  test '20-29% scores 4' do
    assert_equal 4, score_for(25)
  end

  test '<20% scores 5 (full diversity)' do
    assert_equal 5, score_for(15)
  end

  private

    def score_for(share)
      Hve::Scoring::Biodiversity::MainCropWeightScorer
        .new(audit: @audit, sau: FakeSau.new(share: share)).call[:points]
    end
end
