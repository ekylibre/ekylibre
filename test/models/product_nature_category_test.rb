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
# == Table: product_nature_categories
#
#  active                              :boolean          default(FALSE), not null
#  asset_fixable                       :boolean          default(FALSE)
#  charge_account_id                   :integer
#  created_at                          :datetime         not null
#  creator_id                          :integer
#  custom_fields                       :jsonb
#  depreciable                         :boolean          default(FALSE), not null
#  description                         :text
#  fixed_asset_account_id              :integer
#  fixed_asset_allocation_account_id   :integer
#  fixed_asset_depreciation_method     :string
#  fixed_asset_depreciation_percentage :decimal(19, 4)   default(0.0)
#  fixed_asset_expenses_account_id     :integer
#  id                                  :integer          not null, primary key
#  imported_from                       :string
#  lock_version                        :integer          default(0), not null
#  name                                :string           not null
#  number                              :string           not null
#  pictogram                           :string
#  product_account_id                  :integer
#  purchasable                         :boolean          default(FALSE), not null
#  reductible                          :boolean          default(FALSE), not null
#  reference_name                      :string
#  saleable                            :boolean          default(FALSE), not null
#  stock_account_id                    :integer
#  stock_movement_account_id           :integer
#  storable                            :boolean          default(FALSE), not null
#  subscribing                         :boolean          default(FALSE), not null
#  type                                :string           not null
#  updated_at                          :datetime         not null
#  updater_id                          :integer
#
require 'test_helper'

class ProductNatureCategoryTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'type is correctly set upon import from nomenclature' do
    references = { animal: :adult_cat,
                   article: :animal_food,
                   crop: :crop,
                   equipment: :electronic_equipment,
                   service: :agricultural_taxe,
                   worker: :worker,
                   zone: :building }

    references.each { |type, reference| assert ProductNatureCategory.import_from_nomenclature(reference).is_a?("VariantCategories::#{type.capitalize}Category".constantize) }
  end

  test 'type is correctly set upon import from lexicon' do
    references = { animal: :adult_large_specie_animal,
                   article: :amortized_office_equipment,
                   crop: :amortized_plant,
                   equipment: :depreciable_tool,
                   service: :additional_activity,
                   worker: :associate,
                   zone: :amortized_installation }

    references.each { |type, reference| assert ProductNatureCategory.import_from_lexicon(reference).is_a?("VariantCategories::#{type.capitalize}Category".constantize) }
  end
end
