# One physical element of the farm's IAE (Infrastructures Agro-
# Écologiques) inventory, attached to a single HveAudit. The set of
# items drives criterion 4.1 of the HVE3 audit (Biodiversité — IAE,
# gating criterion).
#
# `equivalent_iae_ha` is auto-computed from `surface_or_length` and
# `coefficient` on save. The coefficient is fetched from the vendored
# HveIaeCoefficient lookup unless the caller overrides it.
class HveBiodiversityItem < ApplicationRecord
  belongs_to :audit, class_name: 'HveAudit',
                     foreign_key: :hve_audit_id,
                     inverse_of: :biodiversity_items

  validates :iae_family, inclusion: { in: HveIaeCoefficient::FAMILIES }
  validates :iae_type,   presence: true
  validates :unit,       inclusion: { in: HveIaeCoefficient::UNITS }
  validates :surface_or_length, presence: true, numericality: { greater_than: 0 }

  before_save :resolve_coefficient
  before_save :compute_equivalent

  scope :family, ->(name) { where(iae_family: name) }

  def families_present
    audit.biodiversity_items.distinct.pluck(:iae_family)
  end

  private

    def resolve_coefficient
      return if coefficient.present?
      row = HveIaeCoefficient.find_for(family: iae_family, type: iae_type, unit: unit)
      self.coefficient = row&.coefficient
    end

    # Linear elements (m) are converted to hectares by dividing the
    # product (length × coefficient) by 10_000 only when the coefficient
    # is expressed per metre. The reference table actually publishes the
    # coefficient already homogeneous to "hectares per metre" for linear
    # elements, so the conversion is just length × coefficient. We keep
    # the (unit == 'ha') branch explicit so future calibration changes
    # stay obvious.
    def compute_equivalent
      return self.equivalent_iae_ha = nil if coefficient.blank?
      self.equivalent_iae_ha = surface_or_length.to_d * coefficient.to_d
    end
end
