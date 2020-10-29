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
# == Table: activity_inspection_calibration_scales
#
#  activity_id         :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  size_indicator_name :string           not null
#  size_unit_name      :string           not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#
class ActivityInspectionCalibrationScale < Ekylibre::Record::Base
  belongs_to :activity
  has_many :natures, -> { order(:minimal_value, :maximal_value) },
           class_name: 'ActivityInspectionCalibrationNature',
           foreign_key: :scale_id, inverse_of: :scale, dependent: :destroy
  refers_to :size_indicator, -> { where(datatype: :measure) }, class_name: 'Indicator'
  refers_to :size_unit, -> { where(dimension: %i[distance mass]) }, class_name: 'Unit'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :activity, :size_indicator_name, :size_unit_name, presence: true
  # ]VALIDATORS]

  accepts_nested_attributes_for :natures, reject_if: :all_blank, allow_destroy: true

  def name
    size_indicator.human_name
  end
end
