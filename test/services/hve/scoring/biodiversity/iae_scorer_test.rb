require 'test_helper'

class Hve::Scoring::Biodiversity::IaeScorerTest < ActiveSupport::TestCase
  class FakeSau
    attr_accessor :arable_ha
    def initialize(arable_ha:); @arable_ha = arable_ha; end
  end

  def setup
    @campaign = Campaign.find_or_create_by!(harvest_year: 2099)
    @audit = HveAudit.create!(campaign: @campaign, referentiel_version: 'V4.4', status: 'draft')
  end

  test 'gate flag when no biodiversity_items' do
    result = Hve::Scoring::Biodiversity::IaeScorer.new(audit: @audit, sau: FakeSau.new(arable_ha: 100)).call
    assert_equal '4.1', result[:code]
    assert_equal 0,     result[:points]
    assert_equal 'iae_inventory_missing', result[:evidence][:gate]
  end

  test 'linear ratio scoring without family bonus' do
    HveIaeCoefficient.find_or_create_by!(iae_family: 'ligneux', iae_type: 'haie', unit: 'm') { |c| c.coefficient = 0.001 }
    HveBiodiversityItem.create!(audit: @audit, iae_family: 'ligneux', iae_type: 'haie',
                                 surface_or_length: 7_000, unit: 'm')  # 7 ha-équivalent
    result = Hve::Scoring::Biodiversity::IaeScorer.new(audit: @audit, sau: FakeSau.new(arable_ha: 100)).call
    assert_equal 7.0, result[:value_raw].to_f         # 7 % ratio
    assert_equal 4,   result[:points]                  # ratio 7 % → 4 pts
    assert_equal 0,   result[:evidence][:families_bonus]
  end

  test 'family bonus when 3 distinct families' do
    %w[ligneux herbager aquatique].each_with_index do |fam, i|
      HveIaeCoefficient.find_or_create_by!(iae_family: fam, iae_type: "type#{i}", unit: 'ha') { |c| c.coefficient = 1.0 }
      HveBiodiversityItem.create!(audit: @audit, iae_family: fam, iae_type: "type#{i}",
                                   surface_or_length: 3.0, unit: 'ha')  # 3 ha-équivalent each
    end
    # total IAE = 9 ha, arable = 100 → ratio 9 % → 6 pts + 2 bonus = 8 pts
    result = Hve::Scoring::Biodiversity::IaeScorer.new(audit: @audit, sau: FakeSau.new(arable_ha: 100)).call
    assert_equal 9.0, result[:value_raw].to_f
    assert_equal 8,   result[:points]
    assert_equal 2,   result[:evidence][:families_bonus]
    assert_equal 3,   result[:evidence][:families_present].size
  end

  test 'caps to 7 + 2 bonus at very high ratio' do
    HveIaeCoefficient.find_or_create_by!(iae_family: 'ligneux',   iae_type: 'haie',  unit: 'ha') { |c| c.coefficient = 1.0 }
    HveIaeCoefficient.find_or_create_by!(iae_family: 'herbager',  iae_type: 'bande', unit: 'ha') { |c| c.coefficient = 1.0 }
    HveIaeCoefficient.find_or_create_by!(iae_family: 'aquatique', iae_type: 'mare',  unit: 'ha') { |c| c.coefficient = 1.0 }
    %w[ligneux herbager aquatique].each do |fam|
      HveBiodiversityItem.create!(audit: @audit, iae_family: fam, iae_type: fam == 'ligneux' ? 'haie' : (fam == 'herbager' ? 'bande' : 'mare'),
                                   surface_or_length: 10.0, unit: 'ha')  # 30 ha total
    end
    # ratio 30 % → 7 pts + 2 bonus
    result = Hve::Scoring::Biodiversity::IaeScorer.new(audit: @audit, sau: FakeSau.new(arable_ha: 100)).call
    assert_equal 9, result[:points]
  end
end
