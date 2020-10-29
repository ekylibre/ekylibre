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
# == Table: event_participations
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  event_id       :integer          not null
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  participant_id :integer          not null
#  state          :string
#  updated_at     :datetime         not null
#  updater_id     :integer
#

class EventParticipation < Ekylibre::Record::Base
  belongs_to :event, inverse_of: :participations
  belongs_to :participant, class_name: 'Entity'
  enumerize :state, in: %i[waiting accepted refused informative]
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :event, :participant, presence: true
  # ]VALIDATORS]

  delegate :name, :full_name, to: :participant, prefix: true

  def status
    { waiting: :caution, accepted: :go, refused: :stop, informative: :undefined }.with_indifferent_access[state]
  end
end
