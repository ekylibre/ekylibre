require 'test_helper'

class HveNitrogenExportCoefficientTest < ActiveSupport::TestCase
  test 'exported returns kg N for a fresh-matter coefficient' do
    HveNitrogenExportCoefficient.create!(
      crop_reference: 'wheat', organ: 'grain',
      ms_pct: 85, n_kg_per_t: 22.0, unit: 'fresh_matter'
    )
    # 5 t fresh matter × 22 kg N/t = 110 kg N
    assert_in_delta 110.0, HveNitrogenExportCoefficient.exported(crop_reference: 'wheat', organ: 'grain', yield_tonnes: 5), 0.001
  end

  test 'exported applies MS conversion for dry-matter coefficients' do
    HveNitrogenExportCoefficient.create!(
      crop_reference: 'alfalfa', organ: 'hay',
      ms_pct: 85, n_kg_per_t: 30.0, unit: 'dry_matter'
    )
    # 10 t fresh × 85% MS × 30 kg N/t MS = 255 kg N
    assert_in_delta 255.0, HveNitrogenExportCoefficient.exported(crop_reference: 'alfalfa', organ: 'hay', yield_tonnes: 10), 0.001
  end

  test 'exported returns 0 when crop/organ is missing' do
    assert_equal 0.0, HveNitrogenExportCoefficient.exported(crop_reference: 'unknown', organ: 'grain', yield_tonnes: 100)
  end

  test 'exported returns 0 when yield is zero' do
    assert_equal 0.0, HveNitrogenExportCoefficient.exported(crop_reference: 'wheat', organ: 'grain', yield_tonnes: 0)
  end
end
