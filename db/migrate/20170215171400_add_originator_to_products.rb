class AddOriginatorToProducts < ActiveRecord::Migration[4.2]
  def change
    add_reference :products, :originator, index: true
  end
end
