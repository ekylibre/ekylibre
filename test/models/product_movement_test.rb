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
# == Table: product_movements
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  delta           :decimal(19, 4)   not null
#  description     :string
#  id              :integer          not null, primary key
#  intervention_id :integer
#  lock_version    :integer          default(0), not null
#  originator_id   :integer
#  originator_type :string
#  population      :decimal(19, 4)   not null
#  product_id      :integer          not null
#  started_at      :datetime         not null
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#
require 'test_helper'

class ProductMovementTest < ActiveSupport::TestCase
  test_model_actions

  setup do
    @time = Time.now.utc
    @variant   = ProductNatureVariant.import_from_nomenclature(:beet)
    @container = ProductNatureVariant.import_from_nomenclature(:building).products.create!(name: 'Container')
    @product   = @variant.products.create!(
      name: 'Beets',
      initial_population: 10,
      initial_born_at: @time - 2.days,
      initial_container: @container
    )
    @other = @variant.products.create!(
      name: 'To be merged',
      initial_population: 5,
      initial_born_at: @time - 2.days,
      initial_container: @container
    )
  end

  test 'can\'t create a movement after a product has been merged' do
    ProductMerging.create!(product: @other, merged_with: @product, merged_at: @time - 1.day)

    assert_raise(ActiveRecord::RecordInvalid) { @other.move! 10.in_ton.to_d, at: @time }
  end
end
