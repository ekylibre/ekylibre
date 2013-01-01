class ChangeTreatments< ActiveRecord::Migration
  def change

      add_column :animal_events, :parent_id, :integer
      add_column :animal_events, :planned_at, :datetime
      add_column :animal_events, :moved_at, :datetime
      rename_column :animal_events, :started_on, :started_at
      rename_column :animal_events, :stopped_on, :stopped_at

      rename_column :animal_treatments, :started_on, :started_at
      rename_column :animal_treatments, :stopped_on, :stopped_at
      add_column :animal_treatments, :prescription_id, :integer
      add_column :animal_treatments, :quantity_unit_id, :integer
      add_column :animal_treatments, :per_animal_unit, :string
      add_column :animal_treatments, :frequency, :integer, :default => 1,  :null => false
      add_column :animal_treatments, :per_frequency_time_unit, :string
      add_column :animal_treatments, :per_duration_time_unit, :string
      add_column :animal_treatments, :duration_unit_wait_for_milk, :string
      add_column :animal_treatments, :duration_unit_wait_for_meat, :string

      add_column :drugs, :prescripted, :boolean, :default => true, :null => true

     create_table :posologies do |t|
       t.belongs_to :animal_race_nature
       t.belongs_to :drug
       t.belongs_to :disease
       t.string     :description
       t.decimal    :quantity,                     :precision => 19, :scale => 4, :default => 0.0,  :null => false
       t.belongs_to :quantity_unit
       t.integer  :frequency,                                                 :default => 1,   :null => false
       t.string   :per_frequency_time_unit
       t.string   :per_duration_time_unit
       t.integer :duration_wait_for_meat
       t.integer :duration_wait_for_milk
       t.string :duration_unit_wait_for_meat
       t.string :duration_unit_wait_for_milk
       t.string :drug_admission_path
       t.stamps
    end
    add_stamps_indexes :posologies
    add_index :posologies, :animal_race_nature_id
    add_index :posologies, :drug_id
    add_index :posologies, :disease_id



    create_table :animal_treatment_uses do |t|
       t.belongs_to :event
       t.belongs_to :treatment
       t.string     :name
       t.decimal    :quantity,                     :precision => 19, :scale => 4, :default => 0.0,  :null => false
       t.belongs_to :quantity_unit
       t.belongs_to :drug_allowed
       t.string     :per_animal_unit
       t.string     :drug_admission_path
       t.stamps
    end
    add_stamps_indexes :animal_treatment_uses
    add_index :animal_treatment_uses, :event_id
    add_index :animal_treatment_uses, :treatment_id

    create_table :prescriptions do |t|
       t.belongs_to :prescriptor
       t.string     :name
       t.string     :prescription_number
       t.date       :prescripted_on
       t.attachment :picture
       t.stamps
    end
    add_stamps_indexes :prescriptions
    add_index :prescriptions, :prescriptor_id


  end
end