# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
  belongs_to :intervention
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :duration, allow_nil: true, only_integer: true
  validates_presence_of :duration, :intervention, :started_at, :stopped_at
  # ]VALIDATORS]

  scope :of_campaign, lambda { |campaign|
    where(intervention_id: Intervention.of_campaign(campaign))
  }

  scope :with_generic_cast, lambda { |role, object|
    where(intervention_id: InterventionCast.of_generic_role(role).of_actor(object).select(:intervention_id))
  }

  delegate :update_temporality, to: :intervention

  before_validation do
    if self.started_at && self.stopped_at
      self.duration = (self.stopped_at - self.started_at).to_i
    end
  end

  validate do
    if self.started_at && self.stopped_at
      if self.stopped_at <= self.started_at
        errors.add(:stopped_at, :posterior, to: self.started_at.l)
      end
    end
  end

  after_commit :update_temporality
  after_destroy :update_temporality
end
