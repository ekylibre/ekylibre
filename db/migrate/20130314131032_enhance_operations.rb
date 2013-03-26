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
    # WorkingSet
    create_table :working_sets do |t|
      t.string :name, :null => false
      t.string :nomen
      t.stamps
    end
    add_stamps_indexes :working_sets
    add_index :working_sets, :nomen

    # ProcedureNature
    create_table :procedure_natures do |t|
      t.string :name, :null => false
      t.string :nomen
      t.references :parent
      t.integer :lft
      t.integer :rgt
      t.integer :depth
      t.stamps
    end
    add_stamps_indexes :procedure_natures
    add_index :procedure_natures, :nomen
    add_index :procedure_natures, :parent_id

    # OperationNature
    remove_column :operation_natures, :target_type
    add_column :operation_natures, :nomen, :string
    add_column :operation_natures, :working_set_id, :integer
    add_index :operation_natures, :nomen
    add_index :operation_natures, :working_set_id
    normalize_indexes :operation_natures

    # Procedure
    create_table :procedures do |t|
      t.references :nature, :null => false
      t.references :parent
      t.string :name, :null => false
      t.datetime :started_at
      t.datetime :stopped_at
      t.stamps
    end
    add_stamps_indexes :procedures
    add_index :procedures, :parent_id
    add_index :procedures, :nature_id

    # Operation
    add_column :operations, :procedure_id, :integer
    add_index :operations, :procedure_id
    normalize_indexes :operations
    remove_column :operations, :hour_duration
    remove_column :operations, :min_duration
    remove_column :operations, :duration
    remove_column :operations, :name
    remove_column :operations, :description
    remove_column :operations, :consumption
    remove_column :operations, :planned_on
    remove_column :operations, :moved_on
    remove_column :operations, :tools_list
    remove_column :operations, :target_type
    remove_column :operations, :target_id
    remove_column :operations, :responsible_id

    # OperationTask
    create_table :operation_tasks do |t|
      t.references :operation, :null => false
      t.references :parent
      t.boolean    :detailled, :null => false, :default => false
      t.references :subject, :null => false
      t.string :verb, :string, :null => false
      t.references :operand
      t.references :operand_unit
      t.decimal    :operand_quantity, :precision => 19, :scale => 4
      t.references :indicator
      t.stamps
    end
    add_stamps_indexes :operation_tasks
    add_index :operation_tasks, :operation_id
    add_index :operation_tasks, :parent_id
    add_index :operation_tasks, :subject_id
    add_index :operation_tasks, :operand_id
    add_index :operation_tasks, :operand_unit_id
    add_index :operation_tasks, :indicator_id

    drop_table :operation_uses
    drop_table :operation_lines

    # ProductLocalization
    for table in [:product_localizations, :product_memberships, :product_links]
      add_column table, :operation_task_id, :integer
      add_index table, :operation_task_id
    end

    # Product <-> WorkingSet
    create_table :products_working_sets, :id => false do |t|
      t.references :product
      t.references :working_set
    end
    add_index :products_working_sets, :product_id
    add_index :products_working_sets, :working_set_id

    # ProductCapabilities
    create_table :product_abilities do |t|
      t.references :product, :null => false
      t.string :name, :null => false
      t.string :nomen
      t.stamps
    end
    add_stamps_indexes :product_abilities
    add_index :product_abilities, :nomen
    
    # Campaigns
    create_table :campaigns do |t|
      t.string :name, :null => false
      t.string :description
      t.string :nomen #code ou nomenclature si XML
      t.boolean :closed, :null => false, :default => false # Flag pour dire si une campagne est clôturé ou non
      t.stamps
    end
    add_stamps_indexes :campaigns
    add_index :campaigns, :name
    
    # Activities
    create_table :activities do |t|
      t.string :name, :null => false
      t.string :description
      t.string :nomen #code ou nomenclature si XML
      t.string :family, :null => false #classification ( végétal, animal, mecanisation)
      t.string :analytical_center_type, :null => false # PRINCIPAL / AUXILIAIRE / NON AFFECTE
      t.boolean :net_margin, :null => false, :default => false # Flag pour le calcul de la marge nette
      t.boolean :closed, :null => false, :default => false # Flag pour dire si une activité est clôturé ou non
      t.references :work_unit #unité d'oeuvre
      t.references :area_unit #unité de surface
      t.references :favored_product_nature # Si Flag pour le calcul de la marge nette =1 alors on demande un product_nature de reference
      t.references :parent #activité parente
      t.stamps
    end
    add_stamps_indexes :activities
    add_index :activities, :name
    add_index :activities, :parent_id
    add_index :activities, :work_unit_id
    add_index :activities, :area_unit_id
    add_index :activities, :favored_product_nature_id
    
    
  end

  def down
  end
end
