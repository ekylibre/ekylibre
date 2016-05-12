class UpdateGradingAttributes < ActiveRecord::Migration
  def change
    # add a simple way to know if a product is ready to harvest or not
    add_column :products, :ready_to_harvest, :boolean, null: false, default: false
    # add a way to adapt net surface area before grading calculation
    add_column :product_gradings, :net_surface_area_in_hectare, :decimal, precision: 19, scale: 4
    # add a second grading calibre
    add_column :activities, :use_second_grading_calibre, :boolean, null: false, default: false
    add_column :activities, :second_grading_calibre_indicator_name, :string
    add_column :activities, :second_grading_calibre_unit_name, :string
  end
end