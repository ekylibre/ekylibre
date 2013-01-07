class RenameCustomFieldReference < ActiveRecord::Migration
  def up
    rename_column :custom_fields, :customized_type, :used_with
  end

  def down
    rename_column :custom_fields, :used_with, :customized_type
  end
end
