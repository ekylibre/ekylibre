# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
#  address_id                   :integer
#  birth_date_completeness      :string
#  birth_farm_number            :string
#  born_at                      :datetime
#  category_id                  :integer          not null
#  country                      :string
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  custom_fields                :jsonb
#  dead_at                      :datetime
#  default_storage_id           :integer
#  derivative_of                :string
#  description                  :text
#  end_of_life_reason           :string
#  father_country               :string
#  father_identification_number :string
#  father_variety               :string
#  filiation_status             :string
#  first_calving_on             :datetime
#  fixed_asset_id               :integer
#  id                           :integer          not null, primary key
#  identification_number        :string
#  initial_born_at              :datetime
#  initial_container_id         :integer
#  initial_dead_at              :datetime
#  initial_enjoyer_id           :integer
#  initial_father_id            :integer
#  initial_geolocation          :geometry({:srid=>4326, :type=>"st_point"})
#  initial_mother_id            :integer
#  initial_movement_id          :integer
#  initial_owner_id             :integer
#  initial_population           :decimal(19, 4)   default(0.0)
#  initial_shape                :geometry({:srid=>4326, :type=>"multi_polygon"})
#  lock_version                 :integer          default(0), not null
#  member_variant_id            :integer
#  mother_country               :string
#  mother_identification_number :string
#  mother_variety               :string
#  name                         :string           not null
#  nature_id                    :integer          not null
#  number                       :string           not null
#  origin_country               :string
#  origin_identification_number :string
#  originator_id                :integer
#  parent_id                    :integer
#  person_id                    :integer
#  picture_content_type         :string
#  picture_file_name            :string
#  picture_file_size            :integer
#  picture_updated_at           :datetime
#  team_id                      :integer
#  tracking_id                  :integer
#  type                         :string
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  uuid                         :uuid
#  variant_id                   :integer          not null
#  variety                      :string           not null
#  work_number                  :string
#
require 'test_helper'

class AnimalTest < ActiveSupport::TestCase
  test_model_actions
  # Add tests here...
  test 'animal without identification number' do
    animal = Animal.new(
      name: 'test_animal',
      variant_id: ProductNatureVariant.where(variety: :bos).first.id,
      # category_id: 8,
      variety: 'bos',
      nature_id: ProductNature.where(variety: 'bos').first,

    )
    animal.valid?
    binding.pry
    # animal = FactoryGirl.new(:animal)
  end
end

# id: 14,
#  category_id: 8,
#  nature_id: 12,
#  name: "Veau",
#  work_number: nil,
#  variety: "bos",
#  derivative_of: nil,
#  reference_name: "calf",
#  unit_name: "Tête",
#  active: true,
#  picture_file_name: nil,
#  picture_content_type: nil,
#  picture_file_size: nil,
#  picture_updated_at: nil,
#  created_at: Fri, 09 Jun 2017 12:58:59 UTC +00:00,
#  updated_at: Fri, 09 Jun 2017 12:58:59 UTC +00:00,
#  creator_id: nil,
#  updater_id: nil,
#  lock_version: 0,
#  custom_fields: nil,
#  gtin: nil,
#  number: "000014",
#  stock_account_id: 461,
#  stock_movement_account_id: 462,
#  france_maaid: nil>




# type: "Animal",
# name: "Test",
# number: "P00000000517",
# variant_id: 14,
# nature_id: 12,
# category_id: 8,
# initial_born_at: Fri, 09 Jun 2017 13:00:00 UTC +00:00,
# initial_dead_at: nil,
# initial_container_id: nil,
# initial_owner_id: nil,
# initial_enjoyer_id: nil,
# initial_population: #<BigDecimal:f4ecaa0,'0.0',9(18)>,
# initial_shape: nil,
# initial_father_id: nil,
# initial_mother_id: nil,
# variety: "bos",
# derivative_of: nil,
# tracking_id: nil,
# fixed_asset_id: nil,
# born_at: Fri, 09 Jun 2017 13:00:00 UTC +00:00,
# dead_at: nil,
# description: nil,
# picture_file_name: nil,
# picture_content_type: nil,
# picture_file_size: nil,
# picture_updated_at: nil,
# identification_number: "bla",
# work_number: nil,
# address_id: nil,
# parent_id: nil,
# default_storage_id: nil,
# created_at: Fri, 09 Jun 2017 14:01:19 UTC +00:00,
# updated_at: Fri, 09 Jun 2017 14:01:19 UTC +00:00,
# creator_id: 1,
# updater_id: 1,
# lock_version: 0,
# person_id: nil,
# initial_geolocation: nil,
# uuid: "1ff0f66f-3711-4764-a209-f9a692176e25",
# initial_movement_id: 709,
# custom_fields: nil,
# team_id: nil,
# member_variant_id: nil,
# birth_date_completeness: nil,
# birth_farm_number: nil,
# country: nil,
# filiation_status: nil,
# first_calving_on: nil,
# mother_country: nil,
# mother_variety: nil,
# mother_identification_number: nil,
# father_country: nil,
# father_variety: nil,
# father_identification_number: nil,
# origin_country: nil,
# origin_identification_number: nil,
# end_of_life_reason: nil,
# originator_id: nil>
