class AddIncidents < ActiveRecord::Migration

  def change

    create_table :incidents do |t|
       t.references :target, :polymorphic => true, :null => false # product / product_group / entity / sale / purchase / incoming_delivery / outgoing_delivery
       t.string :nature , :null => false# incident_nature XML nomenclatures
       t.datetime   :observed_at, :null => false
       t.integer    :priority # range (1..10)
       t.integer    :gravity  # range (1..10)
       t.string     :state   # enumerize (resolved / waiting / in progress / new)
       t.string     :name, :null => false
       t.text     :description
       t.stamps
    end
    add_stamps_indexes :incidents
    add_index :incidents, [:target_id, :target_type]
    add_index :incidents, :nature
    add_index :incidents, :name

    create_table :prescriptions do |t|
       t.references :document
       t.references :prescriptor
       t.string     :reference_number
       t.date       :delivered_on
       t.text       :description
       t.stamps
    end
    add_stamps_indexes :prescriptions
    add_index :prescriptions, :reference_number
    add_index :prescriptions, :document_id
    add_index :prescriptions, :prescriptor_id

    # add_column :procedures, :incident_id, :integer
    # add_index :procedures, :incident_id
  end

end
