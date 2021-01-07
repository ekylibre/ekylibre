class AddContainerAndLastNumberToCashes < ActiveRecord::Migration[4.2]
  def change
    add_reference :cashes, :container, index: true
    add_column :cashes, :last_number, :integer
  end
end
