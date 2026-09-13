# frozen_string_literal: true

# == Schema information
# (see db/migrate/20260606120001_create_hve_audits.rb)
#
# A single HVE audit lives for one campaign of one tenant.
# It aggregates 35 HveAuditItem records (one per HVE criterion) and
# caches the four indicator scores plus the global verdict.
class HveAudit < ApplicationRecord
  VALID_STATUSES = %w[draft submitted certified refused].freeze
  VALID_VERDICTS = %w[compliant non_compliant cmr1_blocked].freeze
  THEMES = %w[biodiversity phytosanitary fertilisation irrigation].freeze

  belongs_to :campaign
  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :updater, class_name: 'User', optional: true

  has_many :items, class_name: 'HveAuditItem',
                   foreign_key: :hve_audit_id,
                   dependent: :destroy,
                   inverse_of: :audit

  has_many :biodiversity_items, class_name: 'HveBiodiversityItem',
                                foreign_key: :hve_audit_id,
                                dependent: :destroy,
                                inverse_of: :audit

  validates :referentiel_version, presence: true
  validates :status,  inclusion: { in: VALID_STATUSES }
  validates :verdict, inclusion: { in: VALID_VERDICTS }, allow_nil: true
  validates :campaign_id, uniqueness: { scope: :referentiel_version }

  scope :draft,     -> { where(status: 'draft') }
  scope :submitted, -> { where(status: 'submitted') }

  # Recomputes verdict from the four scores + CMR1 flag.
  # Does NOT save — callers decide whether to persist.
  def recompute_verdict
    self.verdict = if uses_cmr1_without_derogation
                     'cmr1_blocked'
                   elsif all_scores_meet_threshold?
                     'compliant'
                   else
                     'non_compliant'
                   end
  end

  def compliant?
    verdict == 'compliant'
  end

  # Seuil, en points, que chaque indicateur thématique doit atteindre pour la
  # certification (référentiel HVE V4.4). Il vit ici et non dans le greffon
  # `ekylibre_hve` : la table `hve_audits` et ce modèle sont au cœur, et un
  # modèle du cœur ne peut pas dépendre d'un greffon qui n'est pas toujours
  # monté — la CI ne monte aucun greffon.
  CERTIFICATION_THRESHOLD = 10

  def threshold
    CERTIFICATION_THRESHOLD
  end

  def scores
    {
      biodiversity:  score_biodiversity,
      phytosanitary: score_phytosanitary,
      fertilisation: score_fertilisation,
      irrigation:    score_irrigation
    }
  end

  private

    def all_scores_meet_threshold?
      scores.values.compact.size == 4 &&
        scores.values.all? { |v| v && v >= threshold }
    end
end
