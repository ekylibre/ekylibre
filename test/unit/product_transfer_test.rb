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
# == Table: product_transfers
#
#  arrival_move_id        :integer          
#  arrival_stock_id       :integer          
#  arrival_warehouse_id   :integer          
#  comment                :text             
#  created_at             :datetime         not null
#  creator_id             :integer          
#  departure_move_id      :integer          
#  departure_stock_id     :integer          
#  departure_warehouse_id :integer          
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  moved_at               :datetime         not null
#  nature                 :string(255)      not null
#  number                 :string(255)      not null
#  product_id             :integer          not null
#  quantity               :decimal(19, 4)   not null
#  unit_id                :integer          not null
#  updated_at             :datetime         not null
#  updater_id             :integer          
#


require 'test_helper'

class ProductTransferTest < ActiveSupport::TestCase


  test "simple transfert" do
    emitter  = product_stocks(:product_stocks_001)
    receiver = product_stocks(:product_stocks_003)
    assert_equal emitter.product_id, receiver.product_id, "Emitter and receiver stocks must use the same product"
    unit = emitter.product.unit.name
    source_quantity = emitter.real_quantity
    target_quantity = receiver.real_quantity
    transfered_quantity = source_quantity / 2
    transfer = nil
    # assert_nothing_raised do
    transfer = ProductTransfer.create!(:departure_stock => emitter, :arrival_stock => receiver, :nature => 'transfer', :quantity => transfered_quantity, :moved_at => Time.now)
    # end
    assert_not_nil transfer
    assert_equal ProductTransfer, transfer.class
    assert_not_nil transfer.stock_move, "Departure stock move cannot be nil"
    assert_equal source_quantity - transfered_quantity, emitter.reload.real_quantity, "Emitter stock must be reduced from #{source_quantity}#{unit} to #{source_quantity - transfered_quantity}#{unit}"
    assert_equal -transfered_quantity, transfer.departure_move.quantity, "Departure stock move quantity must be equal to #{-transfered_quantity}#{unit}"

    assert_not_nil transfer.arrival_move, "Arrival stock move cannot be nil"
    assert_equal transfered_quantity, transfer.arrival_move.quantity, "Arrival stock move quantity must be equal to #{transfered_quantity}#{unit}"
    assert_equal receiver, transfer.arrival_move.stock, "Arrival stock move stock must be equal to receiver stock"
    assert_equal target_quantity + transfered_quantity, receiver.reload.quantity, "Receiver stock must be increased from #{target_quantity}#{unit} to #{target_quantity + transfered_quantity}#{unit}"
  end

end
