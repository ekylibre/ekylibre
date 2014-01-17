def write_controller_test_file(klass)
  code  = ""
  code << "require 'test_helper'\n"
  code << "class #{klass} < ActionController::TestCase\n"
  code << "  test_restfully_all_actions\n"
  code << "end\n"
  file = Rails.root.join("test", "controllers", klass.underscore + ".rb")
  FileUtils.mkdir_p(file.dirname)
  File.open(file, "wb") do |f|
    f.write(code)
  end
end

def write_model_test_file(klass)
  code  = ""
  code << "require 'test_helper'\n\n"
  code << "class #{klass} < ActiveSupport::TestCase\n\n"
  code << "  # Replace this with your real tests.'\n"
  code << "  test \"the truth\" do\n"
  code << "    assert true\n"
  code << "  end\n\n"
  code << "end\n"
  file = Rails.root.join("test", "models", klass.underscore + ".rb")
  FileUtils.mkdir_p(file.dirname)
  File.open(file, "wb") do |f|
    f.write(code)
  end
end

def write_helper_test_file(klass)
  code  = ""
  code << "require 'test_helper'\n\n"
  code << "class #{klass} < ActionView::TestCase\n\n"
  code << "  # Replace this with your real tests.'\n"
  code << "  test \"the truth\" do\n"
  code << "    assert true\n"
  code << "  end\n\n"
  code << "end\n"
  file = Rails.root.join("test", "helpers", klass.underscore + ".rb")
  FileUtils.mkdir_p(file.dirname)
  File.open(file, "wb") do |f|
    f.write(code)
  end
end

def print_stat(name, count, first = false)
  print ", " unless first
  count = count[name] if count.is_a?(Hash)
  print "#{name.to_s.humanize}: #{count.to_s} errors"
end


desc "Analyze test files and report"
task :tests => :environment do
  verbose = !ENV["VERBOSE"].to_i.zero?
  log = File.open(Rails.root.join("log", "clean-tests.log"), "wb")
  log.write(">> Init\n") if verbose

  print " - Tests: "
  errors = {:models => 0, :controllers => 0, :helpers => 0, :fixtures => 0}
  source = nil
  log.write(">> Search models\n") if verbose
  models      = CleanSupport.models_in_file
  log.write(">> Search controllers\n") if verbose
  controllers = CleanSupport.controllers_in_file

  log.write(">> Start!\n") if verbose

  # Check model test files
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
          write_model_test_file(class_name)
          log.write("   > Empty test file has been writed: #{file}\n")
        end
      end
    else
      errors[:models] += 1
      log.write(" - Error: Test file #{file} is missing\n")
      # Create missing file
      write_model_test_file(class_name)
      log.write("   > Test file has been created: #{file}\n")
    end
    files.delete(file.to_s)
  end
  for file in files.sort
    errors[:models] += 1
    log.write(" - Error: Unexpected test file: #{file}\n")
  end
  if files.size > 0
    log.write("   > git rm #{files.join(' ')}\n")
  end

  print_stat :models, errors, true


  # Check helper test files
  files = Dir.glob(Rails.root.join("test", "helpers", "**", "*_test.rb")).map(&:to_s)
  for helper_name in CleanSupport.helpers_in_file.to_a
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
          write_helper_test_file(test_class_name)
          log.write("   > Empty test file has been writed: #{file}\n")
        end
      end
    else
      errors[:helpers] += 1
      log.write(" - Error: Test file #{file} is missing\n")
      # Create missing file
      write_helper_test_file(test_class_name)
      log.write("   > Test file has been created: #{file}\n")
    end
    files.delete(file.to_s)
  end
  for file in files.sort
    errors[:helpers] += 1
    log.write(" - Error: Unexpected test file: #{file}\n")
  end
  if files.size > 0
    log.write("   > git rm #{files.join(' ')}\n")
  end

  print_stat :helpers, errors


  # Check controller test files
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
          write_controller_test_file(class_name)
          log.write("   > Empty test file has been writed: #{file}\n")
        end
      end
    else
      errors[:controllers] += 1
      log.write(" - Error: Test file #{file} is missing\n")
      write_controller_test_file(class_name)
      log.write("   > Test file has been created: #{file}\n")
    end
    files.delete(file.to_s)
  end
  for file in files.sort
    errors[:controllers] += 1
    log.write(" - Error: Unexpected test files: #{file}\n")
  end
  if files.size > 0
    log.write("   > git rm #{files.join(' ')}\n")
  end
  print_stat :controllers, errors

  # Check fixture files
  yaml = nil
  files = Dir.glob(Rails.root.join("test", "fixtures", "*.yml")).collect{|f| f.to_s}
  for table, columns in Ekylibre::Schema.tables
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

      cols = columns.keys.map(&:to_s)
      required_cols = columns.values.select{|c| !c.null? and c.default.nil?}.collect{|c| c.name.to_s}
      dr_cols = columns.values.inject({}.with_indifferent_access) do |hash, col|
        if col.references?
          reflection_name = col.name.to_s.gsub(/_id$/, '')
          hash[reflection_name] = [col.name.to_s]
          hash[reflection_name] << col.references if col.polymorphic?
        end
        hash
      end

      if yaml.is_a?(Hash)
        ids = yaml.collect{|k,v| v["id"]}
        if ids.compact.any?
          if ids.uniq.size != ids.size
            errors[:fixtures] += 1
            log.write(" - Error: Duplicates id values in #{file}\n")
          end
        end

        for record_name, attributes in yaml
          requireds = required_cols.dup
          for attr_name, value in attributes
            unless cols.include?(attr_name.to_s) or dr_cols[attr_name]
              errors[:fixtures] += 1
              log.write(" - Errors: Column #{attr_name} is unknown in #{file}\n")
            end
            if dr_cols[attr_name].is_a?(Array)
              dr_cols[attr_name].each{|n| requireds.delete(n)}
            end
            requireds.delete(attr_name.to_s)
          end
          for col in requireds
            errors[:fixtures] += 1
            log.write(" - Errors: Missing required column #{col} in #{file}\n")
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
  if files.size > 0
    log.write("   > git rm #{files.join(' ')}\n")
  end

  print_stat :fixtures, errors

  # puts " " + errors.collect{|k,v| "#{k.to_s.humanize}: #{v.to_s.rjust(3)} errors"}.join(", ")
  puts ""
  log.close
end

