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
# == Table: activity_tactics
#
#  activity_id  :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  mode         :string
#  mode_delta   :integer
#  name         :string           not null
#  planned_on   :date
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class ActivityTactic < Ekylibre::Record::Base
  enumerize :mode, in: %i[sowed harvested], default: :sowed

  belongs_to :activity, class_name: 'Activity', inverse_of: :tactics
  has_many :productions, class_name: 'ActivityProduction', inverse_of: :tactic, foreign_key: :tactic_id

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :mode_delta, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :planned_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :activity, presence: true
  # ]VALIDATORS]

  def of_family
    Activity.where(id: activity_id).map(&:family).join.to_sym
  end

  def mode_unit_name
    :day
  end

  def mode_unit_name=(value)
    raise ArgumentError, 'Mode unit must be: day' unless value.to_s == 'day'
  end
end
