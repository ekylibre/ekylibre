class AddAttributesPurchaseOrder < ActiveRecord::Migration
  def change
    add_column :purchases, :command_mode, :string
    add_column :purchases, :estimate_reception_date, :datetime
  end
end
