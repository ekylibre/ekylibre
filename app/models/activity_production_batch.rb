# frozen_string_literal: true

class ActivityProductionBatch < ApplicationRecord

  validates :number, :day_interval, presence: true, unless: :irregular_batch?
  validates :number, :day_interval, numericality: { greater_than: 0 }, unless: :irregular_batch?

  belongs_to :activity_production, class_name: 'ActivityProduction'
  belongs_to :plot, class_name: 'ScenarioActivity::Plot', foreign_key: :planning_scenario_activity_plot_id
  has_many :irregular_batches, class_name: 'ActivityProductionIrregularBatch', dependent: :destroy, foreign_key: :activity_production_batch_id, inverse_of: :activity_production_batch

  accepts_nested_attributes_for :irregular_batches, allow_destroy: true

  before_validation do
    irregular_batches.destroy_all unless irregular_batch
  end
end
