namespace :clean do
  task reflections: :environment do
    log = File.open(Rails.root.join('log', 'clean-reflections.log'), 'wb')
    Clean::Support.set_search_path!

    print ' - Reflections: '

    errors = 0
    warnings = 0
    Clean::Support.models_in_file.each do |model|
      reflections = model.reflect_on_all_associations(:has_many)
      reflections.each do |r|
        next if r.options[:through]
        # puts model.name.to_s + '.' + r.name.to_s
        # puts r.inspect.yellow
        dependent = r.options[:dependent]
        begin
          foreign_model = r.class_name.constantize
        rescue NameError => e
          log.write"Cannot find model: #{r.class_name} used in #{model.name}##{r.name}\n"
          errors += 1
          next
        end
        foreign_column = foreign_model.columns_hash[r.foreign_key.to_s]
        unless foreign_column
          log.write"Cannot find foreign key #{foreign_model.table_name}.#{r.foreign_key} used in #{model.name}##{r.name}\n"
          errors += 1
          next
        end
        if foreign_column.null
          unless dependent
            # log.write "No dependent option on #{model.name}##{r.name}\n"
            # warnings += 1
          end
        else
          if dependent.nil?
            next if reflections.detect { |b| r != b && b.options[:dependent] }
            log.write"Missing dependent option on #{model.name}##{r.name}\n"
            errors += 1
          elsif ![:destroy, :delete_all, :restrict_with_error, :restrict_with_exception].include?(dependent)
            next if reflections.detect { |b| r != b && [:destroy, :delete_all, :restrict_with_error, :restrict_with_exception].include?(b.options[:dependent]) }
            log.write"Invalid dependent option on #{model.name}##{r.name}: #{dependent}\n"
            errors += 1
          end
        end
      end
    end
    print "#{errors.to_s.rjust(3)} errors\n" # , #{warnings.to_s.rjust(3)} warnings
    log.close
  end
end
