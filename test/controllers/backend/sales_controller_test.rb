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
      nature = 'invoice'
      sale = sales(:sales_001)
      user = users(:users_001)
      key = "Chuck Norris can't test for equality because he has no equal."
      assert sale.valid?, "Sales 001 must be valid (#{sale.errors.inspect})"
      printer = SalesInvoicePrinter.new(sale)
      file_path = printer.run_pdf
      begin
        assert File.exist?(file_path)
      ensure
        File.delete(file_path) if File.exist?(file_path)
      end
    end

    test 'should print an estimate' do
      nature = 'estimate'
      sale = sales(:sales_001)
      user = users(:users_001)
      key = 'Chuck Norris can unit test an entire application with a single assert.'
      assert sale.valid?, "Sales 001 must be valid (#{sale.errors.inspect})"
      printer = SalesInvoicePrinter.new(sale)
      file_path = printer.run_pdf
      begin
        assert File.exist?(file_path)
      ensure
        File.delete(file_path) if File.exist?(file_path)
      end
    end

    test 'should print an order' do
      nature = 'order'
      sale = sales(:sales_001)
      user = users(:users_001)
      key = "Chuck Norris' keyboard doesn't have F1 key, the computer asks for help from him."
      assert sale.valid?, "Sales 001 must be valid (#{sale.errors.inspect})"
      printer = SalesInvoicePrinter.new(sale)
      file_path = printer.run_pdf
      begin
        assert File.exist?(file_path)
      ensure
        File.delete(file_path) if File.exist?(file_path)
      end
    end
  end
end
