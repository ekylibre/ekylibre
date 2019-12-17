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

module Printers
  module Sale
    class SalesInvoicePrinterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      setup do
        @template = Minitest::Mock.new
        @template.expect :nil?, false
        @template.expect :managed?, true
        @template.expect :nature, :shipping_note
      end

      teardown do
        @template.verify
      end

      test 'should print an estimate' do
        sale = sales(:sales_001)
        assert sale.valid?, "Sales 001 must be valid (#{sale.errors.inspect})"
        printer = SalesInvoicePrinter.new(template: @template, sale: sale)
        assert printer.run_pdf
      end
    end
  end
end

