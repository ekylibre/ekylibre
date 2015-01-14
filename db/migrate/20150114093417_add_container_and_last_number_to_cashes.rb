class AddContainerAndLastNumberToCashes < ActiveRecord::Migration
  def change
    add_reference :cashes, :container, index: true
    add_column :cashes, :last_number, :integer
  end
end
