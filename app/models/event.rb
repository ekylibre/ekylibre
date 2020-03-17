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
# == Table: events
#
#  affair_id     :integer
#  created_at    :datetime         not null
#  creator_id    :integer
#  custom_fields :jsonb
#  description   :text
#  duration      :integer
#  id            :integer          not null, primary key
#  lock_version  :integer          default(0), not null
#  name          :string           not null
#  nature        :string           not null
#  place         :string
#  restricted    :boolean          default(FALSE), not null
#  started_at    :datetime         not null
#  stopped_at    :datetime
#  updated_at    :datetime         not null
#  updater_id    :integer
#

class Event < Ekylibre::Record::Base
  include Attachable
  include Customizable
  belongs_to :affair
  has_one :intervention, inverse_of: :event
  has_many :participations, class_name: 'EventParticipation', dependent: :destroy, inverse_of: :event
  has_many :participants, through: :participations
  refers_to :nature, class_name: 'EventNature'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :duration, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :nature, presence: true
  validates :place, length: { maximum: 500 }, allow_blank: true
  validates :restricted, inclusion: { in: [true, false] }
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :stopped_at, timeliness: { on_or_after: ->(event) { event.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  # ]VALIDATORS]
  validates :nature, inclusion: { in: nature.values }
  validates :stopped_at, presence: true

  accepts_nested_attributes_for :participations

  scope :between, lambda { |started_at, stopped_at|
    where(started_at: started_at..stopped_at)
  }
  scope :after,   ->(at) { where(arel_table[:started_at].gt(at)) }
  scope :before,  ->(at) { where(arel_table[:started_at].lt(at)) }
  scope :without_restrictions_for, lambda { |*entities|
    where("NOT restricted OR (restricted AND id IN (SELECT event_id FROM #{EventParticipation.table_name} WHERE participant_id IN (?)))", entities.flatten.map(&:id))
  }
  scope :with_participant, lambda { |*entities|
    where("id IN (SELECT event_id FROM #{EventParticipation.table_name} WHERE participant_id IN (?))", entities.flatten.map(&:id))
  }

  # protect(on: :destroy) do
  #   puts self.destroyed_by_association.inspect.red
  #   return self.intervention.present? unless self.destroyed_by_association
  #   return false
  # end

  before_validation do
    self.nature ||= :meeting
    self.started_at ||= Time.zone.now
    if nature = Nomen::EventNature[self.nature]
      self.duration ||= nature.default_duration.to_i
    end
    if stopped_at && self.started_at
      self.duration = (stopped_at - self.started_at).to_i
    elsif self.started_at && self.duration
      self.stopped_at = self.started_at + self.duration
    else
      self.duration = 0
    end
  end

  validate do
    if self.started_at && stopped_at
      if stopped_at < self.started_at
        errors.add(:stopped_at, :posterior, to: self.started_at.l)
      end
    end
  end

  def updateable?
    intervention.blank?
  end

  # TODO: Make it better if possible
  def casting
    participants.map(&:label).to_sentence
  end

  def start_time
    self.started_at
  end
end
