class RefactorTreatmentAnimals< ActiveRecord::Migration
  def up

    change_table :animal_posologies do |t|
      t.integer :product_category_id
      t.rename :animal_race_nature_id, :animal_race_id
      t.remove :frequency, :duration_wait_for_meat, :duration_wait_for_milk, :duration_unit_wait_for_milk
      t.rename :quantity, :preventive_quantity
      t.decimal :currative_quantity, :decimal, :precision => 19, :scale => 4, :default => 0.0, :null => false
      t.rename :per_frequency_time_unit, :quantity_delay
      t.rename :per_duration_time_unit, :quantity_interval
      t.rename :duration_unit_wait_for_meat, :product_category_waiting_delay
      t.rename :drug_admission_path , :drug_admission_way
    end
    add_index :animal_posologies, :product_category_id
    add_index :animal_posologies, :animal_race_id

    change_table :animal_drugs do |t|
      t.remove :frequency, :unit_id, :quantity
    end

    change_table :animal_races do |t|
      t.remove :nature_id
      t.integer :parent_id
    end
    add_index :animal_races, :parent_id

    change_table :animals do |t|
      t.rename :working_number, :work_number
      t.rename :is_reproductor, :reproductor
      t.rename :is_external, :external
      t.rename :outgone_reasons, :departure_reasons
      t.rename :outgone_on, :departed_on
      t.rename :income_reasons, :arrival_reasons
      t.rename :income_on, :arrived_on
    end

    change_table :animal_events do |t|
      t.remove :animal_group_id
    end

    change_table :animal_groups do |t|
      t.remove :age_min, :age_max, :sex, :pregnant
      t.integer :parent_id
    end
    add_index :animal_groups, :parent_id

    create_table :animal_group_events do |t|
      t.belongs_to :animal_group
      t.belongs_to :watcher
      t.belongs_to :nature
      t.belongs_to :parent
      t.datetime :started_at
      t.datetime :stopped_at
      t.datetime :moved_at
      t.datetime :planned_at
      t.text     :comment
      t.stamps
    end
    add_stamps_indexes :animal_group_events
    add_index :animal_group_events, :animal_group_id
    add_index :animal_group_events, :watcher_id
    add_index :animal_group_events, :nature_id
    add_index :animal_group_events, :parent_id

    change_table :animal_treatments do |t|
      t.remove :duration_wait_for_milk, :duration_wait_for_meat, :duration, :quantity_unit_id, :frequency, :per_frequency_time_unit, :duration_unit_wait_for_milk, :duration_unit_wait_for_meat
      t.rename :per_animal_unit, :quantity_interval
      t.rename :per_duration_time_unit, :quantity_delay
      t.rename :drug_admission_path, :drug_admission_way
    end

    drop_table :animal_race_natures

  end

  def down

    change_table :animal_posologies do |t|
      t.integer :animal_race_nature_id
      t.remove :product_category_id
      t.rename :animal_race_id, :animal_race_nature_id
      t.rename :preventive_quantity, :quantity
      t.remove :currative_quantity
      t.rename :quantity_delay, :per_frequency_time_unit
      t.rename :quantity_interval, :per_duration_time_unit
      t.rename :product_category_waiting_delay, :duration_unit_wait_for_meat
      t.rename :drug_admission_way, :drug_admission_path
    end
    add_index :animal_posologies, :animal_race_nature_id

    change_table :animal_drugs do |t|
      t.decimal :quantity, :decimal, :precision => 19, :scale => 4, :default => 0.0, :null => false
      t.decimal :frequency, :decimal, :precision => 19, :scale => 4, :default => 0.0, :null => false
      t.integer :unit_id
    end
    add_index :animal_posologies, :unit_id


    change_table :animal_races do |t|
      t.remove :parent_id
      t.integer :nature_id
    end
    remove_index :animal_events, :parent_id
    add_index :animal_races, :nature_id

    change_table :animals do |t|
      t.rename :work_number, :working_number
      t.rename  :reproductor, :is_reproductor
      t.rename  :external, :is_external
      t.rename  :departure_reasons, :outgone_reasons
      t.rename  :departed_on, :outgone_on
      t.rename  :arrival_reasons, :income_reasons
      t.rename  :arrived_on, :income_on
    end

    change_table :animal_events do |t|
      t.integer :animal_group_id
    end
    add_index :animal_events, :animal_group_id

    change_table :animal_groups do |t|
      t.string :age_min
      t.string :age_max
      t.string :sex
      t.boolean :pregnant
      t.remove :parent_id
    end

    change_table :animal_treatments do |t|
      t.string :duration_wait_for_milk
      t.string :duration_wait_for_meat
      t.decimal :duration
      t.integer :quantity_unit_id
      t.integer :frequency
      t.string :per_frequency_time_unit
      t.string :duration_unit_wait_for_milk
      t.string :duration_unit_wait_for_meat
      t.rename :quantity_interval, :per_animal_unit
      t.rename :quantity_delay, :per_duration_time_unit
      t.rename :drug_admission_way, :drug_admission_path
    end

   drop_table :animal_group_events

  end

end