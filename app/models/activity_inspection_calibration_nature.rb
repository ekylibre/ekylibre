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
# == Table: activity_inspection_calibration_natures
#
#  created_at    :datetime         not null
#  creator_id    :integer
#  id            :integer          not null, primary key
#  lock_version  :integer          default(0), not null
#  marketable    :boolean          default(FALSE), not null
#  maximal_value :decimal(19, 4)   not null
#  minimal_value :decimal(19, 4)   not null
#  scale_id      :integer          not null
#  updated_at    :datetime         not null
#  updater_id    :integer
#

class ActivityInspectionCalibrationNature < Ekylibre::Record::Base
  belongs_to :scale, class_name: 'ActivityInspectionCalibrationScale', inverse_of: :natures
  has_one :activity, through: :scale
  has_many :inspection_calibrations, class_name: 'InspectionCalibration', inverse_of: :nature, foreign_key: :nature_id, dependent: :restrict_with_exception
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :marketable, inclusion: { in: [true, false] }
  validates :maximal_value, :minimal_value, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :scale, presence: true
  # ]VALIDATORS]

  delegate :size_indicator, :size_unit, to: :scale

  scope :marketable, -> { where(marketable: true) }

  # TODO: Validate no overlapping

  def name
    tc :name,
       scale: size_indicator.human_name,
       minimum: minimal_value.in(size_unit).l(precision: 0),
       maximum: maximal_value.in(size_unit).l(precision: 0)
  end
end
