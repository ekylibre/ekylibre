# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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

class ProductNatureVariantComponentTest < ActiveSupport::TestCase
  test 'test non recursivity of components' do
    tractor = ProductNatureVariant.import_from_nomenclature(:tractor)

    piston_params = {
      nature: ProductNature.import_from_nomenclature(:equipment),
      name: 'Piston B72 injection retro, alliage titane',
      unit_name: 'Piston'
    }
    piston = ProductNatureVariant.create!(piston_params)

    motor_v12_param = {
      nature: ProductNature.import_from_nomenclature(:equipment),
      name: 'Moteur V12 injection gtx 18L, 2013',
      unit_name: 'Moteur'
    }
    motor_v12 = ProductNatureVariant.create!(motor_v12_param)

    tractor.components.create!(name: 'Moteur', piece_variant: motor_v12)
    motor_v12.components.create!(name: 'Piston 1', piece_variant: piston)
    motor_v12.components.create!(name: 'Piston 2', piece_variant: piston)

    assert_raise ActiveRecord::RecordInvalid do
      motor_v12.components.create!(name: 'Piston 2', piece_variant: piston)
    end
    assert_raise ActiveRecord::RecordInvalid do
      motor_v12.components.create!(name: 'piston 2', piece_variant: piston)
    end

    assert_raise ActiveRecord::RecordInvalid do
      piston.components.create!(name: 'Nimp', piece_variant: tractor)
    end
  end
end
