require 'test_helper'

class Hve::Scoring::Biodiversity::PlantSpeciesCountScorerTest < ActiveSupport::TestCase
  class FakeSau
    attr_accessor :plant_species_count, :main_crop_share
    def initialize(count:, main_share:)
      @plant_species_count = count
      @main_crop_share = main_share
    end
  end

  def setup
    @campaign = Campaign.find_or_create_by!(harvest_year: 2099)
    @audit = HveAudit.create!(campaign: @campaign, referentiel_version: 'V4.4', status: 'draft')
  end

  test '4 species, monoculture-heavy → 0 pts' do
    assert_equal 0, score_for(count: 4, share: 70)
  end

  test '6 species, monoculture-heavy → capped at 2 (max 5 in this case)' do
    assert_equal 2, score_for(count: 6, share: 70)
  end

  test '10 species, monoculture-heavy → cap 5' do
    assert_equal 5, score_for(count: 10, share: 70)
  end

  test '10 species, diversified → cap 6' do
    assert_equal 6, score_for(count: 10, share: 30)
  end

  test 'less than baseline never goes negative' do
    assert_equal 0, score_for(count: 2, share: 30)
  end

  private

    def score_for(count:, share:)
      Hve::Scoring::Biodiversity::PlantSpeciesCountScorer
        .new(audit: @audit, sau: FakeSau.new(count: count, main_share: share)).call[:points]
    end
end
