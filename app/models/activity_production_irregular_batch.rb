# frozen_string_literal: true

class ActivityProductionIrregularBatch < ApplicationRecord

  belongs_to :activity_production_batch, class_name: 'ActivityProductionBatch', foreign_key: :activity_production_batch_id, required: true

  # Sowing date should be between the period of the activity production
  validate :sowing_date_between_period_of_activity_production
  validates :estimated_sowing_date, :area, presence: true

  def sowing_date_between_period_of_activity_production
    activity_production = activity_production_batch&.activity_production
    if activity_production.present?
      if estimated_sowing_date.present? && estimated_sowing_date < activity_production.started_on
        errors.add(:estimated_sowing_date, :date_should_be_after_start_date_of_production)
      end

      if estimated_sowing_date.present? && estimated_sowing_date > activity_production.stopped_on
        errors.add(:estimated_sowing_date, :date_should_be_before_end_of_production)
      end
    end
  end
end
