class NormalizeVariousMistakes < ActiveRecord::Migration
  def change
    # Removes unique index
    revert { add_index :documents, %i[nature key], unique: true }

    # Re-adds index with unique constraint
    add_index :documents, %i[nature key]

    # Renames ressource => resource
    rename_column :interventions, :ressource_id,   :resource_id
    rename_column :interventions, :ressource_type, :resource_type

    # Removes sales_conditons on team
    revert { add_column :teams, :sales_conditions, :text }

    # Rename vat_taxe_registry to vat_registry
    reporting_tables = %i[document_templates documents attachments]
    reversible do |dir|
      dir.up do
        reporting_tables.each do |table|
          execute "UPDATE #{table} SET nature = 'vat_registry' WHERE nature = 'vat_taxe_registry'"
        end
      end
      dir.down do
        reporting_tables.each do |table|
          execute "UPDATE #{table} SET nature = 'vat_taxe_registry' WHERE nature = 'vat_registry'"
        end
      end
    end

    # Invert bad role for group_inclusion special procedures
    reversible do |dir|
      dir.up do
        reporting_tables.each do |_table|
          execute "UPDATE intervention_casts SET roles='group_inclusion-includer' WHERE roles='group_inclusion-target' AND reference_name = 'member'"
          execute "UPDATE intervention_casts SET roles='group_inclusion-target' WHERE roles='group_inclusion-includer' AND reference_name = 'group'"
        end
      end
      dir.down do
        reporting_tables.each do |_table|
          execute "UPDATE intervention_casts SET roles='group_inclusion-target' WHERE roles='group_inclusion-includer' AND reference_name = 'member'"
          execute "UPDATE intervention_casts SET roles='group_inclusion-includer' WHERE roles='group_inclusion-target' AND reference_name = 'group'"
        end
      end
    end

    # Moves LegalEntities/People images to their new home
    removed = []
    %i[legal_entities people].each do |type|
      old_dir = Ekylibre::Tenant.private_directory.join('attachments', type.to_s)
      new_dir = Ekylibre::Tenant.private_directory.join('attachments', 'entities')
      removed << old_dir
      reversible do |dir|
        dir.up do
          Dir.glob(old_dir.join('**', '*.*')).each do |f|
            new_file = new_dir.join(Pathname.new(f).relative_path_from(old_dir))
            FileUtils.mkdir_p new_file.dirname
            FileUtils.cp f, new_file.to_s
          end
        end
        dir.down do
          # TODO: Replace it with valid code based on DB content
          raise ActiveRecord::IrreversibleMigration
        end
      end
    end

    # Always execute at the end of migration
    reversible do |dir|
      dir.up do
        removed.each do |dir|
          FileUtils.rm_rf(dir)
        end
      end
    end
  end
end
