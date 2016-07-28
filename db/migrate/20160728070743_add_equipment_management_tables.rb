class AddEquipmentManagementTables < ActiveRecord::Migration
  def change
    # Add nature for intervention
    reversible do |dir|
      dir.up do
        execute "update interventions set state='aborted' where state='squeezed'"
        execute <<-SQL
        DELETE FROM intervention_parameter_readings
          WHERE id IN (
            SELECT intervention_parameter_readings.id
              FROM intervention_parameter_readings
                INNER JOIN intervention_parameters
                  ON intervention_parameters.id = intervention_parameter_readings.parameter_id
                INNER JOIN interventions
                  ON interventions.id = intervention_parameters.intervention_id
              WHERE interventions.state = 'aborted'
          )
        SQL

        execute <<-SQL
        DELETE FROM intervention_parameters
          WHERE id IN (
            SELECT intervention_parameters.id
              FROM intervention_parameters
                INNER JOIN interventions
                  ON interventions.id = intervention_parameters.intervention_id
              WHERE interventions.state='aborted'
          )
        SQL

        execute <<-SQL
        DELETE
          FROM interventions
          WHERE interventions.state='aborted'
        SQL

        execute <<-SQL
        UPDATE interventions
          SET state='request'
          WHERE state='undone'
        SQL

        execute <<-SQL
        UPDATE interventions
          SET state='record'
          WHERE state='in_progress'
        SQL

        execute <<-SQL
        UPDATE interventions
          SET state='record'
          WHERE state='done'
        SQL

      end

      dir.down do
        execute <<-SQL
        UPDATE interventions
          SET state='squeezed'
          WHERE state='aborted'
        SQL

        execute <<-SQL
        UPDATE interventions
          SET state='done'
          WHERE state='record'
        SQL

        execute <<-SQL
        UPDATE interventions
          SET state='undone'
          WHERE state='request'
        SQL

      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE interventions
          SET procedure_name = 'equipment_maintenance'
          WHERE procedure_name = 'equipment_item_replacement'
        SQL

        execute <<-SQL
        UPDATE intervention_parameters
          SET reference_name = 'part'
          WHERE reference_name = 'piece'
        SQL


        execute <<-SQL
        UPDATE interventions
          SET procedure_name = 'equipment_maintenance'
          WHERE procedure_name = 'oil_replacement'
        SQL

        execute <<-SQL
        UPDATE intervention_parameters
          SET reference_name = 'part'
          WHERE reference_name = 'oil'
        SQL

      end
      dir.down do
        execute <<-SQL
        UPDATE interventions
          SET procedure_name = 'equipment_item_replacement'
          WHERE procedure_name = 'equipment_maintenance'
        SQL

        execute <<-SQL
        UPDATE intervention_parameters
          SET reference_name = 'piece'
          WHERE reference_name = 'part'
        SQL


        execute <<-SQL
        UPDATE interventions
          SET procedure_name = 'oil_replacement'
          WHERE procedure_name = 'equipment_maintenance'
        SQL

        execute <<-SQL
        UPDATE intervention_parameters
          SET reference_name = 'oil'
          WHERE reference_name = 'part'
        SQL

      end
    end

    rename_column :interventions, :state, :nature
    add_reference :interventions, :request_intervention, index: true
    add_column :interventions, :state, :string

    add_column :interventions, :maintenance_nature, :string
    add_column :interventions, :trouble_encountered, :boolean, null: false, default: false
    add_column :interventions, :trouble_description, :string

    # Create product nature variant component
    create_table :product_nature_variant_components do |t|
      t.references :product_nature_variant, null: false
      t.references :part_product_nature_variant
      t.references :parent, index: true
      t.datetime :deleted_at
      t.string :name, null: false
      t.index :product_nature_variant_id, name: :index_product_nature_variant_components_on_variant
      t.index :part_product_nature_variant_id, name: :index_product_nature_variant_components_on_part_variant
      t.index :deleted_at, name: :index_product_nature_variant_components_ondeleted_at_on_
      t.stamps
    end

    # Create product part replacements
    create_table :product_part_replacements do |t|
      t.references :component, null: false, index: true
      t.references :following, index: true
      t.references :intervention_parameter, null: false, index: true
      t.references :product, null: false, index: true
      t.stamps
    end
  end
end
