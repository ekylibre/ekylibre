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
    
    execute "INSERT INTO #{quoted_table_name(:delivery_modes)} (company_id, name, code, comment, created_at, updated_at) SELECT companies.id , 'Remise en main propre', 'exw', '',current_timestamp, current_timestamp FROM #{quoted_table_name(:companies)} AS companies"

    execute "INSERT INTO #{quoted_table_name(:delivery_modes)} (company_id, name, code, comment, created_at, updated_at) SELECT companies.id , 'Livraison avec assurance', 'cip', '',current_timestamp, current_timestamp FROM #{quoted_table_name(:companies)} AS companies"

    execute "INSERT INTO #{quoted_table_name(:delivery_modes)} (company_id, name, code, comment, created_at, updated_at) SELECT companies.id , 'Livraison sans assurance', 'cpt', '', current_timestamp, current_timestamp FROM #{quoted_table_name(:companies)} AS companies"
 
    modes = connection.select_all("SELECT * FROM #{quoted_table_name(:delivery_modes)}")
    execute "UPDATE #{quoted_table_name(:deliveries)} SET mode_id = CASE "+modes.collect{|m| "WHEN nature='#{m['code']}' AND company_id=#{m['company_id']} THEN #{m['id']}"}.join(" ")+" ELSE 0 END" if modes.size > 0
    
    remove_column :deliveries,  :nature
    
  end

  def self.down
    add_column :deliveries, :nature, :string, :limit=>3 


    modes = connection.select_all("SELECT * FROM #{quoted_table_name(:delivery_modes)}").collect{|m| "WHEN mode_id=#{m['id']} THEN '#{m['code'].gsub(/\W/, '')}'"}.join
    execute "UPDATE #{quoted_table_name(:deliveries)} SET nature = CASE #{modes} END" unless modes.blank?

    remove_column :deliveries, :mode_id
    drop_table :delivery_modes
    remove_column :products, :manage_stocks
    add_column :products, :without_stocks, :boolean, :null=>false, :default=>false
    add_column :contacts, :name, :string
  end
end
