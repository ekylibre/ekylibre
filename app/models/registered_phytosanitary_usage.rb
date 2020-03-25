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
#  pre_harvest_delay          :interval
#  pre_harvest_delay_bbch     :integer
#  product_id                 :integer          not null
#  record_checksum            :integer
#  species                    Array<:text>
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
  extend Enumerize
  include HasInterval
  include Lexiconable
  include ScopeIntrospection

  belongs_to :product, class_name: 'RegisteredPhytosanitaryProduct'

  enumerize :state, in: %w[authorized provisional withdrawn], predicates: true
  has_interval :pre_harvest_delay

  scope :of_product, -> (*ids) { where(product_id: ids) }

  # Matches at least one of the given varieties
  scope :of_variety, -> (*varieties) do
    with_ancestors = [*varieties, *varieties.flat_map { |v| Nomen::Variety.ancestors(Nomen::Variety.find(v)).map(&:name) }].uniq.join('", "')

    joins('LEFT OUTER JOIN registered_phytosanitary_cropsets ON registered_phytosanitary_usages.species[1] = registered_phytosanitary_cropsets.name')
      .where("registered_phytosanitary_usages.species && '{\"#{with_ancestors}\"}' OR registered_phytosanitary_cropsets.crop_names && '{\"#{with_ancestors}\"}'")
      .order(:state)
  end

  # Matches all the given varieties
  scope :of_varieties, -> (*varieties) { varieties.reduce(self) { |acc, v| acc.of_variety(v) } }

  scope :of_specie, ->(specie) { where(specie: specie.to_s) }
  scope :with_conditions, -> { where.not(usage_conditions: nil) }

  delegate :decorated_reentry_delay, to: :product

  %i[dose_quantity development_stage_min usage_conditions pre_harvest_delay].each do |col|
    define_method "decorated_#{col}" do
      decorate.send(col)
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

  def decorated_applications_frequency
    decorate.value_in_days(:applications_frequency)
  end

  def status
    if authorized?
      :go
    elsif provisional?
      :caution
    elsif withdrawn?
      :stop
    else
      :stop
    end
  end

  def of_dimension?(dimension)
    dose_unit.present? && Nomen::Unit.find(dose_unit).dimension == dimension.to_sym
  end

  def among_dimensions?(*dimensions)
    dimensions.any? { |dimension| of_dimension?(dimension) }
  end
end
