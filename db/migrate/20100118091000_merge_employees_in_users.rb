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
    execute "UPDATE #{table} SET #{column}=#{casewhen}"
  end
  
  def self.sqlint(val)
    if val.nil?
      return " IS NULL"
    else
      return "="+val.to_s
    end
  end

  def self.up
    add_column :users, :deleted_at, :timestamp
    execute "UPDATE users SET deleted_at = updated_at WHERE deleted = #{quoted_true}"
    remove_column :users, :deleted

    add_column :productions, :name, :string
    execute "UPDATE productions SET name=COALESCE(tracking_serial, 'Production')"

    #rename table product_stocks to stocks
    rename_table :product_stocks,          :stocks 
    rename_table :shape_operations,        :operations
    rename_table :shape_operation_natures, :operation_natures
    rename_table :shape_operation_lines,   :operation_lines
    rename_table :stock_trackings,         :trackings

    add_column :stocks,             :name,        :string
    add_column :operations,         :target_type, :string
    add_column :operations,         :target_id,   :integer 
    execute "UPDATE operations SET target_type='Shape', target_id=shape_id"
    remove_column :operations,      :shape_id
    rename_column :operation_lines, :shape_operation_id, :operation_id
    rename_column :tool_uses,       :shape_operation_id, :operation_id
    add_column :operation_natures, :target_type,  :string
    execute "UPDATE operation_natures SET target_type='Shape'"
    
    add_column :stock_moves, :stock_id, :integer
    for stock in select_all("SELECT id, location_id AS lid, product_id AS pid, tracking_id AS tid, company_id AS cid FROM stocks")
      execute "UPDATE stock_moves SET stock_id=#{stock['id']} WHERE location_id#{sqlint(stock['lid'])} AND product_id#{sqlint(stock['pid'])} AND tracking_id#{sqlint(stock['pid'])} AND company_id#{sqlint(stock['cid'])}"
    end
    change_column :stock_moves, :quantity, :decimal
    execute "UPDATE stock_moves SET quantity = CASE WHEN input THEN quantity ELSE -quantity END"
    remove_column :stock_moves, :input
      


    for k, v in COLUMNS.stringify_keys.sort
      add_column :users, k, v
    end
    add_column :users, :employed,   :boolean, :null=>false, :default=>false
    add_column :users, :employment, :string

    puts "#{User.all.size} users"
    execute "INSERT INTO users (company_id, created_at, updated_at, first_name, last_name, language_id, name, role_id, office, admin) "+
      "SELECT company_id, created_at, updated_at, first_name, last_name, 0, LOWER(first_name||'.'||last_name), 0, id, #{quoted_false} FROM employees WHERE user_id IS NULL"
    puts "#{User.all.size} users"
    for user in User.find(:all, :conditions=>{:language_id=>0})
      user.password = ([0]*(rand*10+3).to_i).collect{|x| rand.to_s[2..-1].to_i.to_s(36)}.join
      user.password_confirmation = user.password
      user.language = user.company.entity.language
      user.role = user.company.roles.find(:first, :order=>"LENGTH(rights)")
      user.name = user.name.lower_ascii.gsub(/\W/, "")
      user.save!
      execute "UPDATE employees SET user_id = #{user.id} WHERE id = #{user.office}"
      # puts user.inspect
    end

    employees = {}
    for employee in select_all("SELECT * FROM employees")
      hash = {}
      COLUMNS.each{|k,v| hash[k] = employee[k.to_s]}
      hash[:employed] = true
      hash[:employment] = employee['role']
      # puts hash.inspect
      User.update_all(hash, {:id=>employee['user_id']})
      employees[employee['id'].to_s] = employee['user_id']
    end

    if employees.keys.size > 0
      change_ids(:entities,         :employee_id,    employees)
      change_ids(:events,           :employee_id,    employees)
      change_ids(:inventories,      :employee_id,    employees)
      change_ids(:sale_orders,      :responsible_id, employees)
      change_ids(:operations,       :employee_id,    employees)
      change_ids(:transports,       :responsible_id, employees)
    end

    drop_table :employees

    rename_column :entities,    :employee_id, :responsible_id
    rename_column :events,      :employee_id, :user_id    
    rename_column :inventories, :employee_id, :responsible_id
    rename_column :operations,  :employee_id, :responsible_id
    
    # raise Exception.new("Stop")
  end

  def self.down
    rename_column :operations,  :responsible_id, :employee_id
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
    
    add_index(:employees, :company_id, :name => "index_employees_on_company_id") rescue nil
    add_index(:employees, :updater_id, :name => "index_employees_on_updater_id") rescue nil
    add_index(:employees, :creator_id, :name => "index_employees_on_creator_id") rescue nil
    add_index(:employees, :updated_at, :name => "index_employees_on_updated_at") rescue nil
    add_index(:employees, :created_at, :name => "index_employees_on_created_at") rescue nil

    # Add employees
    execute "INSERT INTO employees (department_id, establishment_id, user_id, title, last_name, first_name, arrived_on, departed_on, role, office, comment, company_id, created_at, updated_at, profession_id, commercial) "+
      "SELECT COALESCE(department_id,0), COALESCE(establishment_id,0), id, SUBSTR(COALESCE(employment, '-'), 1, 32), COALESCE(last_name, '-'), COALESCE(first_name, '-'), arrived_on, departed_on, employment, office, comment, company_id, COALESCE(created_at, CURRENT_TIMESTAMP), COALESCE(updated_at, CURRENT_TIMESTAMP), profession_id, commercial FROM users WHERE employed = #{quoted_true}"

    puts select_one("SELECT count(*) AS 'x' from employees").inspect

    # Get conversion ids
    employees = {}
    for em in select_all "SELECT user_id, id FROM employees"
      employees[em['user_id']] = em['id'].to_i
    end

    # Update ids of foreign key
    if employees.keys.size > 0
      change_ids(:entities,         :employee_id,    employees)
      change_ids(:events,           :employee_id,    employees)
      change_ids(:inventories,      :employee_id,    employees)
      change_ids(:sale_orders,      :responsible_id, employees)
      change_ids(:operations,       :employee_id,    employees)
      change_ids(:transports,       :responsible_id, employees)
    end
    
    remove_column :users, :employment
    remove_column :users, :employed
    for k, v in COLUMNS.stringify_keys.sort.reverse
      remove_column :users, k
    end


    add_column :stock_moves, :input, :boolean, :null=>false, :default=>false
    execute "UPDATE stock_moves SET input=(quantity>=0), quantity = ABS(quantity)"
    remove_column :stock_moves, :stock_id
    
    remove_column :operation_natures, :target_type
    rename_column :tool_uses,       :operation_id, :shape_operation_id
    rename_column :operation_lines, :operation_id, :shape_operation_id
    add_column    :operations, :shape_id
    execute "UPDATE operations SET shape_id=target_id WHERE target_type='Shape'"
    execute "DELETE FROM operations WHERE shape_id IS NULL"
    remove_column :operations, :target_id
    remove_column :operations, :target_type
    remove_column :stocks,     :name
    
    rename_table :trackings,         :stock_trackings
    rename_table :operation_lines,   :shape_operation_lines
    rename_table :operation_natures, :shape_operation_natures
    rename_table :operations,        :shape_operations
    rename_table :stocks,            :product_stocks 

    remove_column :productions, :name

    add_column :users, :deleted, :boolean , :null=>false, :default=>false
    execute "UPDATE users SET deleted = #{quoted_true} WHERE deleted_at IS NOT NULL"
    remove_column :users, :deleted_at
  end
end
