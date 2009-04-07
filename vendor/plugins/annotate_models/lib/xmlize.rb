require "config/environment"

MODEL_DIR   = File.join(RAILS_ROOT, "app/models")
DB_SCHEMA_FILE = File.join(RAILS_ROOT, "db/schema.xml")

module Xmlize

  # We're passed a name of things that might be 
  # ActiveRecord models. If we can find the class, and
  # if its a subclass of ActiveRecord::Base,
  # then pas it to the associated block

  def self.build_schema
    old_schema = nil
    old_schema = REXML::Document.new(File.new(DB_SCHEMA_FILE)) if File.exists? DB_SCHEMA_FILE

    # Models
    models = ARGV.dup
    models.shift

    if models.empty? or old_schema.nil?
      schema = REXML::Document.new
      schema.add_element('analysis')
      schema << REXML::XMLDecl.new
    else
      schema = old_schema
    end
    
    if models.empty?
      Dir.chdir(MODEL_DIR) do 
        models = Dir["**/*.rb"]
      end
      models = models.sort
    end
    
    root = schema.root
    models.each do |m|
      model_name = m.sub(/\.rb$/,'')
      model = model_name.camelize.constantize
      puts 'Building '+model.to_s+'...'
      table = root.elements["table[@name='#{model.to_s}']"]
      table = root.add_element('table', 'name'=>model.to_s, 'label'=>I18n.translate("activerecord.models.#{model_name}")) if table.nil?
      for column in model.columns
        col = table.elements["column[@name='#{column.name}']"]
        col = table.add_element('column', 'name'=>column.name, 'type'=>column.sql_type)
        if column.null
          col.delete_attribute('notnull')
        else
          col.add_attribute('notnull', 'true')
        end
      end
    end

    # Writing
    schema.write(File.open(DB_SCHEMA_FILE, 'w'),2)    
  end
end
