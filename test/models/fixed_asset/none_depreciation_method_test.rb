require 'test_helper'

module FixedAssetTest
  class NoneDepreciationMethodTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    setup do
      @variant = ProductNatureVariant.import_from_nomenclature(:tractor)
      @entity = Entity.create!(last_name: 'JOHN DEERE SA')
      @address = @entity.addresses.create!(canal: 'mail', mail_line_1: 'Yolo', mail_line_2: 'Another test')

      @building_division_variant = ProductNatureVariant.import_from_nomenclature(:building_division)
      @storage = BuildingDivision.create!(
        variant: @building_division_variant,
        name: 'Tractor Stockage',
        initial_shape: Charta.new_geometry('SRID=4326;MULTIPOLYGON(((-0.813218951225281 45.5985699786537,-0.813113003969193 45.5985455816635,-0.81300538033247 45.5987766488858,-0.813106298446655 45.5987876744046,-0.813218951225281 45.5985699786537)))')
      )

      @product = @variant.products.create!(
        initial_container: @storage,
        initial_population: 1,
        name: 'JD 5201'
      )
      currency = 'EUR'

      @journal = Journal.where(nature: 'various', currency: currency).first
      @asset_account = Account.find_or_create_by_number('998765')
    end


    test 'stopped_on, allocation_account, expenses_account are not mandatory when a FixedAsset uses the :none depreciation method' do
      attributes = {
        name: @product.name,
        depreciable_amount: 50_000,
        depreciation_method: :none,
        started_on: Date.parse('2018-06-15'),
        asset_account: @asset_account,
        journal_id: @journal.id
      }

      fixed_asset = FixedAsset.new attributes
      valid = fixed_asset.valid?

      assert valid, fixed_asset.errors.messages.map { |_, v| v }.flatten
    end

    test 'a FixedAsset depreciated with :none method should not have any FixedAssetDepreciation' do
      attributes = {
        name: @product.name,
        depreciable_amount: 50_000,
        depreciation_method: :none,
        started_on: Date.parse('2018-06-15'),
        asset_account: @asset_account,
        journal_id: @journal.id
      }

      fixed_asset = FixedAsset.create! attributes

      assert_equal 0, fixed_asset.depreciations.count, "Should not have a depreciation"
    end

  end
end