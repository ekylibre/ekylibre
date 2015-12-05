class AddActivityColors < ActiveRecord::Migration
  def change
    add_column :activities, :color, :string
    # FIXME: Load colors for existing activities
  end
end
