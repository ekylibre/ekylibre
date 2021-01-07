class AddCustomNameColumnToProduction < ActiveRecord::Migration[4.2]
  def change
    add_column :activity_productions, :custom_name, :string
  end
end
