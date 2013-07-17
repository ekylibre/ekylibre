# -*- coding: utf-8 -*-
class AddProductProcesses< ActiveRecord::Migration

  def change

    # create_table :product_nature_indicators do |t|
    #   t.references :product_nature, :null => false
    #   # t.references :process
    #   t.string     :nature,   :null => false
    #   # t.string     :nature, :null => false  # decimal, measure, string, boolean ou choice
    #   # t.string     :usage                   # notion métiers avec enumerize
    #   # t.string :unit
    #   # t.integer    :minimal_length
    #   # t.integer    :maximal_length
    #   # t.decimal    :minimal_value,   :precision => 19, :scale => 4
    #   # t.decimal    :maximal_value,   :precision => 19, :scale => 4
    #   # t.boolean    :active, :null => false, :default => false
    #   # t.text       :comment
    #   t.stamps
    # end
    # add_stamps_indexes :product_nature_indicators
    # add_index :product_nature_indicators, :product_nature_id
    # add_index :product_nature_indicators, :nature

    # create_table :product_indicator_choices do |t|
    #   t.references :indicator, :null => false
    #   t.string     :name, :null => false
    #   t.string     :value # valeur de l'indicateur si besoin (coefficient)
    #   t.integer    :position
    #   t.text       :comment
    #   t.stamps
    # end
    # add_stamps_indexes :product_indicator_choices
    # add_index :product_indicator_choices, :indicator_id

    create_table :product_indicator_data do |t|
      t.references :product,            :null => false
      t.string     :indicator,          :null => false
      t.string     :indicator_datatype, :null => false
      t.datetime   :measured_at,        :null => false

      t.geometry   :geometry_value
      t.decimal    :decimal_value,   :precision => 19, :scale => 4
      t.decimal    :measure_value_value,   :precision => 19, :scale => 4
      t.string     :measure_value_unit      # Needed for historic
      t.text       :string_value
      t.boolean    :boolean_value, :null => false, :default => false
      t.string     :choice_value
      t.stamps
    end
    add_stamps_indexes :product_indicator_data
    add_index :product_indicator_data, :product_id
    add_index :product_indicator_data, :indicator
    add_index :product_indicator_data, :measured_at

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
