class HveAuditItem < ApplicationRecord
  belongs_to :audit, class_name: 'HveAudit',
                     foreign_key: :hve_audit_id,
                     inverse_of: :items

  validates :code, presence: true
  validates :theme, inclusion: { in: HveAudit::THEMES }
  validates :code, uniqueness: { scope: :hve_audit_id }

  scope :theme,  ->(theme) { where(theme: theme) }
  scope :auto,   -> { where(auto_computed: true) }
  scope :manual, -> { where(auto_computed: false) }

  # value_used resolves the override: manual takes priority when present.
  def effective_value
    value_manual.presence || value_raw
  end

  before_save :sync_value_used

  private

    def sync_value_used
      self.value_used = effective_value
    end
end
