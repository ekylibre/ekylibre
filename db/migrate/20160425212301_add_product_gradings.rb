class AddProductGradings < ActiveRecord::Migration
  def change
    create_table :grading_quality_criteria do |t|
      t.string :name, null: false
      t.stamps
      t.index :name
    end

    add_column :activities, :use_gradings, :boolean, null: false, default: false

    add_column :activities, :use_grading_calibre, :boolean, null: false, default: false
    add_column :activities, :grading_calibre_indicator_name, :string
    add_column :activities, :grading_calibre_unit_name, :string

    add_column :activities, :measure_grading_items_count, :boolean, null: false, default: false

    add_column :activities, :measure_grading_net_mass, :boolean, null: false, default: false
    add_column :activities, :grading_net_mass_unit_name, :string

    add_column :activities, :measure_grading_sizes, :boolean, null: false, default: false
    add_column :activities, :grading_sizes_indicator_name, :string
    add_column :activities, :grading_sizes_unit_name, :string

    create_table :activity_grading_checks do |t|
      t.references :activity, null: false, index: true
      t.string :nature, null: false # => calibre, quality
      t.decimal :minimal_calibre_value, precision: 19, scale: 4
      t.decimal :maximal_calibre_value, precision: 19, scale: 4
      t.references :quality_criterion, index: true
      t.integer :position
      t.stamps
    end

    create_table :product_gradings do |t|
      t.references :activity, null: false, index: true
      t.references :product, null: false, index: true
      t.string :number, null: false
      t.datetime :sampled_at, null: false
      t.integer :implanter_rows_number
      t.decimal :implanter_working_width, precision: 19, scale: 4 # (meter) ?
      t.text :comment
      t.stamps
    end

    create_table :product_grading_checks do |t|
      t.references :product_grading, null: false, index: true
      t.references :activity_grading_check, null: false, index: true
      t.integer :items_count
      t.decimal :net_mass_value, precision: 19, scale: 4
      t.decimal :minimal_size_value, precision: 19, scale: 4
      t.decimal :maximal_size_value, precision: 19, scale: 4
      t.stamps
    end
  end
end
