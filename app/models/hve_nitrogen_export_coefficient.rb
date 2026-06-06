# Per-crop nitrogen export coefficients used by the BGA (Bilan Global
# Azoté) computation tool. Source: Comifer 2013 + technical institutes,
# distributed via Exportations_azote_productions_vegetales_5.pdf.
class HveNitrogenExportCoefficient < ApplicationRecord
  UNITS = %w[fresh_matter dry_matter].freeze

  validates :crop_reference, :organ, presence: true
  validates :n_kg_per_t, presence: true
  validates :unit, inclusion: { in: UNITS }
  validates :crop_reference, uniqueness: { scope: :organ }

  scope :for_crop, ->(reference) { where(crop_reference: reference.to_s) }

  # Returns the nitrogen exported (in kg N) for a given crop, organ and
  # yield (t). Yield is expected in tonnes of fresh matter; conversion
  # to dry matter applied automatically when the coefficient is per dry
  # matter tonne.
  def self.exported(crop_reference:, organ:, yield_tonnes:)
    return 0.0 if yield_tonnes.to_f.zero?
    row = for_crop(crop_reference).where(organ: organ.to_s).take
    return 0.0 unless row
    tonnes = yield_tonnes.to_f
    tonnes *= (row.ms_pct.to_f / 100.0) if row.unit == 'dry_matter' && row.ms_pct
    tonnes * row.n_kg_per_t.to_f
  end
end
