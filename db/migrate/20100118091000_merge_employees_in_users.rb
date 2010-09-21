class MergeEmployeesInUsers < ActiveRecord::Migration
  COLUMNS = {
    :department_id=>:integer, 
    :establishment_id=>:integer, 
    :arrived_on=>:date, 
    :departed_on=>:date,
    :office=>:string, 
    :comment=>:text, 
    :profession_id=>:integer, 
    :commercial=>:boolean
  }
  def self.change_ids(table, column, conv)
    # Build of CASE WHEN which register all employee_id=>user_id conversion
    casewhen =  "CASE "+conv.collect{|k, v| "WHEN #{column}=#{k} THEN #{v}"}.join(" ")+ " END"
    execute "UPDATE #{quote_table_name(table)} SET #{column}=#{casewhen}"
  end
  
  def self.up
    add_column :users, :deleted_at, :timestamp
    execute "UPDATE #{quote_table_name(:users)} SET deleted_at = updated_at WHERE deleted = #{quoted_true}"
    remove_column :users, :deleted

    for k, v in COLUMNS.stringify_keys.sort
      add_column :users, k, v
    end
    add_column :users, :employed,   :boolean, :null=>false, :default=>false
    add_column :users, :employment, :string

    # puts "#{User.all.size} users"
    execute "INSERT INTO #{quote_table_name(:users)} (company_id, created_at, updated_at, first_name, last_name, language_id, name, role_id, office, admin) "+
      "SELECT company_id, created_at, updated_at, first_name, last_name, 0, LOWER("+connection.concatenate("first_name", "'.'", "last_name")+"), 0, id, #{quoted_false} FROM #{quote_table_name(:employees)} WHERE user_id IS NULL"
    # puts "#{User.all.size} users"
    for user in connection.select_all("SELECT * FROM #{quote_table_name(:users)} WHERE language_id=0")
#      user.password = ([0]*(rand*10+3).to_i).collect{|x| rand.to_s[2..-1].to_i.to_s(36)}.join
#      user.password_confirmation = user.password
#      user.language = user.company.entity.language
#      user.role = user.company.roles.find(:first, :order=>length("rights"))
#      user.name = user.name.lower_ascii.gsub(/\W/, "")
#      user.save!
      execute "UPDATE #{quote_table_name(:employees)} SET user_id = #{user['id']} WHERE id = #{user['office']}"
      # puts user.inspect
    end

    employees = {}
    for employee in connection.select_all("SELECT * FROM #{quote_table_name(:employees)}")
      updates = []
      hash = {}
      COLUMNS.each do |k,v| 
        updates << k.to_s+"="+if v == :boolean
                                ['1', 't', 'T', 'true'].include?(employee[k.to_s]) ? quoted_true : quoted_false
                              elsif v == :integer
                                (employee[k.to_s]||0).to_s
                              elsif v == :date
                                quote(employee[k.to_s]||Date.civil(1970,1,1))
                              else 
                                quote(employee[k.to_s])
                              end
        # hash[k] = employee[k.to_s]}
      end
      updates << "employed=#{quoted_true}"
      updates << "employment="+quote(employee['role'].to_s)
      #hash[:employed] = true
      #hash[:employment] = employee['role']
      # puts hash.inspect
      execute "UPDATE #{quote_table_name(:users)} SET #{updates.join(', ')} WHERE id=#{employee['user_id']}"
      employees[employee['id'].to_s] = employee['user_id']
    end

    if employees.keys.size > 0
      change_ids(:entities,         :employee_id,    employees)
      change_ids(:events,           :employee_id,    employees)
      change_ids(:inventories,      :employee_id,    employees)
      change_ids(:sale_orders,      :responsible_id, employees)
      change_ids(:shape_operations,       :employee_id,    employees)
      change_ids(:transports,       :responsible_id, employees)
    end

    remove_index(:employees, :name => "index_#{quote_table_name(:employees)}_on_company_id")
