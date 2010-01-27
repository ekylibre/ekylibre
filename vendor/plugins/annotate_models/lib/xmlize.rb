require "config/environment"

MODEL_DIR   = File.join(RAILS_ROOT, "app/models")
DB_SCHEMA_FILE = File.join(RAILS_ROOT, "db/schema.xml")

module Xmlize

  
  # Simple quoting for the default column value
  def self.quote(value)
    case value
      when NilClass                 then "NULL"
      when TrueClass                then "TRUE"
      when FalseClass               then "FALSE"
      when Float, Fixnum, Bignum, BigDecimal    then value.to_s
      # BigDecimals need to be output in a non-normalized form and quoted.
#      when BigDecimal               then value.to_s('F')
      else
        value.inspect
    end
  end

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
    version = (ActiveRecord::Migrator.current_version rescue 0).to_s
    root.add_attribute('version', version)
    models.each do |m|
      model_name = m.sub(/\.rb$/,'')
      begin
        model = model_name.camelize.constantize
        columns = model.columns
        puts 'Building '+model.to_s+'...'
        table = root.elements["table[@name='#{model.to_s}']"]
        table = root.add_element('table', 'name'=>model.to_s) if table.nil?
        label = I18n.translate("activerecord.models.#{model_name}")
        table.add_attribute('label', label) unless label.match /^translation\ missing/
        for column in columns
          col = table.elements["column[@name='#{column.name}']"]
          col = table.add_element('column', 'name'=>column.name, 'type'=>column.sql_type.upcase) if col.nil?
          label = I18n.translate("activerecord.attributes.#{model_name}.#{column.name}")
          col.add_attribute('label', label) unless label.match /^translation\ missing/
          ['notnull', 'fkey', 'default'].each do |a|
            col.delete_attribute(a)
          end
          col.add_attribute('notnull', 'true') unless column.null
          col.add_attribute('default', self.quote(column.default)) if column.default
          for ref in model.reflections
            if ref[1].options[:foreign_key] == column.name and ref[1].macro==:belongs_to
              col.add_attribute('fkey', ref[1].options[:class_name]+'(id)')
            end
          end
          
        end
      rescue Exception => e
        puts "Unable to build #{model_name.camelize}: #{e.message}"
      end
    end

    # Writing
    schema.write(File.open(DB_SCHEMA_FILE, 'w'),2)    
  end
end
