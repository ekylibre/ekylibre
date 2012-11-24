class CreateRelationsSupport < ActiveRecord::Migration
  def self.up
    # EntityNature
    create_table :entity_natures do |t|
      t.column :name,                   :string,  :null=>false
      t.column :abbreviation,           :string,  :null=>false # abbrev for postal address
      t.column :active,                 :boolean, :null=>false, :default=>true
      t.column :physical,               :boolean, :null=>false, :default=>false
      t.column :in_name,                :boolean, :null=>false, :default=>true
      t.column :title,                  :string # title
      t.column :description,            :text
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :entity_natures
    add_index :entity_natures, :company_id
    add_index :entity_natures, [:name, :company_id], :unique=>true

    # Entity
    create_table :entities do |t|
      t.column :nature_id,              :integer,  :null=>false, :references=>:entity_natures, :on_delete=>:restrict, :on_update=>:cascade
      t.column :language_id,            :integer,  :null=>false, :references=>:languages, :on_delete=>:restrict, :on_update=>:cascade
      t.column :name,                   :string,   :null=>false # name or last_name
      t.column :first_name,             :string
      t.column :full_name,              :string,   :null=>false
      t.column :code,                   :string,   :limit=>16    # HID Human ID
      t.column :active,                 :boolean,  :null=>false, :default=>true
      t.column :born_on,                :date
      t.column :dead_on,                :date
      t.column :ean13,                  :string,   :limit=>13
      t.column :soundex,                :string,   :limit=>4
      t.column :website,                :string
      t.column :client,                 :boolean,  :null=>false, :default=>false
      t.column :supplier,               :boolean,  :null=>false, :default=>false
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :entities
    add_index :entities, :company_id
    add_index :entities, [:code, :company_id], :unique=>true
    add_index :entities, [:name, :company_id]
    add_index :entities, [:full_name, :company_id]
    add_index :entities, [:soundex, :company_id]

    # AddressNorm
    create_table :address_norms do |t|
      t.column :name,                   :string,   :null=>false
      t.column :reference,              :string
      t.column :default,                :boolean,  :null=>false, :default=>false
      t.column :rtl,                    :boolean,  :null=>false, :default=>false
      t.column :align,                  :string,   :null=>false, :default=>"left", :limit=>8
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :address_norms
    add_index :address_norms, :company_id
    add_index :address_norms, [:name, :company_id], :unique=>true

    # AddressNormItem
    create_table :address_norm_items do |t|
      t.column :contact_norm_id,        :integer, :null=>false, :references=>:address_norms,  :on_delete=>:cascade, :on_update=>:cascade
      t.column :name,                   :string,  :null=>false
      t.column :nature,                 :string,  :null=>false, :default=>"content", :limit=>15
      t.column :maxlength,              :integer, :null=>false, :default=>38
      t.column :content,                :string
      t.column :left_nature,            :string,  :limit=>15
      t.column :left_value,             :string,  :limit=>63
      t.column :right_nature,           :string,  :default=>"space", :limit=>15
      t.column :right_value,            :string,  :limit=>63
      t.column :position,               :integer
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :address_norm_items
    add_index :address_norm_items, :company_id
    add_index :address_norm_items, [:nature, :contact_norm_id, :company_id], :unique=>true, :name=>"#{quoted_table_name(:address_norm)}_items_nature"
    add_index :address_norm_items, [:name, :contact_norm_id, :company_id],  :unique=>true, :name=>"#{quoted_table_name(:address_norm)}_items_name"

    # Contact
    create_table :contacts do |t|
    #  t.column :element_id,             :integer,  :null=>false, :references=>nil
    #  t.column :element_type,           :string
      t.column :name,                   :string
      t.column :entity_id,              :integer,  :null=>false, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
      t.column :norm_id,                :integer,  :null=>false, :references=>:address_norms
      t.column :default,                :boolean,  :null=>false, :default=>false
      t.column :closed_on,              :date
      t.column :line_2,                 :string,   :limit=>38
      t.column :line_3,                 :string,   :limit=>38
      t.column :line_4_number,          :string,   :limit=>38
      t.column :line_4_street,          :string,   :limit=>38
      t.column :line_5,                 :string,   :limit=>38
      t.column :line_6_code,            :string,   :limit=>38
      t.column :line_6_city,            :string,   :limit=>38
      t.column :address,                :string,   :limit=>280
      t.column :phone,                  :string,   :limit=>32
      t.column :fax,                    :string,   :limit=>32
      t.column :mobile,                 :string,   :limit=>32
      t.column :email,                  :string
      t.column :website,                :string
      t.column :deleted,                :boolean, :null=>false, :default=>false
      t.column :latitude,               :float
      t.column :longitude,              :float
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :contacts
    add_index :contacts, :company_id
    add_index :contacts, :entity_id
    # add_index :contacts, :element_id
    # add_index :contacts, :element_type
    # add_index :contacts, :active
    add_index :contacts, :default

    # Complement
    create_table :complements do |t|
      #t.column :class_name,             :string,    :null=>false
      t.column :name,                   :string,    :null=>false
      t.column :nature,                 :string,    :null=>false,   :limit=>8 # {decimal string boolean choice date datetime}
      t.column :position,               :integer
      t.column :active,                 :boolean,   :null=>false,   :default=>true
      t.column :required,               :boolean,   :null=>false,   :default=>false
      t.column :length_max,             :integer
      t.column :decimal_min,            :decimal,   :precision=>16, :scale=>4
      t.column :decimal_max,            :decimal,   :precision=>16, :scale=>4
      t.column :company_id,             :integer,   :null=>false,   :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :complements
    add_index :complements, [:company_id, :position]
    add_index :complements, :required
    add_index :complements, :company_id

    # ComplementChoice
    create_table :complement_choices do |t|
      t.column :complement_id,          :integer,   :null=>false,   :references=>:complements, :on_delete=>:cascade
      t.column :name,                   :string,    :null=>false
      t.column :value,                  :string,    :null=>false
      t.column :company_id,             :integer,   :null=>false,   :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :complement_choices
    add_index :complement_choices, :complement_id
    add_index :complement_choices, :company_id

    # ComplementDatum
    create_table :complement_data do |t|
      t.column :entity_id,              :integer,   :null=>false,   :references=>:entities,           :on_delete=>:cascade, :on_update=>:cascade
      t.column :complement_id,          :integer,   :null=>false,   :references=>:complements, :on_delete=>:cascade
      t.column :decimal_value,          :decimal
      t.column :string_value,           :text
      t.column :boolean_value,          :boolean
      t.column :date_value,             :date
      t.column :datetime_value,         :datetime
      t.column :choice_value_id,        :integer,   :references=>:complement_choices, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,   :null=>false,   :references=>:companies,          :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :complement_data
    add_index :complement_data, :entity_id
    add_index :complement_data, :choice_value_id
    add_index :complement_data, :complement_id
    add_index :complement_data, :company_id
    add_index :complement_data, [:entity_id, :complement_id], :unique=>true

  end


  def self.down
    drop_table :complement_data
    drop_table :complement_choices
    drop_table :complements
    drop_table :contacts
    drop_table :address_norm_items
    drop_table :address_norms
    drop_table :entities
    drop_table :entity_natures
  end
end
