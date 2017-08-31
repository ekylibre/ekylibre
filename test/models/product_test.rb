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
#  codes                        :jsonb
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
#  reading_cache                :jsonb
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

class ProductTest < ActiveSupport::TestCase
  test_model_actions
  test 'working sets' do
    assert Product.of_expression('is product').any?
    assert Product.of_expression('can move()').any?
    Nomen::WorkingSet.list.each do |item|
      assert Product.of_working_set(item.name).count >= 0
    end
  end

  test 'product has a way to get its intervention_participations' do
    product  = create :product
    intervention_participation = create :intervention_participation, product: product
    assert_includes product.intervention_participations, intervention_participation
  end

  test 'product can get a value from its readings: boolean' do
    product = create :product
    create :product_reading, :boolean,
      product: product,
      indicator_name: 'healthy',
      value: true

    assert_equal true, product.get(:healthy)
  end

  test 'product can get a value from its readings: choice' do
    product = create :product
    create :product_reading, :choice,
      product: product,
      indicator_name: 'certification',
      value: 'cognac'

    assert_equal 'cognac', product.get(:certification)
  end

  test 'product can get a value from its readings: decimal' do
    product = create :product
    create :product_reading, :decimal,
      product: product,
      indicator_name: 'members_population',
      value: 12.5

    assert_equal 12.5, product.get(:members_population)
  end

  # No indicators with datatype="geometry" yet.
  # test 'product can get a value from its readings: geometry' do
  #
  # end

  test 'product can get a value from its readings: integer' do
    product = create :product
    create :product_reading, :integer,
      product: product,
      indicator_name: 'rows_count',
      value: 4

    assert_equal 4, product.get(:rows_count)
  end

  test 'product can get a value from its readings: measure' do
    product = create :product
    create :product_reading, :measure,
      product: product,
      indicator_name: 'diameter',
      value: 5.in(:meter)

    assert_equal 5.in(:meter), product.get(:diameter)
  end

  test 'product can get a value from its readings: multi_polygon' do

  end

  test 'product can get a value from its readings: point' do

  end

  test 'product can get a value from its readings: string' do

  end
end
