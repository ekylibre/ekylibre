namespace :clean do

  desc "Update models list file in db/models.yml and db/tables.yml"
  task :schema => :environment do
    print " - Schema: "

    Clean::Support.set_search_path!

    models = Clean::Support.models_in_file

    symodels = models.collect{|x| x.name.underscore.to_sym}

    errors = 0
    # schema_file = Rails.root.join("lib", "ekylibre", "schema", "reference.rb")

    schema_hash = {}
    schema_yaml = "---\n"
    Ekylibre::Record::Base.connection.tables.sort.delete_if do |table|
      %w(schema_migrations spatial_ref_sys oauth_access_grants oauth_access_tokens oauth_applications).include?(table.to_s)
    end.each do |table|
      schema_hash[table] = {}
      schema_yaml << "\n#{table}:\n"
      columns = Ekylibre::Record::Base.connection.columns(table).sort{|a,b| a.name <=> b.name }
      max = columns.map(&:name).map(&:size).max + 1
      model = table.classify.constantize rescue nil
      for column in columns
        next if column.name =~ /\A\_/
        column_hash = {}
        schema_yaml << "  #{column.name}: {type: #{column.type}"
        column_hash[:type] = column.type.to_s
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
          unless val = Ekylibre::Schema.references(table, column)
            if column.name == "parent_id"
              val = model.name.underscore.to_sym
            elsif [:creator_id, :updater_id].include? column.name
              val = :user
            elsif columns.map(&:name).include?(reference_name.to_s + "_type")
              val = "~#{reference_name}_type"
            elsif symodels.include? reference_name
              val = reference_name
            elsif model and reflection = model.reflections[reference_name]
              val = reflection.class_name.underscore.to_sym
            end
          end
          errors += 1 if val.nil?
          schema_yaml << ", references: #{val.to_s}"
          column_hash[:references] = val
        end
        if column.type == :string and column.limit.to_i != 255
          schema_yaml << ", limit: #{column.limit}"
          column_hash[:limit] = column.limit
        end
        if column.null.is_a? FalseClass
          schema_yaml << ", required: true"
          column_hash[:required] = true
        end
        unless column.default.nil?
          if column.type == :string
            schema_yaml << ", default: #{column.default.inspect}"
          else
            schema_yaml << ", default: #{column.default.to_s}"
          end
          column_hash[:default] = column.default
        end
        schema_yaml << "}\n"
        schema_hash[table][column.name] = column_hash
      end.join(",\n").dig
    end.join(",\n").dig

    File.open(Ekylibre::Schema.root.join("tables.yml"), "wb") do |f|
      f.write(schema_yaml)
    end

    File.open(Ekylibre::Schema.root.join("models.yml"), "wb") do |f|
      f.write(models.collect{|m| m.name.underscore}.to_yaml)
    end

    puts "#{errors.to_s.rjust(3)} errors"
  end

end
