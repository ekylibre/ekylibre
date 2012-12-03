class AddTools < ActiveRecord::Migration
  def up
    change_table :tools do |t|
      t.remove :nature
      t.has_attached_file :picture
      t.text :comment
      t.string :state
      t.date :purchased_on
      t.date :ceded_on
      t.belongs_to :nature
      t.belongs_to :asset
    end
    
    create_table :tool_natures do |t|
      t.string :name
      t.string :name_aee
      t.string :code_aee
      t.text :comment
      t.stamps
    end
    add_stamps_indexes :tool_natures
  end
  
  def down
    drop_attached_file :tools, :picture
    remove_column :tools, :comment
    remove_column :tools, :state
    remove_column :tools, :purchased_on
    remove_column :tools, :ceded_on
    remove_column :tools, :nature_id
    remove_column :tools, :asset_id
    drop_table :tool_natures
  end
end
