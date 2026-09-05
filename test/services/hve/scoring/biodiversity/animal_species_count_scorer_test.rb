require 'test_helper'

class Hve::Scoring::Biodiversity::AnimalSpeciesCountScorerTest < ActiveSupport::TestCase
  class FakeSau
    attr_reader :animal_species_count
    def initialize(count:); @animal_species_count = count; end
  end

  def setup
    @campaign = Campaign.find_or_create_by!(harvest_year: 2099)
    @audit = HveAudit.create!(campaign: @campaign, referentiel_version: 'V4.4', status: 'draft')
  end

  test '0 species → 0 pts' do
    assert_equal 0, score_for(0)
  end

  test '1 species → 0 pts' do
    assert_equal 0, score_for(1)
  end

  test '2 species → 1 pt' do
    assert_equal 1, score_for(2)
  end

  test '3 species → 2 pts' do
    assert_equal 2, score_for(3)
  end

  test '4+ species → 3 pts (cap)' do
    assert_equal 3, score_for(4)
    assert_equal 3, score_for(7)
  end

  private

    def score_for(n)
      Hve::Scoring::Biodiversity::AnimalSpeciesCountScorer
        .new(audit: @audit, sau: FakeSau.new(count: n)).call[:points]
    end
end
