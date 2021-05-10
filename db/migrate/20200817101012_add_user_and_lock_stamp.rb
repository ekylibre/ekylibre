class AddUserAndLockStamp < ActiveRecord::Migration
  AFFECTED_TABLES = %i[cvi_cadastral_plants cvi_cadastral_plant_cvi_land_parcels cvi_cultivable_zones cvi_land_parcels cvi_statements locations].freeze

  def self.up
    AFFECTED_TABLES.each do |t|
      add_column t, :lock_version, :integer, null: false, default: 0
      add_reference t, :creator, index: true
      add_reference t, :updater, index: true
    end
  end

  def self.down
    AFFECTED_TABLES.each do |t|
      remove_column t, :lock_version
      remove_column t, :creator_id
      remove_column t, :updater_id
    end
  end
end