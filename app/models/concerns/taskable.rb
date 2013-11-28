module Taskable
  extend ActiveSupport::Concern

  included do
    belongs_to :operation
    belongs_to :originator, polymorphic: true
    has_many :product_births,        as: :originator, dependent: :destroy
    has_many :product_deaths,        as: :originator, dependent: :destroy
    has_many :product_enjoyments,    as: :originator, dependent: :destroy
    has_many :product_linkages,      as: :originator, dependent: :destroy
    has_many :product_localizations, as: :originator, dependent: :destroy
    has_many :product_measurements,  as: :originator, dependent: :destroy
    has_many :product_memberships,   as: :originator, dependent: :destroy
    has_many :product_ownerships,    as: :originator, dependent: :destroy
  end

  def intervention
    return (self.operation ? self.operation.intervention : nil)
  end

  def intervention_name
    return (self.operation ? self.operation.intervention_name : nil)
  end

end
