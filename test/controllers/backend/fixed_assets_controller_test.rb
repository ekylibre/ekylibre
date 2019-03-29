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
  class FixedAssetsControllerTest < ActionController::TestCase
    # TODO: Re-activate the #depreciate, #depreciate_all, #sell, #start_up and #scrap test
    test_restfully_all_actions except: %i[depreciate depreciate_all sell start_up scrap]

    test "update action should not modify depreciation_percentage if not in parameters" do
      @variant = ProductNatureVariant.import_from_nomenclature(:tractor)
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

      @waiting_account = Account.find_or_import_from_nomenclature :suspense
      @asset_account = Account.find_or_create_by_number('998765')
      @allocation_account = Account.find_or_create_by_number('998764')
      @expenses_account = Account.find_or_create_by_number('998763')
      FinancialYear.delete_all
      [2016, 2017].each do |year|
        assert fy = FinancialYear.create(started_on: Date.new(year, 1, 1), stopped_on: Date.new(year, 12, 31))
      end
      fa = FixedAsset.new(
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
      fa.save!
      fa.start_up

      patch :update, id: fa.id, fixed_asset: { sold_on: "2017-05-08" }
      fa.reload
      assert_equal 10, fa.depreciation_percentage.to_i
    end
  end
end
