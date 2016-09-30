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
# == Table: product_nature_variants
#
#  active                    :boolean          default(FALSE), not null
#  category_id               :integer          not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  custom_fields             :jsonb
#  derivative_of             :string
#  gtin                      :string
#  id                        :integer          not null, primary key
#  lock_version              :integer          default(0), not null
#  name                      :string
#  nature_id                 :integer          not null
#  number                    :string           not null
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  reference_name            :string
#  stock_account_id          :integer
#  stock_movement_account_id :integer
#  unit_name                 :string           not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  variety                   :string           not null
#  work_number               :string
#
require 'test_helper'

class ProductNatureVariantTest < ActiveSupport::TestCase
  test_model_actions
  test 'working sets' do
    Nomen::WorkingSet.list.each do |item|
      assert ProductNatureVariant.of_working_set(item.name).count >= 0
    end
  end

  test 'flattened nomenclature' do
    assert ProductNatureVariant.flattened_nomenclature
    assert ProductNatureVariant.flattened_nomenclature.respond_to?(:any?)
    assert ProductNatureVariant.flattened_nomenclature.any?
    assert ProductNatureVariant.items_of_expression('is triticum').any?
    assert ProductNatureVariant.items_of_expression('is triticum or is bos_taurus').any?
  end
end
