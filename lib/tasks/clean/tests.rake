namespace :clean do
  desc 'Analyze test files and report'
  task tests: :environment do
    Clean::Support.set_search_path!
    verbose = !ENV['VERBOSE'].to_i.zero?
    log = File.open(Rails.root.join('log', 'clean-tests.log'), 'wb')
    log.write(">> Init\n") if verbose

    errors = { fixtures: 0 }
    source = nil

    log.write(">> Start!\n") if verbose

    # Check model test files
    print ' - Tests: '
    errors[:models] = Clean::Tests.check_class_test('models', log, verbose)
    Clean::Tests.print_stat :models, errors

    # Check helper test files
    print ' - Tests: '
    errors[:helpers] = Clean::Tests.check_class_test('helpers', log, verbose)
    Clean::Tests.print_stat :helpers, errors

    # Check controller test files
    print ' - Tests: '
    errors[:controllers] = Clean::Tests.check_class_test('controllers', log, verbose)
    Clean::Tests.print_stat :controllers, errors

    # Check job test files
    print ' - Tests: '
    errors[:jobs] = Clean::Tests.check_class_test('jobs', log, verbose)
    Clean::Tests.print_stat :jobs, errors

    # Check fixture files
    print ' - Tests: '
    yaml = nil
    files = Dir.glob(Rails.root.join('test', 'fixtures', '*.yml')).map(&:to_s)
    Ekylibre::Schema.tables.each do |table, columns|
      next unless columns.keys.include?('id')
      log.write("> fixtures #{table}\n") if verbose
      file = Rails.root.join('test', 'fixtures', "#{table}.yml")
      if File.exist?(file)
        begin
          yaml = YAML.load_file(file)
        rescue Exception => e
          errors[:fixtures] += 1
          log.write(" - Error: Fixture file #{file} has a syntax error (#{e.message})\n")
          next
        end

        model = table.singularize.camelize.constantize
        attributes = columns.keys.map(&:to_s)

        required_attributes = columns.values.select { |c| !c.null? && c.default.nil? }.map(&:name).map(&:to_s)

        if yaml.is_a?(Hash)
          if yaml.keys.size != yaml.keys.uniq.size
            errors[:fixtures] += 1
            log.write(" - Error: Duplicates record labels in #{file}\n")
          end

          yaml.each do |_record_name, values|
            requireds = required_attributes.dup
            values.each do |attribute, _value|
              unless attributes.include?(attribute)
                errors[:fixtures] += 1
                log.write(" - Errors: Attribute #{attribute} is unknown in #{file}\n")
              end
              requireds.delete(attribute)
            end
            requireds.each do |attribute|
              errors[:fixtures] += 1
              log.write(" - Errors: Missing required attribute #{attribute} in #{file}\n")
            end
          end
        else
          errors[:fixtures] += 1
          log.write(" - Warning: Fixture file #{file} is empty\n")
        end
      else
        errors[:fixtures] += 1
        log.write(" - Error: Fixture file #{file} is missing\n")
        # # Create missing file
        # File.open(file, "wb") do |f|
        #   f.write("# Auto-generated\n")
        # end
        # log.write("   > Fixture file has been created: #{file}\n")
      end
      files.delete(file.to_s)
    end
    files.sort.each do |file|
      errors[:fixtures] += 1
      log.write(" - Error: Unexpected fixture file: #{file}\n")
    end
    log.write("   > git rm #{files.join(' ')}\n") if files.any?

    Clean::Tests.print_stat :fixtures, errors

    # puts " " + errors.collect{|k,v| "#{k.to_s.humanize}: #{v.to_s.rjust(3)} errors"}.join(", ")
    # puts ""
    log.close
  end
end
