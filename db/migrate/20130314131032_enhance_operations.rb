class EnhanceOperations < ActiveRecord::Migration
  def normalize_indexes(table)
    for index in indexes(table)
      expected_name = ("index_#{table}_on_" + index.columns.join("_and_")).to_sym
      if index.name.to_sym != expected_name
        rename_index table, index.name.to_sym, expected_name
      end
    end
  end


  def up
    # # WorkingSet
    # create_table :working_sets do |t|
    #   t.string :name, :null => false
    #   t.string :nomen
    #   t.stamps
    # end
    # add_stamps_indexes :working_sets
    # add_index :working_sets, :nomen

    # # ProcedureNature
    # create_table :procedure_natures do |t|
    #   t.string :name, :null => false
    #   t.string :nomen
    #   t.references :parent
    #   t.integer :lft
    #   t.integer :rgt
    #   t.integer :depth
    #   t.stamps
    # end
    # add_stamps_indexes :procedure_natures
    # add_index :procedure_natures, :nomen
    # add_index :procedure_natures, :parent_id

    # raise "Stop"

    # Production
    create_table :productions do |t|
      # t.references :nature, :null => false
      t.references :activity, :null => false
      t.references :campaign, :null => false
      t.references :product_nature, :null => false
      t.boolean :static_support, :null => false, :default => false
      t.datetime :started_at
      t.datetime :stopped_at
      t.integer :position
      t.string :state

      t.stamps
    end
    add_stamps_indexes :productions
    add_index :productions, :activity_id
    add_index :productions, :campaign_id
    add_index :productions, :product_nature_id

    # Production Supports can store product_nature
    create_table :production_supports do |t|
      t.references :production, :null => false
      t.references :storage,    :null => false
      t.datetime :started_at
      t.datetime :stopped_at
      t.boolean :exclusive, :null => false, :default => false
      t.stamps
    end
    add_stamps_indexes :production_supports
    add_index :production_supports, :production_id
    add_index :production_supports, :storage_id

    # Procedure
    # add_column :events, :parent_id, :integer
    # add_index  :events, :parent_id
    # add_column :events, :nomen, :string
    create_table :procedures do |t|
      # t.references :nature, :null => false
      t.references :provisional_procedure
      t.boolean :provisional, :null => false, :default => false
      t.references :incident
      t.references :production, :null => false
      t.string :nomen,   :null => false
      t.string :natures, :null => false
      # t.string :version
      t.string :state,   :null => false, :default => "undone"
      # t.string :uid, :limit => 511
      # t.references :parent
      # t.integer :lft
      # t.integer :rgt
      # t.integer :depth
      t.stamps
    end
    add_stamps_indexes :procedures
    # add_index :procedures, :parent_id
    add_index :procedures, :production_id
    add_index :procedures, :provisional_procedure_id
    add_index :procedures, :incident_id
    add_index :procedures, :nomen

    create_table :procedure_variables do |t|
      # t.references :nature, :null => false
      t.references :procedure, :null => false
      t.references :target, :null => false
      t.string  :indicator, :null => false
      t.string  :measure_unit, :null => false
      t.decimal :measure_quantity, :precision => 19, :scale => 4, :null => false
      t.string  :role, :null => false
      t.stamps
    end
    add_stamps_indexes :procedure_variables
    add_index :procedure_variables, :procedure_id
    add_index :procedure_variables, :target_id


    # Operation
    add_column :events, :procedure_id, :integer
    add_index :events, :procedure_id
    # TODO: Migrate operations
    drop_table :operations
    # add_column :operations, :procedure_id, :integer
    # add_index :operations, :procedure_id
    # normalize_indexes :operations
    # remove_column :operations, :hour_duration
    # remove_column :operations, :min_duration
    # remove_column :operations, :duration
    # remove_column :operations, :name
    # remove_column :operations, :description
    # remove_column :operations, :consumption
    # remove_column :operations, :planned_on
    # remove_column :operations, :moved_on
    # remove_column :operations, :tools_list
    # remove_column :operations, :target_type
    # remove_column :operations, :target_id
    # remove_column :operations, :responsible_id

    # OperationNature
    drop_table :operation_natures
    # remove_column :operation_natures, :target_type
    # add_column :operation_natures, :nomen, :string
    # add_column :operation_natures, :working_set_id, :integer
    # add_index :operation_natures, :nomen
    # add_index :operation_natures, :working_set_id
    # normalize_indexes :operation_natures

    # OperationTask
    create_table :operation_tasks do |t|
      t.references :operation, :null => false
      t.references :parent
      t.boolean    :prorated, :null => false, :default => false
      t.references :subject, :null => false
      t.string     :verb, :null => false
      t.references :operand
      t.string     :operand_unit
      t.decimal    :operand_quantity, :precision => 19, :scale => 4
      t.references :indicator_datum
      t.text       :expression
      t.stamps
    end
    add_stamps_indexes :operation_tasks
    add_index :operation_tasks, :operation_id
    add_index :operation_tasks, :parent_id
    add_index :operation_tasks, :subject_id
    add_index :operation_tasks, :operand_id
    add_index :operation_tasks, :operand_unit
    add_index :operation_tasks, :indicator_datum_id

    drop_table :operation_uses
    drop_table :operation_lines

    # ProductLocalization
   for table in [:product_localizations, :product_memberships, :product_links]
      add_column table, :operation_task_id, :integer
      add_index table, :operation_task_id
   end

    # # Product <-> WorkingSet
    # create_table :products_working_sets, :id => false do |t|
    #   t.references :product
    #   t.references :working_set
    # end
    # add_index :products_working_sets, :product_id
    # add_index :products_working_sets, :working_set_id

    # # ProductAbility
    # create_table :product_nature_abilities do |t|
    #   t.references :product_nature, :null => false
    #   t.string :nature, :null => false
    #   # t.string :nomen
    #   t.stamps
    # end
    # add_stamps_indexes :product_nature_abilities
    # add_index :product_nature_abilities, :product_nature_id
    # add_index :product_nature_abilities, :nature
  end

  def down
    # drop_table :product_abilities
    drop_table :products_working_sets
    drop_table :operation_tasks
    drop_table :procedures
    drop_table :procedure_natures
    drop_table :working_sets
  end
end
