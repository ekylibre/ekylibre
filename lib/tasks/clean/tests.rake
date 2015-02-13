namespace :clean do

  desc "Analyze test files and report"
  task :tests => :environment do
    Clean::Support.set_search_path!
    verbose = !ENV["VERBOSE"].to_i.zero?
    log = File.open(Rails.root.join("log", "clean-tests.log"), "wb")
    log.write(">> Init\n") if verbose

    errors = {models: 0, controllers: 0, helpers: 0, fixtures: 0}
    source = nil

    log.write(">> Start!\n") if verbose

    # Check model test files
    print " - Tests: "
    log.write(">> Search models\n") if verbose
    models      = Clean::Support.models_in_file
    files = Dir.glob(Rails.root.join("test", "models", "**", "*.rb")).map(&:to_s)
    for model in models
      log.write("> #{model}\n") if verbose
      class_name = "#{model.name}Test"
      file = Rails.root.join("test", "models", class_name.underscore + ".rb")
      if File.exist?(file)
        File.open(file, "rb") do |f|
          source = f.read
        end
        source.gsub!(/^\#[^\n]*\n/, '')
        unless source.match(/class\ +#{class_name}\ +/)
          errors[:models] += 1
          log.write(" - Error: Test file #{file} seems to be invalid. Class name #{class_name} expected but not found\n")
          if source.blank?
            Clean::Tests.write_model_test_file(class_name)
            log.write("   > Empty test file has been writed: #{file}\n")
          end
        end
      else
        errors[:models] += 1
        log.write(" - Error: Test file #{file} is missing\n")
        # Create missing file
        Clean::Tests.write_model_test_file(class_name)
        log.write("   > Test file has been created: #{file}\n")
      end
      files.delete(file.to_s)
    end
    for file in files.sort
      errors[:models] += 1
      log.write(" - Error: Unexpected test file: #{file}\n")
    end
    if files.any?
      log.write("   > git rm #{files.join(' ')}\n")
    end

    Clean::Tests.print_stat :models, errors, true


    # Check helper test files
    print " - Tests: "
    files = Dir.glob(Rails.root.join("test", "helpers", "**", "*_test.rb")).map(&:to_s)
    for helper_name in Clean::Support.helpers_in_file.to_a
      log.write("> #{helper_name}\n")  if verbose
      test_class_name = (helper_name + "_test").classify
      file = Rails.root.join("test", "helpers", (test_class_name + ".rb").underscore)
      if File.exist?(file)
        File.open(file, "rb") do |f|
          source = f.read
        end
        source.gsub!(/^\#[^\n]*\n/, '')
        unless source.match(/class\ +#{test_class_name}\ +/)
          errors[:helpers] += 1
          log.write(" - Error: Test file #{file} seems to be invalid. Class name #{test_class_name} expected but not found\n")
          if source.blank?
            Clean::Tests.write_helper_test_file(test_class_name)
            log.write("   > Empty test file has been writed: #{file}\n")
          end
        end
      else
        errors[:helpers] += 1
        log.write(" - Error: Test file #{file} is missing\n")
        # Create missing file
        Clean::Tests.write_helper_test_file(test_class_name)
        log.write("   > Test file has been created: #{file}\n")
      end
      files.delete(file.to_s)
    end
    for file in files.sort
      errors[:helpers] += 1
      log.write(" - Error: Unexpected test file: #{file}\n")
    end
    if files.any?
      log.write("   > git rm #{files.join(' ')}\n")
    end

    Clean::Tests.print_stat :helpers, errors


    # Check controller test files
    print " - Tests: "
    log.write(">> Search controllers\n") if verbose
    controllers = Clean::Support.controllers_in_file
    files = Dir.glob(Rails.root.join("test", "controllers", "**", "*.rb")).collect{|f| f.to_s}
    for controller in controllers
      log.write("> #{controller}\n") if verbose
      class_name = "#{controller.name}Test"
      file = Rails.root.join("test", "controllers", class_name.underscore + ".rb")
      if File.exist?(file)
        File.open(file, "rb") do |f|
          source = f.read
        end
        source.gsub!(/^\#[^\n]*\n/, '')
        unless source.match(/class\ +#{class_name}\ +/)
          errors[:controllers] += 1
          log.write(" - Error: Test file #{file} seems to be invalid. Class name #{class_name} expected but not found\n")
          if source.blank?
            Clean::Tests.write_controller_test_file(class_name)
            log.write("   > Empty test file has been writed: #{file}\n")
          end
        end
      else
        errors[:controllers] += 1
        log.write(" - Error: Test file #{file} is missing\n")
        Clean::Tests.write_controller_test_file(class_name)
        log.write("   > Test file has been created: #{file}\n")
      end
      files.delete(file.to_s)
    end
    for file in files.sort
      errors[:controllers] += 1
      log.write(" - Error: Unexpected test files: #{file}\n")
    end
    if files.any?
      log.write("   > git rm #{files.join(' ')}\n")
    end
    Clean::Tests.print_stat :controllers, errors

    # Check fixture files
    print " - Tests: "
    yaml = nil
    files = Dir.glob(Rails.root.join("test", "fixtures", "*.yml")).map(&:to_s)
    for table, columns in Ekylibre::Schema.tables
      next unless columns.keys.include?("id")
      log.write("> fixtures #{table}\n") if verbose
      file = Rails.root.join("test", "fixtures", "#{table}.yml")
      if File.exist?(file)
        begin
          yaml = YAML.load_file(file)
        rescue Exception => e
          errors[:fixtures] += 1
          log.write(" - Error: Fixture file #{file} has a syntax error (#{e.message})\n")
          next
        end

        model = table.singularize.camelize.constantize
        attributes  = columns.keys.map(&:to_s)

        required_attributes = columns.values.select{|c| !c.null? and c.default.nil?}.map(&:name).map(&:to_s)

        if yaml.is_a?(Hash)
          if yaml.keys.size != yaml.keys.uniq.size
            errors[:fixtures] += 1
            log.write(" - Error: Duplicates record labels in #{file}\n")
          end

          for record_name, values in yaml
            requireds = required_attributes.dup
            for attribute, value in values
              unless attributes.include?(attribute)
                errors[:fixtures] += 1
                log.write(" - Errors: Attribute #{attribute} is unknown in #{file}\n")
              end
              requireds.delete(attribute)
            end
            for attribute in requireds
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
        # Create missing file
        File.open(file, "wb") do |f|
          f.write("# Auto-generated\n")
        end
        log.write("   > Fixture file has been created: #{file}\n")
      end
      files.delete(file.to_s)
    end
    for file in files.sort
      errors[:fixtures] += 1
      log.write(" - Error: Unexpected fixture file: #{file}\n")
    end
    if files.any?
      log.write("   > git rm #{files.join(' ')}\n")
    end

    Clean::Tests.print_stat :fixtures, errors

    # puts " " + errors.collect{|k,v| "#{k.to_s.humanize}: #{v.to_s.rjust(3)} errors"}.join(", ")
    # puts ""
    log.close
  end

end
