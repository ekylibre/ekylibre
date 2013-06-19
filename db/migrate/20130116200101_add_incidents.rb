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

    # add_column :procedures, :incident_id, :integer
    # add_index :procedures, :incident_id
  end

end
