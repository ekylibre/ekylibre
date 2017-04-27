class AddEquipmentManagementTables < ActiveRecord::Migration
  def change
    # Add nature for intervention
    add_column :interventions, :nature, :string
    reversible do |dir|
      dir.up do
        execute "UPDATE interventions SET nature = 'record'"
      end
      dir.down do
        execute <<-SQL
        DELETE FROM intervention_parameters
          WHERE intervention_id IN (
            SELECT id
              FROM interventions
              WHERE nature != 'record'
          )
        SQL
        execute "DELETE FROM interventions WHERE nature != 'record'"
      end
    end
    change_column_null :interventions, :nature, false
    add_index :interventions, :nature

    add_reference :interventions, :request_intervention, index: true

    add_column :interventions, :trouble_encountered, :boolean, null: false,
                                                               default: false
    add_column :interventions, :trouble_description, :text

    # Create product nature variant components
    create_table :product_nature_variant_components do |t|
      t.references :product_nature_variant, null: false
      t.references :part_product_nature_variant
      t.references :parent, index: true
      t.datetime :deleted_at
      t.string :name, null: false
      t.index %i[name product_nature_variant_id], unique: true,
                                                  name: :index_product_nature_variant_name_unique
      t.index :product_nature_variant_id,
              name: :index_product_nature_variant_components_on_variant
      t.index :part_product_nature_variant_id,
              name: :index_product_nature_variant_components_on_part_variant
      t.index :deleted_at,
              name: :index_product_nature_variant_components_on_deleted_at
      t.stamps
    end

    add_reference :intervention_parameters, :component, index: true
    add_reference :intervention_parameters, :assembly, index: true
  end
end
