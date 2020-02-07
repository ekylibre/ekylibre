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
# == Table: product_nature_variant_components
#
#  created_at                     :datetime         not null
#  creator_id                     :integer
#  deleted_at                     :datetime
#  id                             :integer          not null, primary key
#  lock_version                   :integer          default(0), not null
#  name                           :string           not null
#  parent_id                      :integer
#  part_product_nature_variant_id :integer
#  product_nature_variant_id      :integer          not null
#  updated_at                     :datetime         not null
#  updater_id                     :integer
#
require 'test_helper'

class ProductNatureVariantComponentTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'test non recursivity of components' do
    tractor = ProductNatureVariant.import_from_nomenclature(:tractor)

    piston_params = {
      nature: ProductNature.import_from_nomenclature(:equipment),
      category: ProductNatureCategory.import_from_nomenclature(:equipment),
      name: 'Piston B72 injection retro, alliage titane',
      unit_name: 'Piston',
      type: 'Variants::EquipmentVariant'
    }
    piston = ProductNatureVariant.create!(piston_params)

    motor_v12_param = {
      nature: ProductNature.import_from_nomenclature(:equipment),
      category: ProductNatureCategory.import_from_nomenclature(:equipment),
      name: 'Moteur V12 injection gtx 18L, 2013',
      unit_name: 'Moteur',
      type: 'Variants::EquipmentVariant'
    }
    motor_v12 = ProductNatureVariant.create!(motor_v12_param)

    motor = tractor.components.create!(name: 'Moteur', part_product_nature_variant: motor_v12)
    tractor.components.create!(name: 'Piston 1', part_product_nature_variant: piston, parent: motor)
    tractor.components.create!(name: 'Piston 2', part_product_nature_variant: piston, parent: motor)

    assert_raise ActiveRecord::RecordInvalid do
      tractor.components.create!(name: 'Piston 2', part_product_nature_variant: piston, parent: motor)
    end

    assert_raise ActiveRecord::RecordInvalid do
      tractor.components.create!(name: 'Nimp', part_product_nature_variant: tractor)
    end

    assert_raise ActiveRecord::RecordInvalid do
      tractor.components.create!(name: 'Nimp', part_product_nature_variant: tractor, parent: motor)
    end
  end
end
