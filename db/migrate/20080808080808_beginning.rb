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
      t.column :native_name,            :string
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
      t.column :salt,                   :string,   :null=>false, :limit=>64
      t.column :hashed_password,        :string,   :null=>false, :limit=>64
      t.column :locked,                 :boolean,  :null=>false, :default=>false
      t.column :deleted,                :boolean,  :null=>false, :default=>false
      t.column :email,                  :string
      t.column :company_id,             :integer,  :null=>false, :references=>nil
      t.column :language_id,            :integer,  :null=>false, :references=>nil
      t.column :role_id,                :integer,  :null=>false, :references=>nil
    end
    add_index :users, :name, :unique=>true
    add_index :users, :email
    add_index :users, :company_id

    # Company
    create_table :companies do |t|
      t.column :name,                   :string,   :null=>false
      t.column :code,                   :string,   :null=>false, :limit=>8
      t.column :siren,                  :string,   :null=>false, :default=>"000000000", :limit=>9
      t.column :locked,                 :boolean,  :null=>false, :default=>false
      t.column :deleted,                :boolean,  :null=>false, :default=>false
    end
    add_index :companies, :name, :unique=>true
    add_index :companies, :code, :unique=>true
    
    # Parameter
    create_table :parameters do |t|
      t.column :name,                   :string,   :null=>false
      t.column :nature,                 :string,   :null=>false, :limit=>1 # String Boolean Integer Decimal ForeignElement
      t.column :string_value,           :text
      t.column :boolean_value,          :boolean
      t.column :integer_value,          :integer
      t.column :decimal_value,          :decimal
      t.column :element_type,           :string
      t.column :element_id,             :integer,  :references=>nil
      t.column :user_id,                :integer,  :references=>:users, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :parameters, :company_id
    add_index :parameters, [:company_id, :name], :unique=>true

    # Role
    create_table :roles do |t|
      t.column :name,                   :string,   :null=>false
      t.column :default,                :boolean,  :null=>false
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :roles, :company_id
    add_index :roles, [:company_id, :name], :unique=>true

    # Action
    create_table :actions do |t|
      t.column :name,                   :string,   :null=>false
      t.column :desc,                   :text
      t.column :parent_id,              :integer,  :null=>false, :references=>:actions
    end
    add_index :actions, :name, :unique=>true

    # Action <---> Role
    create_table :actions_roles do |t|
      t.column :action_id,              :integer,  :null=>false, :references=>:actions
      t.column :role_id,                :integer,  :null=>false, :references=>:roles      
    end
    
    # Template
    create_table :templates do |t|
      t.column :name,                   :string,   :null=>false
      t.column :content,                :text,     :null=>false
      t.column :cache,                  :text    
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :templates, :company_id
    add_index :templates, [:company_id, :name], :unique=>true

  end

  def self.down
    drop_table :templates
    drop_table :actions_roles
    drop_table :actions
    drop_table :roles
    drop_table :parameters
    drop_table :companies
    drop_table :users
    drop_table :languages
    drop_table :sessions
  end
end
