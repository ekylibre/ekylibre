class AddAttributesPurchaseOrder < ActiveRecord::Migration
  def change
    unless column_exists? :purchases, :command_mode
      add_column :purchases, :command_mode, :string
    end
    unless column_exists? :purchases, :estimate_reception_date
      add_column :purchases, :estimate_reception_date, :datetime
    end
  end
end
