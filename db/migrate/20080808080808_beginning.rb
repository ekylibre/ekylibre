class Beginning < ActiveRecord::Migration
  def self.up
    # Session
    create_table :sessions, :stamp=>false do |t|
      t.column :session_id,             :string, :references=>nil
      t.column :data,                   :text
      t.column :updated_at,             :datetime
    end
    add_index :sessions, :session_id
    add_index :sessions, :updated_at

    # Language
    create_table :languages, :stamp=>false do |t|
      t.column :name,                   :string, :null=>false
      t.column :native_name,            :string, :null=>false
      t.column :iso2,                   :string, :limit=>2, :null=>false
      t.column :iso3,                   :string, :limit=>3, :null=>false
    end
    add_index :languages, :name
    add_index :languages, :iso2
    add_index :languages, :iso3

    # User
    create_table :users do |t|
      t.column :name,                   :string,   :null=>false, :limit=>32
      t.column :first_name,             :string,   :null=>false
      t.column :last_name,              :string,   :null=>false
      t.column :salt,                   :string,   :limit=>64
      t.column :hashed_password,        :string,   :limit=>64
      t.column :locked,                 :boolean,  :null=>false, :default=>false
      t.column :deleted,                :boolean,  :null=>false, :default=>false
      t.column :email,                  :string
      t.column :company_id,             :integer,  :null=>false, :references=>nil
      t.column :language_id,            :integer,  :null=>false, :references=>nil
      t.column :role_id,                :integer,  :null=>false, :references=>nil
    end
    add_index :users, :name, :unique=>true
    add_index :users, :email
    add_index :users, :role_id
    add_index :users, :language_id
    add_index :users, :company_id

    # Company
    create_table :companies do |t|
      t.column :name,                   :string,   :null=>false
      t.column :code,                   :string,   :null=>false, :limit=>8
      t.column :siren,                  :string,   :limit=>9
      t.column :born_on,                :date
      t.column :locked,                 :boolean,  :null=>false, :default=>false
      t.column :deleted,                :boolean,  :null=>false, :default=>false
    end
    add_index :companies, :name, :unique=>true
    add_index :companies, :code, :unique=>true
    
    # Parameter
    create_table :parameters do |t|
      t.column :name,                   :string,   :null=>false
      t.column :nature,                 :string,   :null=>false, :default=>'u', :limit=>1 # String Boolean Integer Decimal ForeignElement
      t.column :string_value,           :text
      t.column :boolean_value,          :boolean
      t.column :integer_value,          :integer
      t.column :decimal_value,          :decimal
      t.column :element_type,           :string
      t.column :element_id,             :integer,  :references=>nil
      t.column :user_id,                :integer,  :references=>:users, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :parameters, :name
    add_index :parameters, :nature
    add_index :parameters, :company_id
    add_index :parameters, :user_id
    add_index :parameters, :element_id
    add_index :parameters, [:company_id, :user_id, :name], :unique=>true

    # Role
    create_table :roles do |t|
      t.column :name,                   :string,   :null=>false
      t.column :actions,                :text
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :roles, :name
    add_index :roles, :company_id
    add_index :roles, [:company_id, :name], :unique=>true

    # Template
    create_table :templates do |t|
      t.column :name,                   :string,   :null=>false
      t.column :content,                :text,     :null=>false
      t.column :cache,                  :text    
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :templates, :company_id
    add_index :templates, [:company_id, :name], :unique=>true
    
    # Document
    create_table :documents do |t|
      t.column :filename,               :string 
      t.column :original_name,          :string, :null=>false
      t.column :key,                    :integer 
      t.column :filesize,               :integer 
      t.column :crypt_key,              :binary
      t.column :crypt_mode,             :string, :null=>false
      t.column :sha256,                 :string, :null=>false
      t.column :printed_at,             :datetime
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :documents, :sha256
    add_index :documents, :company_id

#     # Location
#     create_table :locations do |t|
#       t.column :name,                   :string,   :null=>false
#     end
#     add_index :locations, :name, :unique=>true

#     # Widget
#     create_table :widgets do |t|
#       t.column :name,                   :string,   :null=>false
#       t.column :nature,                 :string,   :null=>false
#       t.column :options,                :text
#       t.column :position,               :integer
#       t.column :location_id,            :integer,  :null=>false, :references=>:locations
#       t.column :company_id,             :integer,  :null=>false, :references=>:companies
#     end
#     add_index :widgets, :name
#     add_index :widgets, :location_id
#     add_index :widgets, :nature
#     add_index :widgets, :position
#     add_index :widgets, :company_id
  

#     # Menu
#     create_table :menus do |t|
#       t.column :name,                   :string,    :null=>false, :limit=>32
#       t.column :label,                  :text
#       t.column :company_id,             :integer,   :null=>false, :references=>:companies
#     end
#     add_index :menus, [:company_id,:name], :unique=>true
#     add_index :menus, :company_id

#     # Menu_item
#     create_table :menu_items do |t|
#       t.column :name,                   :string,    :null=>false
#       t.column :menu_id,                :integer,   :null=>false, :references=>:menus, :on_delete=>:cascade
#       t.column :parent_id,              :integer,   :references=>:menu_items, :on_delete=>:cascade
#       t.column :position,               :integer
#       t.column :url,                    :string,    :null=>false 
#       t.column :dynamic,                :boolean,   :null=>false, :default=>false
#       t.column :company_id,             :integer,   :null=>false, :references=>:companies
#     end
#     add_index :menu_items, :name
#     add_index :menu_items, :menu_id
#     add_index :menu_items, :parent_id
#     add_index :menu_items, :url
#     add_index :menu_items, :company_id


    # Establishment
    create_table :establishments do |t|
      t.column :name,                   :string, :null=>false
      t.column :nic,                    :string, :null=>false, :limit=>5
      t.column :siret,                  :string, :null=>false
      t.column :comment,                :text
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end
    add_index :establishments, [:name,  :company_id], :unique=>true
    add_index :establishments, [:siret, :company_id], :unique=>true

    # Department
    create_table :departments do |t|
      t.column :name,                   :string,   :null=>false
      t.column :comment,                :text
      t.column :parent_id,              :integer,  :references=>:departments, :on_delete=>:restrict, :on_update=>:restrict
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end
    add_index :departments, [:name, :company_id], :unique=>true
    add_index :departments, :parent_id


    Language.create!(:name=>'French', :native_name=>'Français', :iso2=>'fr', :iso3=>'fra')

  end

  def self.down
    drop_table :departments
    drop_table :establishments
#    drop_table :menus
#    drop_table :menu_items
#    drop_table :widgets
#    drop_table :locations
    drop_table :documents
    drop_table :templates
    drop_table :roles
    drop_table :parameters
    drop_table :companies
    drop_table :users
    drop_table :languages
    drop_table :sessions
  end
end
