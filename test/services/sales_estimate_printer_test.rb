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

class SalesEstimatePrinterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
  test 'should print an estimate' do
    sale = sales(:sales_001)
    assert sale.valid?, "Sales 001 must be valid (#{sale.errors.inspect})"
    printer = SalesEstimatePrinter.new(sale)
    file_path = printer.run_pdf
    begin
      assert File.exist?(file_path)
    ensure
      File.delete(file_path) if File.exist?(file_path)
    end
  end
end
