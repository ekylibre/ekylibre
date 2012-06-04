class ChangeAllStampColumns < ActiveRecord::Migration
  MODEL_DIR = Rails.root.join("app", "models")
  Dir.chdir(MODEL_DIR) do 
    @@models = Dir["**/*.rb"]
  end
  @@models = @@models.collect{|m| m.sub(/\.rb$/,'')}.sort
  def self.up
    for table in tables.delete_if{|t| [:schema_migrations, :sessions].include? t.to_sym}
      columns = columns(table).collect{|c| c.name.to_sym}
      add_column table, :creator_id, :integer unless columns.include? :creator_id
      add_column table, :updater_id, :integer unless columns.include? :updater_id
      execute "UPDATE #{table} SET creator_id=created_by" if columns.include?(:creator_id) and columns.include?(:created_by)
      execute "UPDATE #{table} SET updater_id=updated_by" if columns.include?(:updater_id) and columns.include?(:updated_by)
      remove_column table, :created_by if columns.include? :created_by
      remove_column table, :updated_by if columns.include? :updated_by
    end
    add_column :languages, :created_at, :timestamp
    add_column :languages, :updated_at, :timestamp
  end

  def self.down
    remove_column :languages, :updated_at
    remove_column :languages, :created_at

    for table in tables.delete_if{|t| [:schema_migrations, :sessions].include? t.to_sym}
      columns = columns(table).collect{|c| c.name.to_s}
      add_column table, :created_by, :integer unless columns.include? "created_by"
      add_column table, :updated_by, :integer unless columns.include? "updated_by"
      execute("UPDATE #{table} SET created_by=creator_id") if columns.include?("creator_id") and columns.include?("created_by")
      execute("UPDATE #{table} SET updated_by=updater_id") if columns.include?("updater_id") and columns.include?("updated_by")
      remove_column table, :creator_id if columns.include?("creator_id")
      remove_column table, :updater_id if columns.include?("updater_id")
    end
    remove_column :languages, :updated_by
    remove_column :languages, :created_by
  end

end
