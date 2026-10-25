require 'test_helper'

class HveScoringTableTest < ActiveSupport::TestCase
  def setup
    @table = HveScoringTable.create!(
      filiere: 'gc', region: 'Île-de-France', ift_type: 'herbicide',
      pc: 1.5, pf: 2.5
    )
  end

  test 'score_for returns 5 when IFT is at or below the plancher (Pc)' do
    assert_equal 5, @table.score_for(1.0)
    assert_equal 5, @table.score_for(1.5)
  end

  test 'score_for returns 0 when IFT reaches the plafond (Pf) or exceeds it' do
    assert_equal 0, @table.score_for(2.5)
    assert_equal 0, @table.score_for(3.5)
  end

  test 'score_for decreases linearly across the (Pf - Pc) span' do
    # Pc=1.5, Pf=2.5, span=1.0, step=0.25 → mid-band IFT=2.0 → score=3
    assert_equal 3, @table.score_for(2.0)
    # IFT=1.8 (0.3 above Pc) → step floor((1.8-1.5)/0.25)=1, score=5-1=4
    assert_equal 4, @table.score_for(1.8)
  end

  test 'score_for returns nil when Pc or Pf are missing' do
    incomplete = HveScoringTable.new(filiere: 'gc', region: 'X', ift_type: 'herbicide')
    assert_nil incomplete.score_for(1.0)
  end
end
