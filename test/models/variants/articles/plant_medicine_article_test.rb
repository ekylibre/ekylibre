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
# == Table: product_nature_variants
#
#  active                    :boolean          default(FALSE), not null
#  category_id               :integer          not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  custom_fields             :jsonb
#  derivative_of             :string
#  france_maaid              :string
#  gtin                      :string
#  id                        :integer          not null, primary key
#  imported_from             :string
#  lock_version              :integer          default(0), not null
#  name                      :string
#  nature_id                 :integer          not null
#  number                    :string           not null
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  providers                 :jsonb
#  reference_name            :string
#  specie_variety            :string
#  stock_account_id          :integer
#  stock_movement_account_id :integer
#  type                      :string           not null
#  unit_name                 :string           not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  variety                   :string           not null
#  work_number               :string
#
require 'test_helper'

module Variants
  module Articles
    class PlantMedicineArticleTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

      test "changing a record's reference to lexicon is not possible if a link to another plant medicine is already established" do
        copless_variant = ProductNatureVariant.find_by_reference_name('2000087_copless')

        assert copless_variant.update(name: 'Random name')

        cases = [%w[imported_from Nomenclature], %w[reference_name fake_ref], %w[france_maaid 123456]]

        cases.each do |(attribute, value)|
          assert_raise ActiveRecord::RecordInvalid do
            copless_variant.update!(attribute => value)
          end
        end
      end
    end
  end
end
