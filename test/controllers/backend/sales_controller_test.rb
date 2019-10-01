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
  class SalesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions cancel: :redirected_get,
                               contacts: :index_xhr,
                               except: %i[generate_parcel update]

    test 'should print an invoice' do
      sale = sales(:sales_001)
      assert sale.valid?, "Sales 001 must be valid (#{sale.errors.inspect})"
      DocumentTemplate.of_nature(:sales_invoice).update_all(active: false)
      template = DocumentTemplate.create!(nature: :sales_invoice, language: I18n.locale, name: 'sales_invoice', active: true, source: File.open(fixture_file('sales_invoice.jrxml')))
      assert template, 'No template found for sales_invoice'
      assert_nothing_raised do # "Template #{template.inspect} doesn't seems to work"
        get :show, id: sale.id, format: :pdf, key: sale.number, template: template.id
      end
      assert_response :success
    end

    test "can't create a sale for a fixed asset if it's invoiced before the fixed asset has started" do
      fixed_asset = create :fixed_asset, :in_use, started_on: Date.new(2018, 1, 1)
      variant = ProductNatureVariant.import_from_nomenclature(:tractor)
      sale_attrs = attributes_for(:sale).slice!(:state).merge(invoiced_at: DateTime.new(2017, 12, 31))
      sale_item_attrs = attributes_for(:sale_item, :fixed).merge(fixed_asset_id: fixed_asset.id, variant_id: variant.id)
      sale_attrs[:items_attributes] = { '0' => sale_item_attrs }

      post :create, sale: sale_attrs
      noko = Nokogiri::HTML(response.body)
      assert_equal 1, noko.css('.sale_invoiced_at.error').size
    end

    # TODO rewrite this as its not implemented this way anymore: a template_id need to be passed, and its this template that allow us to know if its jasper or not.
    # %i[estimate order invoice].each do |nature|
    #   test "should switch to Jasper if sales #{nature} document template exists" do
    #     sale = sales(:sales_001)
    #     class << @controller
    #       attr_accessor :called
    #       def create_response
    #         @called = true
    #         head 200
    #       end
    #     end
    #     get :show, id: sale.id, nature: nature, format: :pdf
    #     assert @controller.called
    #   end
    # end
  end
end
