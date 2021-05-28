class AddUserAndLockStampToCropGroupModels < ActiveRecord::Migration[4.2]
  AFFECTED_TABLES = %i[crop_groups crop_group_items crop_group_labellings].freeze

  def up
    AFFECTED_TABLES.each do |t|
      add_column t, :lock_version, :integer, null: false, default: 0
      add_reference t, :creator, index: true
      add_reference t, :updater, index: true
    end
  end

  def down
    AFFECTED_TABLES.each do |t|
      remove_column t, :lock_version
      remove_column t, :creator_id
      remove_column t, :updater_id
    end
  end
end