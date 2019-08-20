class AddByDefaultToCashes < ActiveRecord::Migration
  def change
    add_column :cashes, :by_default, :boolean, default: false
  end
end
