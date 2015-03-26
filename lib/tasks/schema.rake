namespace :clean do

  desc "Update models list file in db/models.yml and db/tables.yml"
  task :schema => :environment do
    print " - Schema: "

    dir = Rails.root.join("db")
    # Clean::Support.set_search_path!
    Dir.glob(Rails.root.join("app", "models", "*.rb")).each { |file| require file }
    models = if ActiveRecord::Base.respond_to? :descendants
           ActiveRecord::Base.send(:descendants)
         elsif ActiveRecord::Base.respond_to? :subclasses
           ActiveRecord::Base.send(:subclasses)
         else
           Object.subclasses_of(ActiveRecord::Base)
         end.select{|x| not x.name.match('::') and not x.abstract_class?}.sort{|a,b| a.name <=> b.name}

    symodels = models.collect{|x| x.name.underscore.to_sym}

    errors = 0
    # schema_file = Rails.root.join("lib", "ekylibre", "schema", "reference.rb")

    schema_hash = {}
    schema_yaml = "---\n"
    Ekylibre::Record::Base.connection.tables.sort.delete_if do |table|
      %w(schema_migrations sessions).include?(table.to_s)
    end.each do |table|
      schema_hash[table] = {}
      schema_yaml << "\n#{table}:\n"
      columns = Ekylibre::Record::Base.connection.columns(table).sort{|a,b| a.name <=> b.name }
      max = columns.map(&:name).map(&:size).max + 1
      model = table.classify.constantize rescue nil
      for column in columns
        next if column.name =~ /\A\_/
        column_hash = {type: column.type.to_s}
        schema_yaml << "  #{column.name}: {type: #{column.type}"

        if column.type == :decimal
          if column.precision
            schema_yaml << ", precision: #{column.precision}"
            column_hash[:precision] = column.precision
          end
          if column.scale
            schema_yaml << ", scale: #{column.scale}"
            column_hash[:scale] = column.scale
          end
        end
        if column.name =~ /\_id\z/
          reference_name = column.name.to_s[0..-4].to_sym
          # unless val = Ekylibre::Schema.references(table, column)
            if column.name == "parent_id"
              val = model.name.underscore.to_sym
            elsif [:creator_id, :updater_id].include? column.name
              val = :user
            elsif columns.map(&:name).include?(reference_name.to_s + "_type")
              val = "~#{reference_name}_type"
            elsif symodels.include? reference_name
              val = reference_name
            elsif model and reflection = model.reflect_on_association(reference_name)
              val = reflection.class_name.underscore.to_sym
            end
          # end
          errors += 1 if val.nil?
          schema_yaml << ", references: #{val.to_s}"
          column_hash[:references] = val.to_s
        end
        if column.limit
          schema_yaml << ", limit: #{column.limit.inspect}"
          column_hash[:limit] = column.limit
        end
        if column.null.is_a? FalseClass
          schema_yaml << ", required: true"
          column_hash[:required] = true
        end
        unless column.default.nil?
          if column.type == :string
            schema_yaml << ", default: #{column.default.inspect}"
            column_hash[:default] = column.default
          else
            schema_yaml << ", default: #{column.default.to_s}"
          end
          if column.type == :boolean
            column_hash[:default] = !(column.default == 'false')
          end
        end
        schema_yaml << "}\n"
        schema_hash[table][column.name] = column_hash.stringify_keys
      end.join(",\n") # .dig
    end.join(",\n") # .dig

    File.open(dir.join("tables.yml"), "wb") do |f|
      # f.write(schema_yaml)
      f.write(schema_hash.to_yaml)
    end

    File.open(dir.join("models.yml"), "wb") do |f|
      f.write(models.collect{|m| m.name.underscore}.to_yaml)
    end

    puts "#{errors.to_s.rjust(3)} errors"
  end

end
