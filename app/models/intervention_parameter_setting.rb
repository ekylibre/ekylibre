# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2022 Ekylibre SAS
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
# == Table: intervention_parameter_settings
#
#  created_at                :datetime         not null
#  creator_id                :integer
#  id                        :integer          not null, primary key
#  intervention_id           :integer
#  intervention_parameter_id :integer
#  lock_version              :integer          default(0), not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#
class InterventionParameterSetting < ApplicationRecord
  SETTING_NAMES_INDICATORS = {
    spraying: %w[nozzle_type nozzle_count width spray_pressure ground_speed engine_speed]
  }.freeze

  belongs_to :intervention
  belongs_to :intervention_parameter, optional: true
  has_many :settings, class_name: 'InterventionSettingItem', dependent: :destroy
  enumerize :nature, in: %i[spraying]

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :nature, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]

  accepts_nested_attributes_for :settings, reject_if: ->(params) { params['measure_value_value'].blank? && params['integer_value'].blank? && params['boolean_value'].blank? && params['decimal_value'].blank? }, allow_destroy: true

  def name
    :setting_number.tl(locale: Preference[:language]) +  (id || (self.class.last_id + 1)).to_s
  end

  def reference_indicator_names
    SETTING_NAMES_INDICATORS[nature.to_sym]
  end

  def self.last_id
    connection.execute("SELECT last_value FROM intervention_parameter_settings_id_seq").first['last_value']
  end
end
