class AddMissingStampColumns < ActiveRecord::Migration
  def change
    # add_reference :master_production_natures, :creator, index: true
    # add_column :master_production_natures, :created_at, :datetime
    # add_reference :master_production_natures, :updater, index: true
    # add_column :master_production_natures, :updated_at, :datetime
    # add_column :master_production_natures, :lock_version, :integer, null: false, default: 0
    add_reference :naming_formats, :creator, index: true
    add_reference :naming_formats, :updater, index: true
    add_column :naming_formats, :lock_version, :integer, null: false, default: 0
    add_reference :naming_format_fields, :creator, index: true
    add_column :naming_format_fields, :created_at, :datetime
    add_reference :naming_format_fields, :updater, index: true
    add_column :naming_format_fields, :updated_at, :datetime
    add_column :naming_format_fields, :lock_version, :integer, null: false, default: 0
    add_reference :project_budgets, :creator, index: true
    add_reference :project_budgets, :updater, index: true
    add_column :project_budgets, :lock_version, :integer, null: false, default: 0
  end
end
