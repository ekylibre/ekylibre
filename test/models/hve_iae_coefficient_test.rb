require 'test_helper'

class HveIaeCoefficientTest < ActiveSupport::TestCase
  test 'find_for returns the matching row' do
    HveIaeCoefficient.create!(iae_family: 'ligneux', iae_type: 'haie', unit: 'm', coefficient: 0.001)
    row = HveIaeCoefficient.find_for(family: 'ligneux', type: 'haie', unit: 'm')
    assert_equal 0.001, row.coefficient.to_f
  end

  test 'find_for returns nil when no match' do
    assert_nil HveIaeCoefficient.find_for(family: 'aquatique', type: 'mare', unit: 'ha')
  end

  test 'uniqueness on family + type + unit' do
    HveIaeCoefficient.create!(iae_family: 'herbager', iae_type: 'bande_enherbee', unit: 'm', coefficient: 0.0009)
    dup = HveIaeCoefficient.new(iae_family: 'herbager', iae_type: 'bande_enherbee', unit: 'm', coefficient: 0.0010)
    refute dup.valid?
    assert dup.errors[:iae_family].any?
  end

  test 'rejects an unknown family' do
    row = HveIaeCoefficient.new(iae_family: 'spatial', iae_type: 'x', unit: 'ha', coefficient: 1.0)
    refute row.valid?
    assert row.errors[:iae_family].any?
  end
end
