namespace :clean do
  desc 'Update models list file in db/models.yml and db/tables.yml'
  task schema: :environment do
    print ' - Schema: '

    Clean::Support.set_search_path!

    models = Clean::Support.models_in_file

    symodels = models.collect { |x| x.name.underscore.to_sym }

    errors = 0

    schema_hash = {}

    table_name_to_class = ActiveRecord::Base.descendants.reject(&:abstract_class).index_by(&:table_name)

    ApplicationRecord.connection.tables.sort.delete_if do |table|
      %w[schema_migrations spatial_ref_sys oauth_access_grants oauth_access_tokens oauth_applications].include?(table.to_s)
    end.each do |table|
      schema_hash[table] = {}
      columns = ApplicationRecord.connection.columns(table).sort_by(&:name)
      max = columns.map(&:name).map(&:size).max + 1
      model = begin
                table.classify.constantize
              rescue
                table_name_to_class[table]
              end
      columns.each do |column|
        next if column.name.start_with?('_')

        column_hash = { type: column.type.to_s }

        if column.type == :decimal
          if column.precision
            column_hash[:precision] = column.precision
          end
          if column.scale
            column_hash[:scale] = column.scale
          end
        end
        if column.name.end_with?('_id') && column.type != :string
          reference_name = column.name.to_s[0..-4].to_sym
          unless val = Ekylibre::Schema.references(table, column)
            if column.name == 'parent_id'
              val = model.name.underscore.to_sym
            elsif %i[creator_id updater_id].include? column.name
              val = :user
            elsif columns.map(&:name).include?(reference_name.to_s + '_type')
              val = "~#{reference_name}_type"
            elsif symodels.include? reference_name
              val = reference_name
            elsif model && reflection = model.reflect_on_association(reference_name)
              val = reflection.class_name.underscore.to_sym
            elsif model && reflection = model.reflections.values.detect { |r| r.macro == :belongs_to && r.foreign_key == column.name.to_sym }
              val = reflection.class_name.underscore.to_sym
            elsif model && child = model.descendants.detect { |c| c.reflect_on_association(reference_name) }
              reflection = child.reflect_on_association(reference_name)
              val = reflection.class_name.underscore.to_sym
            end
          end
          if val.nil? && table.start_with?("registered_", "master_")
          else
            errors += 1 if val.nil?
            column_hash[:references] = val.to_s
          end
        end
        if column.limit
          column_hash[:limit] = column.limit
        end
        if column.null.is_a? FalseClass
          column_hash[:required] = true
        end
        unless column.default.nil?
          if column.type == :string
            column_hash[:default] = column.default
          end
          if column.type == :boolean
            column_hash[:default] = column.default != 'false'
          end
        end
        schema_hash[table][column.name] = column_hash.deep_stringify_keys
      end.join(",\n").dig
    end.join(",\n").dig

    File.open(Ekylibre::Schema.root.join('tables.yml'), 'wb') do |f|
      f.write(schema_hash.to_yaml)
    end

    File.open(Ekylibre::Schema.root.join('models.yml'), 'wb') do |f|
      f.write(models.collect { |m| m.name.underscore }.uniq.sort.to_yaml)
    end

    Ekylibre::Schema.reset!

    puts "#{errors.to_s.rjust(3)} errors"
  end
end
