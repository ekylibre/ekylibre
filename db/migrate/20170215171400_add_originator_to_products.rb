class AddOriginatorToProducts < ActiveRecord::Migration
  def change
    add_reference :products, :originator, index: true
  end
end
