class AddCustomNameColumnToProduction < ActiveRecord::Migration
  def change
    add_column :activity_productions, :custom_name, :string
  end
end
