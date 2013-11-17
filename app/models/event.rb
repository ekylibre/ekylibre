# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: events
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
#  duration     :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature_id    :integer          not null
#  place        :string(255)
#  started_at   :datetime         not null
#  stopped_at   :datetime
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class Event < Ekylibre::Record::Base
  belongs_to :nature, class_name: "EventNature"
  has_many :participations, class_name: "EventParticipation"
  has_many :participants, :through => :participations
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :duration, allow_nil: true, only_integer: true
  validates_length_of :name, :place, allow_nil: true, maximum: 255
  validates_presence_of :name, :nature, :started_at
  #]VALIDATORS]

  before_validation do
    self.started_at ||= Time.now
  end

  # TODO Make it better if possible
  def casting
    self.participants.map(&:label).to_sentence
  end

end
