# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  created_at      :datetime         not null
#  creator_id      :integer
#  duration        :integer          not null
#  id              :integer          not null, primary key
#  intervention_id :integer          not null
#  lock_version    :integer          default(0), not null
#  started_at      :datetime         not null
#  stopped_at      :datetime         not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#

class InterventionWorkingPeriod < Ekylibre::Record::Base
  include PeriodicCalculable
  belongs_to :intervention
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :duration, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :stopped_at, presence: true, timeliness: { on_or_after: ->(intervention_working_period) { intervention_working_period.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :intervention, presence: true
  # ]VALIDATORS]

  calculable period: :month, column: :duration, at: :started_at, name: :sum

  scope :without_activity, -> { where.not(intervention_id: Intervention::HABTM_Activities.select(:activity_id)) }
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

  delegate :update_temporality, to: :intervention

  before_validation do
    self.duration = (stopped_at - started_at).to_i if started_at && stopped_at
  end

  validate do
    if started_at && stopped_at && stopped_at <= started_at
      errors.add(:stopped_at, :posterior, to: started_at.l)
    end
  end

  after_commit :update_temporality
  after_destroy :update_temporality
end
