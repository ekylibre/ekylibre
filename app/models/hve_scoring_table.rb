# Regional Pf/Pc thresholds used to score the IFT (Indice de Fréquence
# de Traitements) item 5.3. Pc is the 20th percentile (plancher), Pf
# the 70th percentile (plafond); each scoring class is one quarter of
# (Pf - Pc) above Pc.
class HveScoringTable < ApplicationRecord
  FILIERES  = %w[gc viticulture arboriculture horticulture].freeze
  IFT_TYPES = %w[herbicide hors_herbicide].freeze

  validates :filiere,  inclusion: { in: FILIERES }
  validates :ift_type, inclusion: { in: IFT_TYPES }
  validates :filiere, uniqueness: { scope: %i[region ift_type] }

  scope :for, ->(filiere:, region:, ift_type:) {
    where(filiere: filiere, region: region, ift_type: ift_type)
  }

  # Map an actual IFT value to a 0..5 score (Plan §5.3).
  # Returns nil when no scoring row exists for this combination.
  def score_for(ift_value)
    return nil if pc.nil? || pf.nil?
    return 5 if ift_value <= pc
    step = (pf - pc) / 4.0
    return 0 if ift_value >= pf
    [5 - ((ift_value - pc) / step).floor, 0].max
  end
end
