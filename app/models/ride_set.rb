# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: ride_sets
#
#  area_smart           :float
#  area_with_overlap    :float
#  area_without_overlap :float
#  created_at           :datetime         not null
#  creator_id           :integer
#  duration             :interval
#  gasoline             :float
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  nature               :string
#  number               :string
#  provider             :jsonb
#  road                 :integer
#  sleep_count          :integer
#  sleep_duration       :interval
#  started_at           :datetime
#  stopped_at           :datetime
#  updated_at           :datetime         not null
#  updater_id           :integer
#
class RideSet < ApplicationRecord
  include Attachable
  include Providable
  include HasInterval
  has_many :rides, dependent: :destroy
  has_many :crumbs, through: :rides

  has_interval :duration, :sleep_duration

  acts_as_numbered :number
  enumerize :nature, in: %i[road work]

  %i[duration sleep_duration].each do |col|
    define_method "decorated_#{col}" do
      decorate.send(col)
    end
  end

  def equipment
    self.rides.first.equipment_name
  end
end
