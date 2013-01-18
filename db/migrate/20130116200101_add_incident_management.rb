class AddIncidentManagement< ActiveRecord::Migration

  def change

    create_table :incidents do |t|
       t.belongs_to :target, :polymorphic => true, :null => false# product / product_group / entity / sale / purchase / incoming_delivery / outgoing_delivery
       t.belongs_to :nature, :null => false # incident_nature
       t.belongs_to :watcher, :null => false # entity
       t.datetime   :observed_at, :null => false
       t.integer    :priority # range (1..10)
       t.integer    :gravity # range (1..10)
       t.string     :status # enumerize (resolved / waiting / in progress / new)
       t.string     :name
       t.string     :description
       t.stamps
    end
    add_stamps_indexes :incidents
    add_index :incidents, [:target_id, :target_type]
    add_index :incidents, :nature_id
    add_index :incidents, :watcher_id

    create_table :incident_natures do |t|
       t.string     :name, :null => false
       t.string     :nature # enumerize
       t.text       :description
       t.stamps
    end
    add_stamps_indexes :incident_natures



  end

end