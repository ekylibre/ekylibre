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
# == Table: products
#
#  activity_production_id       :integer(4)
#  address_id                   :integer(4)
#  birth_date_completeness      :string
#  birth_farm_number            :string
#  born_at                      :datetime
#  category_id                  :integer(4)       not null
#  codes                        :jsonb
#  conditioning_unit_id         :integer(4)
#  country                      :string
#  created_at                   :datetime         not null
#  creator_id                   :integer(4)
#  custom_fields                :jsonb
#  dead_at                      :datetime
#  default_storage_id           :integer(4)
#  derivative_of                :string
#  description                  :text
#  end_of_life_reason           :string
#  father_country               :string
#  father_identification_number :string
#  father_variety               :string
#  filiation_status             :string
#  first_calving_on             :datetime
#  fixed_asset_id               :integer(4)
#  id                           :integer(4)       not null, primary key
#  identification_number        :string
#  initial_born_at              :datetime
#  initial_container_id         :integer(4)
#  initial_dead_at              :datetime
#  initial_enjoyer_id           :integer(4)
#  initial_father_id            :integer(4)
#  initial_geolocation          :geometry({:srid=>4326, :type=>"st_point"})
#  initial_mother_id            :integer(4)
#  initial_movement_id          :integer(4)
#  initial_owner_id             :integer(4)
#  initial_population           :decimal(19, 4)   default(0.0)
#  initial_shape                :geometry({:srid=>4326, :type=>"multi_polygon"})
#  isacompta_analytic_code      :string(2)
#  lock_version                 :integer(4)       default(0), not null
#  member_variant_id            :integer(4)
#  mother_country               :string
#  mother_identification_number :string
#  mother_variety               :string
#  name                         :string           not null
#  nature_id                    :integer(4)       not null
#  number                       :string           not null
#  origin_country               :string
#  origin_identification_number :string
#  originator_id                :integer(4)
#  parent_id                    :integer(4)
#  person_id                    :integer(4)
#  picture_content_type         :string
#  picture_file_name            :string
#  picture_file_size            :integer(4)
#  picture_updated_at           :datetime
#  provider                     :jsonb            default("{}")
#  reading_cache                :jsonb            default("{}")
#  specie_variety               :jsonb            default("{}")
#  team_id                      :integer(4)
#  tracking_id                  :integer(4)
#  type                         :string
#  type_of_occupancy            :string
#  updated_at                   :datetime         not null
#  updater_id                   :integer(4)
#  uuid                         :uuid
#  variant_id                   :integer(4)       not null
#  variety                      :string           not null
#  work_number                  :string
#  worker_group_item_id         :integer(4)
#

class Animal < Bioproduct
  refers_to :variety, scope: :animal
  belongs_to :initial_father, class_name: 'Animal'
  belongs_to :initial_mother, class_name: 'Animal'
  belongs_to :originator, class_name: 'SynchronizationOperation'

  validates :identification_number, presence: true
  validates :identification_number, uniqueness: true

  enumerize :birth_date_completeness, in: %i[year month_year full_date]
  enumerize :filiation_status, in: %i[unknown certified uncertified]
  enumerize :end_of_life_reason, in: %i[death slaughter cutting_up calculated_date]

  def status
    if dead_at?
      :stop
    elsif indicators_list.include? :healthy
      (healthy ? :go : :caution)
    else
      :go
    end
  end

  def human_status
    I18n.t("tooltips.models.animal.#{status}")
  end

  def state
    I18n.t("tooltips.models.animal.#{status}")
  end

  # Compute daily nitrogen production based on indicator of product
  # The indicator is the reference for now.
  def daily_nitrogen_production(at = nil)
    at ||= Time.zone.now
    quantity = 0.in_kilogram_per_day
    if has_indicator?(:daily_nitrogen_production)
      quantity = daily_nitrogen_production(at: at)
    end
    quantity
  end

  def sex_text
    "nomenclatures.sexes.items.#{sex}".t
  end

  def variety_text
    "nomenclatures.varieties.items.#{variety}".t
  end

  def synchronization_operations
    SynchronizationOperation.of_product(self)
  end
end
