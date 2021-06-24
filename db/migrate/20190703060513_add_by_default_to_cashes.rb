class AddByDefaultToCashes < ActiveRecord::Migration[4.2]
  def change
    add_column :cashes, :by_default, :boolean, default: false
  end
end
