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
# == Table: crumbs
#
#  accuracy                      :decimal(19, 4)   not null
#  created_at                    :datetime         not null
#  creator_id                    :integer
#  device_uid                    :string           not null
#  geolocation                   :geometry({:srid=>4326, :type=>"st_point"}) not null
#  id                            :integer          not null, primary key
#  intervention_parameter_id     :integer
#  intervention_participation_id :integer
#  lock_version                  :integer          default(0), not null
#  metadata                      :text
#  nature                        :string           not null
#  read_at                       :datetime         not null
#  updated_at                    :datetime         not null
#  updater_id                    :integer
#  user_id                       :integer
#

class Crumb < Ekylibre::Record::Base
  enumerize :nature, in: %i[point start stop pause resume scan hard_start hard_stop], predicates: true
  belongs_to :user
  belongs_to :intervention_participation
  belongs_to :intervention_parameter, class_name: 'InterventionProductParameter'
  has_one :worker, through: :user
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accuracy, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :device_uid, presence: true, length: { maximum: 500 }
  validates :geolocation, :nature, presence: true
  validates :metadata, length: { maximum: 500_000 }, allow_blank: true
  validates :read_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  # ]VALIDATORS]
  serialize :metadata, Hash

  scope :after,   ->(at) { where(arel_table[:read_at].gt(at)) }
  scope :before,  ->(at) { where(arel_table[:read_at].lt(at)) }
  scope :unconverted, -> { where(intervention_parameter_id: nil) }

  # returns all crumbs for a given day. Default: the current day
  # TODO: remove this and replace by something like #start_day_between or #at
  scope :of_date, lambda { |start_date = Time.zone.now.midnight|
    where(read_at: start_date.midnight..start_date.end_of_day)
  }
end
