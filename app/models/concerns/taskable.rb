module Taskable
  extend ActiveSupport::Concern

  included do
    belongs_to :intervention
    belongs_to :originator, polymorphic: true
    with_options as: :originator, dependent: :destroy do
      has_many :product_enjoyments
      has_many :product_junctions
      has_many :product_linkages
      has_many :product_localizations
      has_many :product_memberships
      has_many :product_ownerships
      has_many :product_phases
      has_many :product_readings
    end

    before_validation :ensure_originator_type
  end

  def ensure_originator_type
    self.originator_type = originator.class.base_class.name if originator
  end
end
