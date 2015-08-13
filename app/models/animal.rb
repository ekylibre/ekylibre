# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
#  address_id            :integer
#  born_at               :datetime
#  category_id           :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  dead_at               :datetime
#  default_storage_id    :integer
#  derivative_of         :string
#  description           :text
#  extjuncted            :boolean          default(FALSE), not null
#  fixed_asset_id        :integer
#  id                    :integer          not null, primary key
#  identification_number :string
#  initial_born_at       :datetime
#  initial_container_id  :integer
#  initial_dead_at       :datetime
#  initial_enjoyer_id    :integer
#  initial_father_id     :integer
#  initial_geolocation   :geometry({:srid=>4326, :type=>"point"})
#  initial_mother_id     :integer
#  initial_owner_id      :integer
#  initial_population    :decimal(19, 4)   default(0.0)
#  initial_shape         :geometry({:srid=>4326, :type=>"geometry"})
#  lock_version          :integer          default(0), not null
#  name                  :string           not null
#  nature_id             :integer          not null
#  number                :string           not null
#  parent_id             :integer
#  person_id             :integer
#  picture_content_type  :string
#  picture_file_name     :string
#  picture_file_size     :integer
#  picture_updated_at    :datetime
#  tracking_id           :integer
#  type                  :string
#  updated_at            :datetime         not null
#  updater_id            :integer
#  variant_id            :integer          not null
#  variety               :string           not null
#  work_number           :string
#

class Animal < Bioproduct
  refers_to :variety, scope: :animal
  belongs_to :initial_father, class_name: 'Animal'
  belongs_to :initial_mother, class_name: 'Animal'

  validates_presence_of :identification_number
  validates_uniqueness_of :identification_number

  scope :fathers, -> { indicate(sex: 'male', reproductor: true).order(:name) }
  scope :mothers, -> { indicate(sex: 'female', reproductor: true).order(:name) }

  def status
    if self.dead_at?
      return :stop
    elsif indicators_list.include? :healthy
      return (healthy ? :go : :caution)
    else
      return :go
    end
  end

  def daily_nitrogen_production
    # set variables with default values
    quantity = 0.in_kilogram_per_day
    animal_milk_production = 0
    animal_age = 24

    # get data
    # age (if born_at not present then animal has 24 month)
    animal_age = (age / (3600 * 24 * 30)).to_d if age
    # production (if a cow, get annual milk production)
    if Nomen::Varieties[variety] <= :bos
      if milk_daily_production
        animal_milk_production = (milk_daily_production * 365).to_d
      end
    end
    items = Nomen::NmpFranceAbacusNitrogenAnimalProduction.list.select do |item|
      item.minimum_age <= animal_age.to_i && animal_age.to_i < item.maximum_age && item.minimum_milk_production <= animal_milk_production.to_i && animal_milk_production.to_i < item.maximum_milk_production && item.variant.to_s == variant.reference_name.to_s
    end
    if items.any?
      quantity_per_year = items.first.quantity
      quantity = (quantity_per_year / 365).in_kilogram_per_day
    end
    quantity
  end

  def sex_text
    "nomenclatures.sexes.items.#{sex}".t
  end

  def variety_text
    "nomenclatures.varieties.items.#{variety}".t
  end
end