#     remove_index(:employees, :name => "index_employees_on_updater_id")
#     remove_index(:employees, :name => "index_employees_on_creator_id")
#     remove_index(:employees, :name => "index_employees_on_updated_at")
#     remove_index(:employees, :name => "index_employees_on_created_at")

    drop_table :employees

    rename_column :entities,    :employee_id, :responsible_id
    rename_column :events,      :employee_id, :user_id    
    rename_column :inventories, :employee_id, :responsible_id
    rename_column :shape_operations,  :employee_id, :responsible_id
    
    # raise Exception.new("Stop")
  end

  def self.down
    rename_column :shape_operations,  :responsible_id, :employee_id
    rename_column :inventories, :responsible_id, :employee_id
    rename_column :events,      :user_id, :employee_id
    rename_column :entities,    :responsible_id, :employee_id
    
    create_table :employees do |t|
      t.integer  "department_id",                                     :null => false
      t.integer  "establishment_id",                                  :null => false
      t.integer  "user_id"
      t.string   "title",            :limit => 32,                    :null => false
      t.string   "last_name",                                         :null => false
      t.string   "first_name",                                        :null => false
      t.date     "arrived_on"
      t.date     "departed_on"
      t.string   "role"
      t.string   "office",           :limit => 32
      t.text     "comment"
      t.integer  "company_id",                                        :null => false
      t.datetime "created_at",                                        :null => false
      t.datetime "updated_at",                                        :null => false
      t.integer  "creator_id"
      t.integer  "updater_id"
      t.integer  "lock_version",                   :default => 0,     :null => false
      t.integer  "profession_id"
      t.boolean  "commercial",                     :default => false, :null => false
    end

    add_index(:employees, :company_id, :name => "index_#{quote_table_name(:employees)}_on_company_id")
    #add_index(:employees, :updater_id, :name => "index_employees_on_updater_id")
    #add_index(:employees, :creator_id, :name => "index_employees_on_creator_id")
    #add_index(:employees, :updated_at, :name => "index_employees_on_updated_at")
    #add_index(:employees, :created_at, :name => "index_employees_on_created_at")

    # Add employees
    execute "INSERT INTO #{quote_table_name(:employees)} (department_id, establishment_id, user_id, title, last_name, first_name, arrived_on, departed_on, role, office, comment, company_id, created_at, updated_at, profession_id, commercial) SELECT COALESCE(department_id, 0), COALESCE(establishment_id, 0), id, "+connection.substr("COALESCE(employment, '-')", 1, 32)+", COALESCE(last_name, '-'), COALESCE(first_name, '-'), arrived_on, departed_on, COALESCE(employment, '-'), COALESCE(office, '-'), comment, company_id, COALESCE(created_at, CURRENT_TIMESTAMP), COALESCE(updated_at, CURRENT_TIMESTAMP), profession_id, commercial FROM #{quote_table_name(:users)} WHERE employed = #{quoted_true}"

    # puts select_one("SELECT count(*) AS x from #{quote_table_name(:employees)}").inspect

    # Get conversion ids
    employees = {}
    for em in connection.select_all "SELECT user_id, id FROM #{quote_table_name(:employees)}"
      employees[em['user_id']] = em['id'].to_i
    end

    # Update ids of foreign key
    if employees.keys.size > 0
      change_ids(:entities,         :employee_id,    employees)
      change_ids(:events,           :employee_id,    employees)
      change_ids(:inventories,      :employee_id,    employees)
      change_ids(:sale_orders,      :responsible_id, employees)
      change_ids(:shape_operations,       :employee_id,    employees)
      change_ids(:transports,       :responsible_id, employees)
    end
    
    remove_column :users, :employment
    remove_column :users, :employed
    for k, v in COLUMNS.stringify_keys.sort.reverse
      remove_column :users, k
    end

    add_column :users, :deleted, :boolean , :null=>false, :default=>false
    execute "UPDATE #{quote_table_name(:users)} SET deleted = #{quoted_true} WHERE deleted_at IS NOT NULL"
    remove_column :users, :deleted_at
  end
end
