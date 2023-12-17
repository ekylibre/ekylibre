class AddEntityOnBsi < ActiveRecord::Migration[5.2]
  def change
    add_reference :bank_statement_items, :entity, index: true
  end
end


