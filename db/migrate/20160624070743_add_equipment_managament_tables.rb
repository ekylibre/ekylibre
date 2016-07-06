class AddEquipmentManagamentTables < ActiveRecord::Migration
  def change
    #Add nature for intervention
    reversible do |dir|
      dir.up do
        execute "update interventions set state='aborted' where state='squeezed'"
        execute <<-SQL
                DELETE FROM intervention_parameter_readings
                           WHERE id IN (SELECT intervention_parameter_readings.id FROM
                                                                intervention_parameter_readings INNER JOIN intervention_parameters
                                                                   	ON intervention_parameters.id = intervention_parameter_readings.parameter_id
                                                                        INNER JOIN interventions
                                                                           ON interventions.id = intervention_parameters.intervention_id
                                        WHERE interventions.state = 'aborted'
                                                        )
                SQL

        execute <<-SQL
        DELETE FROM intervention_parameters
           where id IN (select intervention_parameters.id from intervention_parameters INNER JOIN interventions
                                        ON interventions.id = intervention_parameters.intervention_id
                        WHERE interventions.state='aborted'
                        )
                  SQL

        execute "DELETE FROM interventions WHERE interventions.state='aborted'"
        execute "update interventions set state='request' where state='undone'"
        execute "update interventions set state='record' where state='in_progress'"
        execute "update interventions set state='record' where state='done'"
      end

      dir.down do
        execute  "update interventions set state='squeezed' where state='aborted'"
        execute  "update interventions set state='done' where state='record'"
        execute  "update interventions set state='undone' where state='request'"
      end
    end
    reversible do |dir|
      dir.up do
        execute "update interventions set procedure_name='equipment_maintenance' where procedure_name='equipment_item_replacement'"
        execute "update intervention_parameters set reference_name='part' where reference_name='piece'"

        execute "update interventions set procedure_name='equipment_maintenance' where procedure_name='oil_replacement'"
        execute "update intervention_parameters set reference_name='part' where reference_name='oil'"

      end
      dir.down do
        execute "update interventions set procedure_name='equipment_item_replacement' where procedure_name='equipment_maintenance'"
        execute "update intervention_parameters set reference_name='piece' where reference_name='part'"

        execute "update interventions set procedure_name='oil_replacement' where procedure_name='equipment_maintenance'"
        execute "update intervention_parameters set reference_name='oil' where reference_name='part'"
      end
    end


    rename_column :interventions, :state, :nature
    add_reference :interventions, :request_intervention, index: true

    add_column :interventions, :maintenance_nature, :string
    add_column :interventions, :trouble_encountered, :boolean, null: false, default: false
    add_column :interventions, :trouble_description, :string


    #create product nature variant component
    create_table :product_nature_variant_components do |t|
      t.references :product_nature_variant, null: false
      t.references :part_product_nature_variant, null: false
      t.string :name, null: false

      t.index      :product_nature_variant_id, name: :index_product_nature_variant_components_on_variant
      t.index      :part_product_nature_variant_id, name: :index_product_nature_variant_components_on_part_variant
      t.stamps
    end
    #create product part replacements
    create_table :product_part_replacements do |t|
      t.references :component, null: false, index: true
      t.references :following, index: true
      t.references :intervention_parameter, null: false, index: true
      t.references :product, null: false, index: true
      t.stamps
    end
  end
end
