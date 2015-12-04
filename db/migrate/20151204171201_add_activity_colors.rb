class AddActivityColors < ActiveRecord::Migration
  def change
    add_column :activities, :color, :string
  end
end
