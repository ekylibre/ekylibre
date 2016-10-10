class UpdateGradingAttributes < ActiveRecord::Migration
  def change
    rename_table :activity_grading_checks, :activity_inspection_point_natures
    add_column :activity_inspection_point_natures, :name, :string
    add_column :activity_inspection_point_natures, :category, :string

    rename_table :product_grading_checks, :inspection_points
    rename_column :inspection_points, :activity_grading_check_id, :nature_id
    rename_column :inspection_points, :product_grading_id, :inspection_id

    rename_table :product_gradings, :inspections

    create_table :activity_inspection_calibration_scales do |t|
      t.references :activity, null: false, index: true
      t.string :size_indicator_name, null: false
      t.string :size_unit_name, null: false
      t.stamps
    end

    create_table :activity_inspection_calibration_natures do |t|
      t.references :scale, null: false, index: true
      t.boolean :marketable, null: false, default: false
      t.decimal :minimal_value, precision: 19, scale: 4, null: false
      t.decimal :maximal_value, precision: 19, scale: 4, null: false
      t.integer :old_id
      t.stamps
    end

    create_table :inspection_calibrations do |t|
      t.references :inspection, null: false, index: true
      t.references :nature, null: false, index: true
      t.integer :items_count
      t.decimal :net_mass_value, precision: 19, scale: 4
      t.decimal :minimal_size_value, precision: 19, scale: 4
      t.decimal :maximal_size_value, precision: 19, scale: 4
      t.stamps
    end

    add_column :inspections, :product_net_surface_area_value, :decimal, precision: 19, scale: 4
    add_column :inspections, :product_net_surface_area_unit, :string

    reversible do |d|
      d.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='inspections' WHERE #{quote_column_name(:usage)}='product_gradings'"
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='inspection' WHERE #{quote_column_name(:root_model)}='product_grading'"

        # Integrates quality criteria
        execute "UPDATE activity_inspection_point_natures SET name = qc.name, category = 'none' FROM grading_quality_criteria AS qc WHERE qc.id = quality_criterion_id"
        # Adds calibration scales
        execute 'INSERT INTO activity_inspection_calibration_scales (activity_id, size_indicator_name, size_unit_name, created_at, creator_id, updated_at, updater_id, lock_version) SELECT id, grading_calibre_indicator_name, grading_calibre_unit_name, created_at, creator_id, updated_at, updater_id, lock_version FROM activities WHERE use_grading_calibre'
        # Adds calibration natures
        execute "INSERT INTO activity_inspection_calibration_natures (old_id, scale_id, minimal_value, maximal_value, created_at, creator_id, updated_at, updater_id, lock_version) SELECT n.id, s.id, minimal_calibre_value, maximal_calibre_value, n.created_at, n.creator_id, n.updated_at, n.updater_id, n.lock_version FROM activity_inspection_point_natures AS n JOIN activity_inspection_calibration_scales AS s ON (s.activity_id = n.activity_id) WHERE n.nature = 'calibre'"

        # Migrate old product_grading
        execute 'INSERT INTO inspection_calibrations (inspection_id, nature_id, items_count, net_mass_value, minimal_size_value, maximal_size_value, created_at, creator_id, updated_at, updater_id, lock_version) SELECT inspection_id, cn.id, i.items_count, i.net_mass_value, i.minimal_size_value, i.maximal_size_value, i.created_at, i.creator_id, i.updated_at, i.updater_id, i.lock_version FROM inspection_points AS i JOIN activity_inspection_calibration_natures AS cn ON (cn.old_id = i.nature_id)'

        # Removes removed calibration data
        execute "DELETE FROM inspection_points WHERE nature_id IN (SELECT id FROM activity_inspection_point_natures WHERE nature != 'quality')"
        execute "DELETE FROM activity_inspection_point_natures WHERE nature != 'quality'"
      end
      d.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='product_gradings' WHERE #{quote_column_name(:usage)}='inspections'"
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='product_grading' WHERE #{quote_column_name(:root_model)}='inspection'"
      end
    end

    change_column_null :activity_inspection_point_natures, :name, false
    change_column_null :activity_inspection_point_natures, :category, false

    revert do
      add_column :activity_inspection_calibration_natures, :old_id, :integer

      add_reference :activity_inspection_point_natures, :quality_criterion, index: true
      add_column :activity_inspection_point_natures, :minimal_calibre_value, precision: 19, scale: 4
      add_column :activity_inspection_point_natures, :maximal_calibre_value, precision: 19, scale: 4
      add_column :activity_inspection_point_natures, :nature, :string
      add_column :activity_inspection_point_natures, :position, :integer

      add_column :activities, :grading_calibre_indicator_name, :string
      add_column :activities, :grading_calibre_unit_name, :string
      add_column :activities, :use_grading_calibre, :boolean, null: false, default: false
    end

    revert do
      create_table :grading_quality_criteria do |t|
        t.string :name, null: false
        t.stamps
        t.index :name
      end
    end
  end
end
