# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: stock_transfers
#
#  comment              :text             
#  created_at           :datetime         not null
#  creator_id           :integer          
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  moved_on             :date             
#  nature               :string(8)        not null
#  number               :string(64)       not null
#  planned_on           :date             not null
#  product_id           :integer          not null
#  quantity             :decimal(19, 4)   not null
#  second_stock_move_id :integer          
#  second_warehouse_id  :integer          
#  stock_move_id        :integer          
#  tracking_id          :integer          
#  unit_id              :integer          
#  updated_at           :datetime         not null
#  updater_id           :integer          
#  warehouse_id         :integer          not null
#


require 'test_helper'

class StockTransferTest < ActiveSupport::TestCase


  test "simple transfert" do
    emitter  = stocks(:stocks_001)
    receiver = stocks(:stocks_003)
    assert_equal emitter.product_id, receiver.product_id, "Emitter and receiver stocks must use the same product"
    unit = emitter.product.unit.name
    source_quantity = emitter.quantity
    target_quantity = receiver.quantity
    transfered_quantity = source_quantity / 2
    transfer = nil
    # assert_nothing_raised do
    transfer = StockTransfer.create!(:product_id => emitter.product_id, :warehouse_id => emitter.warehouse_id, :second_warehouse_id => receiver.warehouse_id, :nature => 'transfer', :quantity => transfered_quantity, :planned_on => Date.today)
    # end
    assert_not_nil transfer
    assert_equal StockTransfer, transfer.class
    assert_not_nil transfer.stock_move, "First stock move cannot be nil"
    assert_equal source_quantity - transfered_quantity, emitter.reload.quantity, "Emitter stock must be reduced from #{source_quantity}#{unit} to #{source_quantity - transfered_quantity}#{unit}"
    assert_equal -transfered_quantity, transfer.stock_move.quantity, "First stock move quantity must be equal to #{-transfered_quantity}#{unit}"

    assert_not_nil transfer.second_stock_move, "Second stock move cannot be nil"
    assert_equal transfered_quantity, transfer.second_stock_move.quantity, "Second stock move quantity must be equal to #{transfered_quantity}#{unit}"
    assert_equal receiver, transfer.second_stock_move.stock, "Second stock move stock must be equal to receiver stock"
    assert_equal target_quantity + transfered_quantity, receiver.reload.quantity, "Receiver stock must be increased from #{target_quantity}#{unit} to #{target_quantity + transfered_quantity}#{unit}"
  end

end
