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
# == Table: registered_phytosanitary_usages
#
#  applications_count         :integer
#  applications_frequency     :integer
#  crop                       :jsonb
#  crop_label_fra             :string
#  decision_date              :date
#  description                :jsonb
#  development_stage_max      :integer
#  development_stage_min      :integer
#  dose_quantity              :decimal(19, 4)
#  dose_unit                  :string
#  dose_unit_factor           :float
#  dose_unit_name             :string
#  ephy_usage_phrase          :string           not null
#  id                         :string           not null, primary key
#  lib_court                  :integer
#  pre_harvest_delay          :integer
#  pre_harvest_delay_bbch     :integer
#  product_id                 :integer          not null
#  record_checksum            :integer
#  species                    :text
#  state                      :string           not null
#  target_name                :jsonb
#  target_name_label_fra      :string
#  treatment                  :jsonb
#  untreated_buffer_aquatic   :integer
#  untreated_buffer_arthropod :integer
#  untreated_buffer_plants    :integer
#  usage_conditions           :string
#
class RegisteredPhytosanitaryUsage < ActiveRecord::Base
  include Lexiconable
  include ScopeIntrospection
  belongs_to :product, class_name: 'RegisteredPhytosanitaryProduct'

  scope :of_product, -> (*ids) { where(product_id: ids) }
  scope :of_variety, -> (*varieties) { joins('LEFT OUTER JOIN ephy_cropsets
                                              ON registered_phytosanitary_usages.species[1] = ephy_cropsets.name')
                                         .where('registered_phytosanitary_usages.species && \'{"' + ActivityProduction.retrieve_varieties_ancestors(*varieties).join('", "') + '"}\'
                                               OR ephy_cropsets.crop_names && \'{"' + ActivityProduction.retrieve_varieties_ancestors(*varieties).join('", "') + '"}\'') }

  scope :of_specie, ->(specie) { where(specie: specie.to_s) }

  %i[dose_quantity development_stage_min].each do |col|
    define_method "decorated_#{col}" do
      decorate.send(col)
    end
  end

  %i[pre_harvest_delay applications_frequency].each do |col|
    define_method "decorated_#{col}" do
      decorate.value_in_days(col)
    end
  end

  %i[untreated_buffer_aquatic untreated_buffer_arthropod untreated_buffer_plants].each do |col|
    define_method "decorated_#{col}" do
      decorate.value_in_meters(col)
    end
  end

  %i[lib_court ephy_usage_phrase].each do |col|
    define_method "decorated_#{col}" do
      decorate.link_to_ephy(col)
    end
  end

  def status
    case state
      when 'Autorisé'
        :go
      when 'Provisoire'
        :caution
      when 'Retrait'
        :stop
    end
  end

  def of_dimension?(dimension)
    return false unless dose_unit
    Nomen::Unit.find(dose_unit).dimension == dimension.to_sym
  end

  def among_dimensions?(*dimensions)
    dimensions.any? { |dimension| of_dimension?(dimension) }
  end
end
