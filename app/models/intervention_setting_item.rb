# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: intervention_setting_items
#
#  absolute_measure_value_unit       :string
#  absolute_measure_value_value      :decimal(19, 4)
#  boolean_value                     :boolean          default(FALSE), not null
#  choice_value                      :string
#  created_at                        :datetime         not null
#  creator_id                        :integer(4)
#  decimal_value                     :decimal(19, 4)
#  geometry_value                    :geometry({:srid=>4326, :type=>"geometry"})
#  id                                :integer(4)       not null, primary key
#  indicator_datatype                :string           not null
#  indicator_name                    :string           not null
#  integer_value                     :integer(4)
#  intervention_id                   :integer(4)
#  intervention_parameter_setting_id :integer(4)
#  lock_version                      :integer(4)       default(0), not null
#  measure_value_unit                :string
#  measure_value_value               :decimal(19, 4)
#  point_value                       :geometry({:srid=>4326, :type=>"st_point"})
#  string_value                      :text
#  updated_at                        :datetime         not null
#  updater_id                        :integer(4)
#
class InterventionSettingItem < ApplicationRecord
  include ReadingStorable
  belongs_to :intervention_parameter_setting, optional: true
  belongs_to :intervention, optional: true

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :absolute_measure_value_unit, :choice_value, length: { maximum: 500 }, allow_blank: true
  validates :absolute_measure_value_value, :decimal_value, :measure_value_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :boolean_value, inclusion: { in: [true, false] }
  validates :indicator_datatype, :indicator_name, presence: true
  validates :integer_value, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :string_value, length: { maximum: 500_000 }, allow_blank: true
  # ]VALIDATORS]
  validates_uniqueness_of :indicator_name, scope: :intervention_parameter_setting_id, if: -> { intervention_parameter_setting.present? }
  validates_uniqueness_of :indicator_name, scope: :intervention_id, if: -> { intervention.present? }
end
