class CreateDeliveryModes < ActiveRecord::Migration
  def self.up
    remove_column :contacts, :name
    remove_column :products, :without_stocks
    add_column :products,    :manage_stocks, :boolean, :null=>false, :default=>false
    
    create_table :delivery_modes do |t|
      t.column :name,           :string, :null=>false
      t.column :code,           :string, :null=>false,   :limit=>3  ## "exw" "cip" "cpt"
      t.column :comment,        :text
      t.column :company_id,     :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end
    
    add_column :deliveries,   :mode_id,  :integer,  :references=>:delivery_modes, :on_delete=>:restrict, :on_update=>:restrict
    
    execute "INSERT INTO delivery_modes(company_id, name, code, comment, created_at, updated_at) SELECT companies.id , 'Remise en main propre', 'exw', '',current_timestamp, current_timestamp FROM companies"

    execute "INSERT INTO delivery_modes(company_id, name, code, comment, created_at, updated_at) SELECT companies.id , 'Livraison avec assurance', 'cip', '',current_timestamp, current_timestamp FROM companies"

    execute "INSERT INTO delivery_modes(company_id, name, code, comment, created_at, updated_at) SELECT companies.id , 'Livraison sans assurance', 'cpt', '', current_timestamp, current_timestamp FROM companies"

    # execute "UPDATE deliveries SET mode_id = m.id FROM delivery_modes m WHERE m.code = deliveries.nature AND m.company_id = deliveries.company_id"
    
    Delivery.find(:all).each do |delivery|
      dm = DeliveryMode.find_by_company_id_and_code(delivery.company_id, delivery.nature)
      delivery.mode_id = dm.id
      delivery.save(false)
    end
    
    remove_column :deliveries,  :nature
    
  end

  def self.down
    add_column :deliveries, :nature, :string, :limit=>3 

    execute "UPDATE deliveries SET nature = m.code FROM delivery_modes m WHERE deliveries.company_id = m.company_id AND deliveries.mode_id = m.id"

    remove_column :deliveries, :mode_id
    drop_table :delivery_modes
    remove_column :products, :manage_stocks
    add_column :products, :without_stocks, :boolean, :null=>false, :default=>false
    add_column :contacts, :name, :string
  end
end
