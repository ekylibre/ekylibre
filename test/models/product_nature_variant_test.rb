# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2019 Ekylibre SAS
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

  setup do
    Crumb.delete_all
    InterventionWorkingPeriod.delete_all
    InterventionParticipation.delete_all
    ParcelItem.delete_all
    Parcel.delete_all
    SaleItem.delete_all
    Sale.delete_all
    ProductNatureCategory.delete_all
    ProductNature.delete_all
    Product.delete_all
    JournalEntryItem.delete_all
    ProductNatureVariant.delete_all
    Payslip.delete_all
    PayslipNature.delete_all
    Account.delete_all
  end

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

  test 'import from nomenclature seedling' do
    # Seedling PNV doesn't exist on fr_pcg82 so it should raise an error when attempting to import it from nomenclature on this accounting system
    Account.accounting_system = 'fr_pcg82'
    assert_raise { ProductNatureVariant.import_from_nomenclature(:seedling) }
    Account.accounting_system = 'fr_pcga'
    assert_nothing_raised { ProductNatureVariant.import_from_nomenclature(:seedling) }
  end

  test 'current_outgoing_stock_ordered_not_delivered returns the right amount of variants when sale state is set to order and parcel state to prepared' do
    variant = create(:product_nature_variant)
    sale = create(:sale)
    sale.update(state: 'order')
    create(:sale_item, sale: sale, variant: variant, quantity: 50.to_d)
    parcel = create(:parcel, sale: sale)
    parcel.update(state: 'prepared')
    assert_equal 50.0, variant.current_outgoing_stock_ordered_not_delivered
  end

  test 'current_outgoing_stock_ordered_not_delivered returns the right amount of variants when sale state is set to draft and parcel state to draft' do
    variant = create(:product_nature_variant)
    sale = create(:sale)
    create(:sale_item, sale: sale, variant: variant, quantity: 50.to_d)
    parcel = create(:parcel, sale: sale)
    assert_equal 0, variant.current_outgoing_stock_ordered_not_delivered
  end

  test 'current_outgoing_stock_ordered_not_delivered returns the right amount of variants when sale state is set to order and parcel state to given' do
    variant = create(:product_nature_variant)
    product = create(:product)
    sale = create(:sale)
    sale.update(state: 'order')
    create(:sale_item, sale: sale, variant: variant, quantity: 50.to_d)
    parcel = create(:parcel, sale: sale)
    create(:parcel_item, parcel: parcel, variant: variant, population: 1.to_d, product: product, product_identification_number: '12345678', product_name: 'Product name')
    parcel.update(state: 'given')
    assert_equal 49.0, variant.current_outgoing_stock_ordered_not_delivered
  end

  test 'current_outgoing_stock_ordered_not_delivered returns the right amount of variants when parcel state is set to prepared and there is no sale related' do
    variant = create(:product_nature_variant)
    parcel = create(:outgoing_parcel)
    product = create(:product, variant: variant)
    t = create(:outgoing_parcel_item, parcel: parcel, source_product: product, population: 1.to_d)
    parcel.update(state: 'prepared')
    assert_equal 1, variant.current_outgoing_stock_ordered_not_delivered
  end
end
