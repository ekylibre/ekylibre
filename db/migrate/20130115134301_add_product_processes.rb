class AddProductProcesses< ActiveRecord::Migration

  def change

    create_table :product_indicators do |t|
       t.belongs_to :product, :null => false
       t.belongs_to :nature, :null => false
       t.datetime   :measured_at, :null => false
       t.string     :comment
       t.decimal    :decimal_value,   :precision => 19, :scale => 4
       t.decimal    :measure_value,   :precision => 19, :scale => 4
       t.belongs_to :measure_unit # Nécessaire pour l'historique, permet de recouper les donner en cas de crash
       t.text       :string_value
       t.boolean    :boolean_value, :null => false, :default => false
       t.integer    :choice_value_id
       t.stamps
    end
    add_stamps_indexes :product_indicators
    add_index :product_indicators, :product_id
    add_index :product_indicators, :nature_id
    add_index :product_indicators, :measure_unit_id
    add_index :product_indicators, :choice_value_id


     create_table :product_indicator_natures do |t|
       t.belongs_to :process, :null => false
       t.belongs_to :unit
       t.string     :name, :null => false
       t.string     :nature  # decimal, measure, string, boolean ou choice
       t.string     :usage  # notion métiers avec enumerize
       t.integer    :minimal_length
       t.integer    :maximal_length
       t.decimal    :minimal_value,   :precision => 19, :scale => 4
       t.decimal    :maximal_value,   :precision => 19, :scale => 4
       t.boolean    :active, :null => false, :default => false
       t.string     :comment
       t.stamps
    end
    add_stamps_indexes :product_indicator_natures
    add_index :product_indicator_natures, :process_id
    add_index :product_indicator_natures, :unit_id

    create_table :product_indicator_nature_choices do |t|
       t.belongs_to :nature, :null => false
       t.string     :name, :null => false
       t.string     :value # valeur de l'indicateur si besoin (coefficient)
       t.integer    :position
       t.string     :comment
       t.stamps
    end
    add_stamps_indexes :product_indicator_nature_choices
    add_index :product_indicator_nature_choices, :nature_id

    create_table :product_process_phases do |t|
       t.belongs_to :process
       t.string     :name
       t.integer    :position
       t.string     :phase_delay
       t.string     :nature # notion métiers avec enumerize
       t.string     :comment
       t.stamps
    end
    add_stamps_indexes :product_process_phases
    add_index :product_process_phases, :process_id

    create_table :product_processes do |t|
       t.belongs_to :variety, :null => false
       t.string     :name, :null => false
       t.string     :nature # notion métiers avec enumerize
       t.string     :comment
       t.boolean    :repeatable, :null => false, :default => false
       t.stamps
    end
    add_stamps_indexes :product_processes
    add_index :product_processes, :variety_id

  end

end