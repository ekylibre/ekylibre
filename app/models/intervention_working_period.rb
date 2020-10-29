# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: intervention_working_periods
#
#  created_at                    :datetime         not null
#  creator_id                    :integer
#  duration                      :integer          not null
#  id                            :integer          not null, primary key
#  intervention_id               :integer
#  intervention_participation_id :integer
#  lock_version                  :integer          default(0), not null
#  nature                        :string
#  started_at                    :datetime         not null
#  stopped_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  updater_id                    :integer
#

class InterventionWorkingPeriod < Ekylibre::Record::Base
  include PeriodicCalculable
  belongs_to :intervention
  belongs_to :intervention_participation
  has_one    :intervention_participated_to, through: :intervention_participation, source: :intervention
  enumerize :nature, in: %i[preparation travel intervention pause]
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :duration, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :stopped_at, presence: true, timeliness: { on_or_after: ->(intervention_working_period) { intervention_working_period.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  # ]VALIDATORS]
  validate :validate_started_stopped_at

  calculable period: :month, column: :duration, at: :started_at, name: :sum

  scope :without_activity, -> { where.not(intervention_id: Intervention::HABTM_Activities.joins(:activity).select(:intervention_id)) }
  scope :of_activity, ->(activity) { where(intervention_id: Intervention.of_activity(activity)) }
  scope :of_activities, ->(*activities) { where(intervention_id: Intervention.of_activities(*activities)) }
  scope :of_campaign, lambda { |campaign|
    where(intervention_id: Intervention.of_campaign(campaign))
  }

  scope :with_generic_cast, lambda { |role, object|
    where(intervention_id: InterventionProductParameter.of_generic_role(role).of_actor(object).select(:intervention_id))
  }

  scope :with_intervention_parameter, lambda { |role, object|
    where(intervention_id: InterventionParameter.of_generic_role(role).of_actor(object).select(:intervention_id))
  }

  scope :of_intervention_participations, lambda { |intervention_participations|
    where(intervention_participation: intervention_participations)
  }

  scope :without_participants_intervention, lambda { |_role, object|
    where.not(intervention_id: InterventionParticipation.of_actor(object).pluck(:intervention_id).compact)
  }

  scope :precise_working_periods, lambda { |role, object|
    where(id: (InterventionWorkingPeriod.with_intervention_parameter(role, object).without_participants_intervention(role, object).pluck(:id) + InterventionWorkingPeriod.of_intervention_participations(object.intervention_participations).pluck(:id)))
  }

  scope :of_nature, lambda { |nature|
    where(nature: nature)
  }

  delegate :update_temporality, to: :intervention

  before_validation do
    self.duration = (stopped_at - started_at).to_i if started_at && stopped_at
  end

  validate do
    errors.add(:intervention, :empty) unless intervention || intervention_participated_to || intervention_participation
    if started_at && stopped_at && stopped_at <= started_at
      errors.add(:stopped_at, :posterior, to: started_at.l)
    end

    if intervention_participation.present?
      errors.add(:started_at, :overlap_sibling) if intervention_participation.working_periods.select do |participation|
                                                     participation.id != id &&
                                                     participation.started_at.to_f <= started_at.to_f &&
                                                     started_at.to_f < participation.stopped_at.to_f
                                                   end.any?

      errors.add(:stopped_at, :overlap_sibling) if intervention_participation.working_periods.select do |participation|
                                                     participation.id != id &&
                                                     participation.started_at.to_f < stopped_at.to_f &&
                                                     stopped_at.to_f <= participation.stopped_at.to_f
                                                   end.any?

    end
  end

  after_commit :update_temporality, unless: -> { intervention.blank? || Intervention.find_by(id: intervention_id).nil? }
  after_destroy :update_temporality, unless: -> { intervention.blank? || Intervention.find_by(id: intervention_id).nil? }

  def last_activity_production_started_on
    targets = intervention&.targets || []
    targets.map { |t| t.activity_production&.started_on }.compact.max
  end

  def first_activity_production_stopped_on
    targets = intervention&.targets || []
    targets.map { |t| t.activity_production&.stopped_on }.compact.min
  end

  def validate_started_stopped_at
    activity_started_on = last_activity_production_started_on
    activity_stopped_on = first_activity_production_stopped_on
    if activity_started_on.present?
      errors.add(:started_at, :posterior, to: activity_started_on) if started_at < activity_started_on
      errors.add(:stopped_at, :posterior, to: activity_started_on) if stopped_at < activity_started_on
    end
    if activity_stopped_on.present?
      errors.add(:started_at, :inferior, to: activity_stopped_on) if started_at > activity_stopped_on
      errors.add(:stopped_at, :inferior, to: activity_stopped_on) if stopped_at > activity_stopped_on
    end
  end

  def hide?
    started_at.to_i == stopped_at.to_i
  end

  def hours_gap
    (gap[:day] * 24) + gap[:hour]
  end

  def minutes_gap
    gap[:minute]
  end

  def previous_period
    return if first?

    previous_index = index - 1
    intervention_participation.working_periods.fetch(previous_index)
  end

  def next_period
    return if last?

    next_index = index + 1
    intervention_participation.working_periods.fetch(next_index)
  end

  def pause_next?
    return false if last?
    gap_with_period?(next_period)
  end

  def gap_with_period?(working_period)
    stopped_at < working_period.started_at
  end

  def duration_gap
    (stopped_at - started_at) / 3600
  end

  def during_financial_year_exchange?
    FinancialYearExchange.opened.where('? BETWEEN started_on AND stopped_on', started_at).any?
  end

  private

  def gap
    Time.diff(stopped_at, started_at)
  end

  def first?
    intervention_participation.working_periods.first == self
  end

  def last?
    intervention_participation.working_periods.last == self
  end

  def index
    intervention_participation.working_periods.find_index(self)
  end
end
