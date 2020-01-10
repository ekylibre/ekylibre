# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2019 Brice Texier, David Joulin
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

require 'test_helper'

class InventoryCreationTest < Ekylibre::Testing::ApplicationTestCase

  test 'Inventory build without a journal setup for it does not initialize it' do
    assert_nil Inventory.new.journal
  end

  test 'Inventory build with a journal for stocks is set as default' do
    j = create :journal, nature: :various, used_for_permanent_stock_inventory: true

    assert_equal j, Inventory.new.journal
  end

  test 'The journal provided at creation is not overriden' do
    j = create :journal, nature: :sales

    assert_equal j, Inventory.new(journal: j).journal
  end

end
