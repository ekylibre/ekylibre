# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'test_helper'
module Backend
  class FixedAssetsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate the #depreciate, #depreciate_all, #sell, #start_up and #scrap test
    test_restfully_all_actions except: %i[depreciate depreciate_all sell start_up scrap link_to_sale stand_by]

    test "update action should not modify depreciation_percentage if not in parameters" do
      manual_setup

      patch :update, id: @fixed_asset.id, fixed_asset: { sold_on: "2017-05-08" }
      @fixed_asset.reload
      assert_equal 10, @fixed_asset.depreciation_percentage.to_i
    end

    test "should display financial year index without any financial year and disable buttons and field" do
      FinancialYear.delete_all
      get :index
      assert_equal 200, response.status
      noko = Nokogiri::HTML(response.body)
      assert_equal 2, noko.css('a.disabled').size
      assert_equal 1, noko.css("#depreciate-fixed-assets-until[disabled='disabled']").size
    end

    cases = [[:scrapping, :scrap, :scrapped_on], [:selling, :sell, :sold_on]]

    cases.each do |(action, mode, attribute)|
      test "edition before #{action} is only possible if the user provides a product and a valid #{attribute} date" do
        manual_setup

        create :sale_item, :fixed, variant: @variant, fixed_asset: @fixed_asset
        @fixed_asset.reload

        patch :update, id: @fixed_asset.id, fixed_asset: @fixed_asset.attributes, mode: mode
        noko = Nokogiri::HTML(response.body)
        assert_equal 1, noko.css('.fixed_asset_product.error').size
        assert_equal 1, noko.css(".fixed_asset_#{attribute}.error").size

        @fixed_asset.update!(product: @product)

        # Case where attribute < @fixed_asset.started_on
        patch :update, id: @fixed_asset.id, fixed_asset: { attribute => Date.new(2007, 12, 31) }, mode: mode
        noko = Nokogiri::HTML(response.body)
        assert_equal 0, noko.css('.fixed_asset_product.error').size
        assert_equal 1, noko.css(".fixed_asset_#{attribute}.error").size

        # Case where attribute is outside an opened financial year
        patch :update, id: @fixed_asset.id, fixed_asset: { attribute => Date.new(2018, 1, 1) }, mode: mode
        noko = Nokogiri::HTML(response.body)
        assert_equal 0, noko.css('.fixed_asset_product.error').size
        assert_equal 1, noko.css(".fixed_asset_#{attribute}.error").size

        # Case where attribute < @fixed_asset.product.born_at
        equipment = create :asset_fixable_product, born_at: DateTime.new(2018, 6, 1)
        @fixed_asset.update!(product: equipment)

        patch :update, id: @fixed_asset.id, fixed_asset: { attribute => Date.new(2018, 1, 1) }, mode: mode
        noko = Nokogiri::HTML(response.body)
        assert_equal 0, noko.css('.fixed_asset_product.error').size
        assert_equal 1, noko.css(".fixed_asset_#{attribute}.error").size
      end
    end

    test "edition before putting on hold is only possible if the user provides a valid waiting_on date" do
      fixed_asset = create :fixed_asset, started_on: Date.new(2008, 1, 1)

      # Case where no waiting_on is provided
      patch :update, id: fixed_asset.id, fixed_asset: fixed_asset.attributes, mode: 'stand_by'
      noko = Nokogiri::HTML(response.body)
      assert_equal 1, noko.css('.fixed_asset_waiting_on.error').size

      # Case where waiting_on > fixed_asset.started_on
      patch :update, id: fixed_asset.id, fixed_asset: { waiting_on: Date.new(2008, 12, 31) }, mode: 'stand_by'
      noko = Nokogiri::HTML(response.body)
      assert_equal 1, noko.css(".fixed_asset_waiting_on.error").size
    end

    private

      def manual_setup
        @variant = ProductNatureVariant.import_from_nomenclature(:tractor)
        @building_division_variant = ProductNatureVariant.import_from_nomenclature(:building_division)
        @storage = BuildingDivision.create!(
          variant: @building_division_variant,
          name: 'Tractor Stockage',
          initial_shape: Charta.new_geometry('SRID=4326;MULTIPOLYGON(((-0.813218951225281 45.5985699786537,-0.813113003969193 45.5985455816635,-0.81300538033247 45.5987766488858,-0.813106298446655 45.5987876744046,-0.813218951225281 45.5985699786537)))')
        )

        @product = create :asset_fixable_product, born_at: DateTime.new(2008, 1, 1),
                                                  variant: @variant,
                                                  initial_container: @storage,
                                                  initial_population: 1,
                                                  name: 'JD 5201'

        currency = 'EUR'
        @journal = Journal.where(nature: 'various', currency: currency).first

        @waiting_account = Account.find_or_import_from_nomenclature :suspense
        @asset_account = Account.find_or_create_by_number('998765')
        @allocation_account = Account.find_or_create_by_number('998764')
        @expenses_account = Account.find_or_create_by_number('998763')
        FinancialYear.delete_all
        [2016, 2017].each do |year|
          assert fy = FinancialYear.create(started_on: Date.new(year, 1, 1), stopped_on: Date.new(year, 12, 31))
        end
        @fixed_asset = FixedAsset.new(
          name: @product.name,
          depreciable_amount: 50_000,
          depreciation_method: :linear,
          depreciation_percentage: 10,
          started_on: '2008-01-01',
          journal: @journal,
          asset_account: @asset_account,
          expenses_account: @expenses_account,
          allocation_account: @allocation_account
        )

        assert @fixed_asset.valid?
        @fixed_asset.save!

        @fixed_asset.start_up

        @fixed_asset.reload
      end
  end
end
