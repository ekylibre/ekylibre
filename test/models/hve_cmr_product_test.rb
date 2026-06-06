require 'test_helper'

class HveCmrProductTest < ActiveSupport::TestCase
  test 'classify returns CMR class when AMM exists for the year' do
    HveCmrProduct.create!(amm_code: '9990001', cmr_class: 'CMR1', snapshot_year: 2025, product_name: 'Test CMR1')
    HveCmrProduct.create!(amm_code: '9990002', cmr_class: 'CMR2', snapshot_year: 2025, product_name: 'Test CMR2')

    assert_equal 'CMR1', HveCmrProduct.classify('9990001', year: 2025)
    assert_equal 'CMR2', HveCmrProduct.classify('9990002', year: 2025)
  end

  test 'classify returns nil when AMM is unknown' do
    assert_nil HveCmrProduct.classify('0000000', year: 2025)
  end

  test 'classify returns nil for blank AMM' do
    assert_nil HveCmrProduct.classify(nil)
    assert_nil HveCmrProduct.classify('')
  end

  test 'enforces uniqueness on (amm_code, snapshot_year)' do
    HveCmrProduct.create!(amm_code: '9990003', cmr_class: 'CMR2', snapshot_year: 2025)
    duplicate = HveCmrProduct.new(amm_code: '9990003', cmr_class: 'CMR1', snapshot_year: 2025)
    refute duplicate.valid?
    assert duplicate.errors[:amm_code].any?
  end
end
