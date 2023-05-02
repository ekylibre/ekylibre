# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
#  active                    :boolean          default(TRUE), not null
#  category_id               :integer(4)       not null
#  created_at                :datetime         not null
#  creator_id                :integer(4)
#  custom_fields             :jsonb
#  default_quantity          :decimal(19, 4)   default(1), not null
#  default_unit_id           :integer(4)       not null
#  default_unit_name         :string           not null
#  derivative_of             :string
#  france_maaid              :string
#  gtin                      :string
#  id                        :integer(4)       not null, primary key
#  imported_from             :string
#  lock_version              :integer(4)       default(0), not null
#  name                      :string           not null
#  nature_id                 :integer(4)       not null
#  number                    :string           not null
#  pictogram                 :string
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer(4)
#  picture_updated_at        :datetime
#  provider                  :jsonb
#  providers                 :jsonb
#  reference_name            :string
#  specie_variety            :string
#  stock_account_id          :integer(4)
#  stock_movement_account_id :integer(4)
#  type                      :string           not null
#  unit_name                 :string
#  updated_at                :datetime         not null
#  updater_id                :integer(4)
#  variety                   :string           not null
#  work_number               :string
#
require 'test_helper'

class ProductNatureVariantTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  setup do
    Crumb.delete_all
    InterventionWorkingPeriod.delete_all
    InterventionParticipation.delete_all
    ParcelItem.delete_all
    Parcel.delete_all
    SaleItem.delete_all
    Sale.delete_all
    ProductNature.delete_all
    ParcelItemStoring.delete_all
    Product.delete_all
    ProductNatureCategory.delete_all
    JournalEntryItem.delete_all
    ProductNatureVariant.delete_all
    Payslip.delete_all
    PayslipNature.delete_all
    Account.delete_all
  end

  test "type is computed from category and variant at each validation" do
    cat = create(:animal_category)
    nature = create(:animals_nature)

    pnv = ProductNatureVariant.new(
      type: "Variants::ArticleVariant",
      category: cat,
      nature: nature
    )

    assert_equal "Variants::ArticleVariant", pnv.type

    pnv.valid?

    assert_equal "Variants::AnimalVariant", pnv.type
  end

  test 'working sets' do
    Onoma::WorkingSet.list.each do |item|
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
    assert_nothing_raised { ProductNatureVariant.import_from_nomenclature(:seedling) }
    Account.accounting_system = 'fr_pcga'
    assert_nothing_raised { ProductNatureVariant.import_from_nomenclature(:seedling) }
  end

  test 'current_outgoing_stock_ordered_not_delivered returns the right amount of variants when sale state is set to order and shipment state to prepared' do
    variant = create(:product_nature_variant)
    sale = create(:sale)
    create(:sale_item, sale: sale, variant: variant, quantity: 50.to_d)
    sale.propose!
    sale.confirm!(DateTime.parse('2018-01-01T00:00:00Z'))
    shipment = create(:shipment, sale: sale)
    shipment.update(state: 'prepared')
    assert_equal 50.0, variant.current_outgoing_stock_ordered_not_delivered
  end

  test 'current_outgoing_stock_ordered_not_delivered returns the right amount of variants when sale state is set to draft and shipment state to draft' do
    variant = create(:product_nature_variant)
    sale = create(:sale)
    create(:sale_item, sale: sale, variant: variant, quantity: 50.to_d)
    shipment = create(:shipment, sale: sale)
    assert_equal 0, variant.current_outgoing_stock_ordered_not_delivered
  end

  test 'current_outgoing_stock_ordered_not_delivered returns the right amount of variants when sale state is set to order and shipment state to given' do
    variant = create(:product_nature_variant)
    product = create(:product, variant: variant)
    sale = create(:sale, invoiced_at: DateTime.parse('2018-01-02T00:00:00Z'))
    create(:sale_item, sale: sale, variant: variant, quantity: 50.to_d)
    sale.propose!
    sale.confirm!(DateTime.parse('2018-01-01T00:00:00Z'))
    shipment = create(:shipment, sale: sale)
    create(:shipment_item, shipment: shipment, variant: variant, population: 1.to_d, source_product: product, product_identification_number: '12345678', product_name: 'Product name')
    shipment.update(state: 'given')
    assert_equal 49.0, variant.current_outgoing_stock_ordered_not_delivered
  end

  test 'current_outgoing_stock_ordered_not_delivered returns the right amount of variants when shipment state is set to prepared and there is no sale related' do
    variant = create(:product_nature_variant)
    shipment = create(:shipment)
    product = create(:product, variant: variant)
    create(:shipment_item, shipment: shipment, source_product: product, population: 1.to_d)
    shipment.update(state: 'prepared')
    assert_equal 1, variant.current_outgoing_stock_ordered_not_delivered
  end

  test "services' stocks are computed correctly" do
    service = create(:service_variant)
    purchase = create(:purchase_order)
    create(:purchase_item, purchase: purchase, variant: service, conditioning_quantity: 50)

    assert_equal service.quantity_purchased, 50
    assert_equal service.current_stock, 50

    reception = create(:reception)
    create(:reception_item, reception: reception, variant: service, conditioning_quantity: 30)

    assert_equal service.quantity_received, 0
    assert_equal service.current_stock, 50

    reception.update(state: 'given')

    assert_equal service.quantity_received, 30
    assert_equal service.current_stock, 20
  end

  test 'type is correctly set upon import from nomenclature' do
    references = { animal: :bee_band,
                   article: :acetal,
                   crop: :annual_fallow_crop,
                   equipment: :animal_medicine_tank,
                   service: :accommodation_taxe,
                   worker: :employee,
                   zone: :animal_building }

    references.each { |type, reference| assert_equal "Variants::#{type.capitalize}Variant", ProductNatureVariant.import_from_nomenclature(reference).type }

    article_references = { plant_medicine: :additive, fertilizer: :bulk_ammo_phosphorus_sulfur_20_23_0, seed_and_plant: :ascott_wheat_seed_25 }
    article_references.each { |type, reference| assert_equal "Variants::Articles::#{type.to_s.classify}Article", ProductNatureVariant.import_from_nomenclature(reference).type }
  end

  test 'type is correctly set upon import from lexicon' do
    references = { article: :stake,
                   equipment: :geolocation_box,
                   service: :additional_activity,
                   worker: :permanent_worker }

    references.each { |type, reference| assert ProductNatureVariant.import_from_lexicon(reference).is_a?("Variants::#{type.capitalize}Variant".constantize) }

    article_references = { plant_medicine: '2000085_zebra', fertilizer: :horse_manure, seed_and_plant: :common_wheat_seed }
    article_references.each { |type, reference| assert ProductNatureVariant.import_from_lexicon(reference).is_a?("Variants::Articles::#{type.to_s.classify}Article".constantize) }
  end

  test 'type is correctly set upon creation through model validations' do
    references = { animal: :animal_variant,
                   article: :harvest_variant,
                   crop: :plant_variant,
                   equipment: :equipment_variant,
                   service: :service_variant,
                   worker: :worker_variant,
                   zone: :land_parcel_variant }

    references.each { |type, reference| assert_equal "Variants::#{type.capitalize}Variant", create(reference).type }

    article_references = { plant_medicine: :phytosanitary_variant, fertilizer: :fertilizer_variant, seed_and_plant: :seed_variant }
    article_references.each { |type, reference| assert_equal "Variants::Articles::#{type.to_s.classify}Article", create(reference).type }
  end

  test 'guess_conditioning' do
    Unit.load_defaults
    variant = create :seed_variant
    conditioning_data = variant.guess_conditioning

    assert_includes Unit.where(reference_name: %i[kilogram]), conditioning_data[:unit]
    assert_equal 1, conditioning_data[:quantity]

    variant.update!(default_quantity: 14)
    conditioning_data = variant.guess_conditioning

    assert_includes Unit.where(reference_name: %i[kilogram]), conditioning_data[:unit]
    assert_equal 14, conditioning_data[:quantity]

    variant.update!(default_quantity: 100)
    conditioning_data = variant.guess_conditioning

    assert_equal Unit.find_by_reference_name('quintal'), conditioning_data[:unit]
    assert_equal 1, conditioning_data[:quantity]
  end

  test 'create and update change the default unit name' do
    pnv = create(:product_nature_variant, default_unit: Unit.find_by(reference_name: :kilogram))
    pnv.update!(default_unit: Unit.find_by(reference_name: :unity))
    assert_equal 'unity', pnv.default_unit_name
  end
end
