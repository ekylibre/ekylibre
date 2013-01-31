class AddDeviseToUsers < ActiveRecord::Migration
  def self.up
    # # Merge users in entities
    # change_table :entities do |t|
    #   t.boolean    :admin, :null => false, :default => false
    #   t.date       :recruited_on
    #   t.datetime   :connected_at
    #   t.date       :left_on
    #   t.references :department
    #   t.boolean    :employed, :null => false, :default => false
    #   t.string     :employment
    #   t.references :establishment
    #   t.string     :office
    #   t.references :profession
    #   t.decimal    :maximum_grantable_reduction_percent, :precision => 19, :scale => 4
    #   t.text       :rights
    #   t.references :role
    #   t.boolean    :loggable, :null => false, :default => false
    # end

    # commons = [:admin, :comment, :connected_at, :created_at, :creator_id, :department_id, :employed, :employment, :establishment_id, :first_name, :hashed_password, :language, :last_name, :lock_version, :locked, :name, :office, :profession_id, :rights, :role_id, :salt, :updated_at, :updater_id].join(', ')

    # max = select_value("SELECT MAX(id) FROM #{quoted_table_name(:entities)}")
    # users = {}
    # nature_id = select_value("SELECT id FROM #{quoted_table_name(:entity_natures)} ORDER BY physical DESC, id LIMIT 1")
    # if nature_id.blank?
    #   execute("INSERT INTO #{quoted_table_name(:entity_natures)} (title, name, active, created_at, updated_at) VALUES ('-', '-', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
    #   nature_id = select_value("SELECT id FROM #{quoted_table_name(:entity_natures)} ORDER BY physical DESC, id LIMIT 1")
    # end

    # for user in select_all("SELECT id, email FROM users")
    #   # Create entity for user
    #   execute("INSERT INTO #{quoted_table_name(:entities)} (loggable, nature_id, full_name, currency, recruited_on, left_on, maximum_grantable_reduction_percent, #{commons}) SELECT TRUE, #{nature_id}, last_name||COALESCE(' '||first_name, ''), 'EUR', arrived_on, departed_on, reduction_percent, #{commons} FROM #{quoted_table_name(:users)} WHERE id = #{user['id']}")
    #   users[user['id']] = select_value("SELECT max(id) FROM #{quoted_table_name(:entities)}").to_i
    #   # Add email
    #   unless user['email'].blank?
    #     execute("INSERT INTO #{quoted_table_name(:entity_addresses)} (entity_id, canal, coordinate) SELECT #{users[user['id']]}, 'email', '#{user['email']}'")
    #   end
    # end
    # # Reconnect foreign keys on entities
    # if users.size > 0
    #   for table, columns in USER_TABLES
    #     execute("UPDATE #{table} SET " + columns.collect{|c| "#{c} = CASE" + users.collect{|u,e| " WHEN #{c} = #{u} THEN #{e}"}.join + " ELSE NULL END"}.join(", "))
    #   end
    # end

    # rename_column :entities, :name, :username
    # remove_column :entities, :discount_rate # unused
    # remove_column :entities, :excise # unused
    # execute("INSERT INTO #{quoted_table_name(:entity_addresses)} (entity_id, canal, coordinate) SELECT id, 'website', website FROM entities WHERE LENGTH(TRIM(website)) > 0")
    # remove_column :entities, :website
    # drop_table :users



    change_table(:users) do |t|
      ## Database authenticatable
      # t.rename :user_name, :email
      # t.change :email, :string, :limit => 255
      # t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => false, :default => ""
      t.remove :hashed_password
      t.remove :salt
      t.rename :admin, :administrator

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.rename :connected_at, :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      t.integer  :failed_attempts, :default => 0 # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      ## Token authenticatable
      t.string :authentication_token

      # Uncomment below if timestamps were not included in your original model.
      # t.timestamps
    end

    remove_column :users, :name
    change_column_null :users, :email, false

    remove_index :users, :email
    add_index :users, :email,                :unique => true
    add_index :users, :reset_password_token, :unique => true
    add_index :users, :confirmation_token,   :unique => true
    add_index :users, :unlock_token,         :unique => true
    add_index :users, :authentication_token, :unique => true

    add_column :users, :entity_id, :integer
    add_column :entities, :old_user_id, :integer
    en_id = select_value("SELECT id FROM  #{quoted_table_name(:entity_natures)} ORDER BY gender DESC") || '0'
    ca = [:first_name, :last_name, :created_at, :updated_at, :creator_id, :updater_id, :lock_version]
    da = {:nature_id => en_id, :old_user_id => :id}
    execute("INSERT INTO #{quoted_table_name(:entities)} (" + ca.join(", ") + ", " + da.keys.join(", ") + ") SELECT " + ca.join(", ") + ", " + da.values.join(", ") + " FROM #{quoted_table_name(:users)}")
    execute("UPDATE #{quoted_table_name(:users)} SET entity_id = e.id FROM #{quoted_table_name(:entities)} AS e WHERE e.old_user_id = #{quoted_table_name(:users)}.id")
    # change_column_null :users, :entity_id, false
    add_index :users, :entity_id, :unique => true
    remove_column :entities, :old_user_id
  end

  def self.down
    # By default, we don't want to make any assumption about how to roll back a migration when your
    # model already existed. Please edit below which fields you would like to remove in this migration.
    raise ActiveRecord::IrreversibleMigration
  end
end
