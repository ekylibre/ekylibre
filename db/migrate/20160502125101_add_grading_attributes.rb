class AddGradingAttributes < ActiveRecord::Migration
  def change
    add_column :product_gradings, :implanter_application_width, :decimal, precision: 19, scale: 4
    add_column :product_gradings, :sampling_distance, :decimal, precision: 19, scale: 4
  end
end
