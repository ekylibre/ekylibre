class UpdateDiseases< ActiveRecord::Migration
  def up

    drop_table :animal_cares
    drop_table :animal_care_natures
    drop_table :animal_cares_drugs
    drop_table :diseases_animal_cares

    create_table :animal_event_natures do |t|
       t.string     :name,                 :null => false
       t.text       :description
       t.text       :comment
       t.stamps
    end
    add_stamps_indexes :animal_event_natures

    create_table :animal_events do |t|
       t.belongs_to :animal
       t.belongs_to :animal_group
       t.belongs_to :watcher
       t.belongs_to :nature,               :null => false
       t.string     :name,                 :null => false
       t.text       :description
       t.text       :comment
       t.datetime   :started_on
       t.datetime   :stopped_on
       t.stamps
    end
    add_stamps_indexes :animal_events
    add_index :animal_events, :animal_id
    add_index :animal_events, :animal_group_id
    add_index :animal_events, :nature_id
    add_index :animal_events, :watcher_id

    create_table :diagnostics do |t|
      t.belongs_to :event
      t.belongs_to :disease
      t.string     :symptoms
      t.stamps
    end
    add_stamps_indexes :diagnostics
    add_index :diagnostics, :event_id
    add_index :diagnostics, :disease_id

    create_table :animal_treatments do |t|
      t.belongs_to :drug
      t.belongs_to :disease
      t.belongs_to :unit
      t.belongs_to :prescriptor
      t.string     :name
      t.string     :prescription_number
      t.datetime   :started_on
      t.datetime   :stopped_on
      t.integer    :duration_wait_for_milk
      t.integer    :duration_wait_for_meat
      t.decimal    :duration, :precision => 19, :scale => 4
      t.string     :per_unit
      t.decimal    :quantity,                     :precision => 19, :scale => 4, :default => 0.0,  :null => false
      t.stamps
    end
    add_stamps_indexes :animal_treatments
    add_index :animal_treatments, :drug_id
    add_index :animal_treatments, :disease_id
    add_index :animal_treatments, :unit_id

  end

  def down

    drop_table :animal_event_natures
    drop_table :animal_events
    drop_table :diagnostics
    drop_table :animal_treatments

  end

end