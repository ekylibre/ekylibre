# frozen_string_literal: true

# Tenant-local snapshot of the official CMR phytosanitary products
# list published every year by the ministry. Used by HVE criterion 5.1:
# any application of a CMR1 product without an explicit derogation
# invalidates the entire audit; CMR2 applications are scored against a
# threshold.
#
# Updated annually via `rake hve:reference:load`.
class HveCmrProduct < ApplicationRecord
  CLASSES = %w[CMR1 CMR2].freeze

  validates :amm_code,      presence: true
  validates :cmr_class,     inclusion: { in: CLASSES }
  validates :snapshot_year, presence: true
  validates :amm_code, uniqueness: { scope: :snapshot_year }

  scope :for_year, ->(year) { where(snapshot_year: year) }
  scope :cmr1,     -> { where(cmr_class: 'CMR1') }
  scope :cmr2,     -> { where(cmr_class: 'CMR2') }
  scope :authorised, -> { where(status: 'AUTORISE') }

  # Look up a product by its AMM number for a given year. Without `year`, the
  # most recent snapshot actually loaded is used.
  def self.classify(amm_code, year: nil)
    return nil if amm_code.blank?

    year ||= latest_snapshot_year
    return nil if year.nil?

    where(amm_code: amm_code.to_s.strip, snapshot_year: year).limit(1).pluck(:cmr_class).first
  end

  # L'année de l'instantané CMR le plus récent présent en base. Elle se déduit
  # des données plutôt que d'une constante du greffon `ekylibre_hve`, qui les
  # livre : le cœur porte la table, le greffon son contenu, et la valeur suit
  # d'elle-même la prochaine livraison.
  def self.latest_snapshot_year
    maximum(:snapshot_year)
  end
end
