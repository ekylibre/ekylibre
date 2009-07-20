class Sep1b3 < ActiveRecord::Migration
  MODEL_DIR = File.join(RAILS_ROOT, "app/models")
  Dir.chdir(MODEL_DIR) do 
    @@models = Dir["**/*.rb"]
  end
  @@models = @@models.collect{|m| m.sub(/\.rb$/,'')}.sort
  def self.up
    for model_name in @@models
      table = model_name.pluralize.to_sym
      model = model_name.camelcase.constantize
      if model.table_exists?
        add_column table, :creator_id, :integer
        add_column table, :updater_id, :integer
        if model.columns_hash.keys.include? "created_by"
          model.update_all('creator_id=created_by, updater_id=updated_by')
          remove_column table, :created_by
          remove_column table, :updated_by 
        end
      end
    end
    add_column :languages, :created_at, :timestamp
    add_column :languages, :updated_at, :timestamp
  end

  def self.down
    remove_column :languages, :updated_at
    remove_column :languages, :created_at
    for model_name in @@models
      table = model_name.pluralize.to_sym
      model = model_name.camelcase.constantize
      if model.table_exists?
        add_column table, :created_by, :integer
        add_column table, :updated_by, :integer
        if model.columns_hash.keys.include? "creator_id"
          model.update_all('created_by=creator_id, updated_by=updater_id')
          remove_column table, :creator_id
          remove_column table, :updater_id
        end
      end
    end
    remove_column :languages, :updated_by
    remove_column :languages, :created_by
  end

end
