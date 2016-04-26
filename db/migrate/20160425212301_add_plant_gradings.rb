class AddPlantGradings < ActiveRecord::Migration
  def change
    add_column :activities, :use_gradings, :boolean, null: false, default: false

    create_table :product_grades do |t|
      t.references :grading_nature, null: false, index: true
      t.string :name, null: false, index: true
      t.string :indicator_name
      t.string :indicator_datatype
      t.string :grade_unit, null: false
      t.decimal :minimum_grade_value, precision: 19, scale: 4
      t.decimal :maximum_grade_value, precision: 19, scale: 4
      t.stamps
    end

    create_table :product_qualities do |t|
      t.string :name, null: false, index: true
      t.string :reference_name
      t.string :category
      t.stamps
    end

    create_table :grading_natures do |t|
      t.references :activity, null: false, index: true
      t.string :name, null: false, index: true
      t.string :grade_indicator_name
      t.string :grade_unit, null: false
      t.string :extremum_indicator_name
      t.string :extremum_unit, null: false
      t.stamps
    end

    create_table :product_qualities_grading_natures, id: false do |t|
      t.belongs_to :product_grade, index: true
      t.belongs_to :grading_quality, index: true
    end

    create_table :gradings do |t|
      t.references :product, null: false, index: true
      t.string :number, null: false
      t.datetime :sampled_at, null: false
      t.integer :implanter_lines_number
      t.decimal :implanter_lines_gap, precision: 19, scale: 4
      t.text :comment
      t.stamps
    end

    create_table :grading_items do |t|
      t.references :grading, null: false, index: true
      t.references :product_grade
      t.references :product_quality
      t.integer :population
      t.decimal :net_mass_value, precision: 19, scale: 4
      t.string  :net_mass_unit
      t.decimal :minimum_grade_value, precision: 19, scale: 4
      t.decimal :maximum_grade_value, precision: 19, scale: 4
      t.stamps
    end
  end
end