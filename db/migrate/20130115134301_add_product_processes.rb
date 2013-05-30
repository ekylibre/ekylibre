# -*- coding: utf-8 -*-
class AddProductProcesses< ActiveRecord::Migration

  def change

    create_table :product_indicators do |t|
      t.references :process
      t.string     :name,   :null => false
      t.string     :nature, :null => false  # decimal, measure, string, boolean ou choice
      t.string     :usage                   # notion métiers avec enumerize
      t.references :unit
      t.integer    :minimal_length
      t.integer    :maximal_length
      t.decimal    :minimal_value,   :precision => 19, :scale => 4
      t.decimal    :maximal_value,   :precision => 19, :scale => 4
      t.boolean    :active, :null => false, :default => false
      t.text       :comment
      t.stamps
    end
    add_stamps_indexes :product_indicators
    add_index :product_indicators, :process_id
    add_index :product_indicators, :unit_id

    create_table :product_indicator_choices do |t|
      t.references :indicator, :null => false
      t.string     :name, :null => false
      t.string     :value # valeur de l'indicateur si besoin (coefficient)
      t.integer    :position
      t.text       :comment
      t.stamps
    end
    add_stamps_indexes :product_indicator_choices
    add_index :product_indicator_choices, :indicator_id

    create_table :product_indicator_data do |t|
      t.references :product, :null => false
      t.references :indicator,  :null => false
      t.datetime   :measured_at, :null => false
      t.text       :comment
      t.decimal    :decimal_value,   :precision => 19, :scale => 4
      t.decimal    :measure_value,   :precision => 19, :scale => 4
      t.references :measure_unit # Nécessaire pour l'historique, permet de recouper les donner en cas de crash
      t.text       :string_value
      t.boolean    :boolean_value, :null => false, :default => false
      t.integer    :choice_value_id
      t.stamps
    end
    add_stamps_indexes :product_indicator_data
    add_index :product_indicator_data, :product_id
    add_index :product_indicator_data, :indicator_id
    add_index :product_indicator_data, :measure_unit_id
    add_index :product_indicator_data, :choice_value_id


    create_table :product_process_phases do |t|
      t.references :process, :null => false
      t.string     :name,    :null => false
      t.string     :nature,  :null => false  # Work notion
      t.integer    :position
      t.string     :phase_delay
      t.string     :comment
      t.stamps
    end
    add_stamps_indexes :product_process_phases
    add_index :product_process_phases, :process_id

    create_table :product_processes do |t|
      t.string     :variety, :null => false, :limit => 127
      t.string     :name,   :null => false
      t.string     :nature, :null => false # Work notion
      t.string     :comment
      t.boolean    :repeatable, :null => false, :default => false
      t.stamps
    end
    add_stamps_indexes :product_processes
    add_index :product_processes, :variety

  end

end
