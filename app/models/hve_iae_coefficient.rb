# Vendored reference table for IAE (Infrastructures Agro-Écologiques)
# conversion coefficients. The HVE3 V4.4 control plan (annex 1) lists,
# for each IAE type, how a linear (m) or area (ha) measurement converts
# to a "hectare-equivalent" used in criterion 4.1.
#
# Seeded from `db/seeds/hve_iae_coefficients.yml` shipped with the
# ekylibre-hve plugin; refreshed via `rake hve:reference:load`.
class HveIaeCoefficient < ApplicationRecord
  FAMILIES = %w[aquatique herbager ligneux rocheux].freeze
  UNITS    = %w[ha m].freeze

  validates :iae_family, inclusion: { in: FAMILIES }
  validates :iae_type,   presence: true
  validates :unit,       inclusion: { in: UNITS }
  validates :coefficient, presence: true
  validates :iae_family, uniqueness: { scope: %i[iae_type unit] }

  scope :for_family, ->(family) { where(iae_family: family) }

  # Returns the coefficient row matching (family, type, unit) — or nil.
  def self.find_for(family:, type:, unit:)
    where(iae_family: family, iae_type: type, unit: unit).limit(1).first
  end
end
