class CreateObservations < ActiveRecord::Migration
  def self.up
    create_table :observations do |t|
      t.column :importance,      :string,   :null=>false, :limit=>10
      t.column :description,     :text,     :null=>false
      t.column :entity_id,       :integer,  :null=>false, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,      :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_stamps :observations
  end

  def self.down
    drop_table :observations
  end
end
