class AddManureManagementPlanTables < ActiveRecord::Migration
  def change
    create_table :manure_management_plans do |t|
      t.string :name, null: false
      t.references :campaign,       null: false, index: true
      t.references :recommender,    null: false, index: true
      t.datetime :opened_at,      null: false
      t.string :default_computation_method, null: false
      t.boolean :locked,         null: false, default: false
      t.boolean :selected,       null: false, default: false
      # t.string     :exploitation_typology
      t.text :annotation
      t.stamps
    end

    create_table :manure_management_plan_zones do |t|
      t.references :plan,                 null: false, index: true
      t.references :support,              null: false, index: true
      t.string :computation_method, null: false
      t.string :administrative_area
      t.string :cultivation_variety
      t.string :soil_nature
      t.decimal :expected_yield,                                  precision: 19, scale: 4
      t.decimal :nitrogen_need,                                   precision: 19, scale: 4
      t.decimal :absorbed_nitrogen_at_opening,                    precision: 19, scale: 4
      t.decimal :mineral_nitrogen_at_opening,                     precision: 19, scale: 4
      t.decimal :humus_mineralization,                            precision: 19, scale: 4
      t.decimal :meadow_humus_mineralization,                     precision: 19, scale: 4
      t.decimal :previous_cultivation_residue_mineralization,     precision: 19, scale: 4
      t.decimal :intermediate_cultivation_residue_mineralization, precision: 19, scale: 4
      t.decimal :irrigation_water_nitrogen,                       precision: 19, scale: 4
      t.decimal :organic_fertilizer_mineral_fraction,             precision: 19, scale: 4
      t.decimal :nitrogen_at_closing,                             precision: 19, scale: 4
      t.decimal :soil_production,                                 precision: 19, scale: 4
      t.decimal :nitrogen_input,                                  precision: 19, scale: 4
      t.stamps
    end
  end
end
