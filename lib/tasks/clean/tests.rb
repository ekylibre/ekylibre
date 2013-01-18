def write_functional_test_file(klass)
  code  = ""
  code << "require 'test_helper'\n"
  code << "class #{klass} < ActionController::TestCase\n"
  code << "  test_restfully_all_actions\n"
  code << "end\n"
  file = Rails.root.join("test", "functional", klass.underscore + ".rb")
  FileUtils.mkdir_p(file.dirname)
  File.open(file, "wb") do |f|
    f.write(code)
  end
end

def write_unit_test_file(klass)
  code  = ""
  code << "require 'test_helper'\n\n"
  code << "class #{klass} < ActiveSupport::TestCase\n\n"
  code << "  # Replace this with your real tests.'\n"
  code << "  test \"the truth\" do\n"
  code << "    assert true\n"
  code << "  end\n\n"
  code << "end\n"
  file = Rails.root.join("test", "unit", klass.underscore + ".rb")
  FileUtils.mkdir_p(file.dirname)
  File.open(file, "wb") do |f|
    f.write(code)
  end
end

desc "Analyze test files and report"
task :tests => :environment do
  log = File.open(Rails.root.join("log", "clean-tests.log"), "wb")

  print " - Tests: "
  errors = {:units => 0, :fixtures => 0, :functionals => 0} # , :unit_helpers => 0
  source = nil
  models      = models_in_file
  controllers = controllers_in_file

  # Check unit test files
  files = Dir.glob(Rails.root.join("test", "unit", "**", "*.rb")).delete_if{ |f| f.to_s.match(/^#{Rails.root.join('test', 'unit', 'helpers')}/) }.collect{|f| f.to_s}
  for model in models
    class_name = "#{model.name}Test"
    file = Rails.root.join("test", "unit", class_name.underscore + ".rb")
    if File.exist?(file)
      File.open(file, "rb") do |f|
        source = f.read
      end
      source.gsub!(/^\#[^\n]*\n/, '')
      unless source.match(/class\ +#{class_name}\ +/)
        errors[:units] += 1
        log.write(" - Error: Test file #{file} seems to be invalid. Class name #{class_name} expected but not found\n")
        if source.blank?
          write_unit_test_file(class_name)
          log.write("   > Empty test file has been writed: #{file}\n")
        end
      end
    else
      errors[:units] += 1
      log.write(" - Error: Test file #{file} is missing\n")
      # Create missing file
      write_unit_test_file(class_name)
      log.write("   > Test file has been created: #{file}\n")
    end
    files.delete(file.to_s)
  end


  # Check unit helper test files







  for file in files.sort
    errors[:units] += 1
    log.write(" - Error: Unexpected test file: #{file}\n")
  end
  if files.size > 0
    log.write("   > git rm #{files.join(' ')}\n")
  end


  # Check fixture files
  yaml = nil
  files = Dir.glob(Rails.root.join("test", "fixtures", "*.yml")).collect{|f| f.to_s}
  for model in models
    file = Rails.root.join("test", "fixtures", model.table_name + ".yml")
    if File.exist?(file)
      begin
        yaml = YAML.load_file(file)
      rescue Exception => e
        errors[:fixtures] += 1
        log.write(" - Error: Fixture file #{file} has a syntax error (#{e.message})\n")
        next
      end
      cols = model.columns.collect{|c| c.name.to_s}
      required_cols = model.columns.select{|c| !c.null and c.default.nil?}.collect{|c| c.name.to_s}
      if yaml.is_a?(Hash)
        for record_name, attributes in yaml
          requireds = required_cols.dup
          for attr_name, value in attributes
            unless cols.include?(attr_name.to_s)
              errors[:fixtures] += 1
              log.write(" - Errors: Column #{attr_name} is unknown in #{file}\n")
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

  # Check functional test files
  files = Dir.glob(Rails.root.join("test", "functional", "**", "*.rb")).collect{|f| f.to_s}
  for controller in controllers
    class_name = "#{controller.name}Test"
    file = Rails.root.join("test", "functional", class_name.underscore + ".rb")
    if File.exist?(file)
      File.open(file, "rb") do |f|
        source = f.read
      end
      source.gsub!(/^\#[^\n]*\n/, '')
      unless source.match(/class\ +#{class_name}\ +/)
        errors[:functionals] += 1
        log.write(" - Error: Test file #{file} seems to be invalid. Class name #{class_name} expected but not found\n")
        if source.blank?
          write_functional_test_file(class_name)
          log.write("   > Empty test file has been writed: #{file}\n")
        end
      end
    else
      errors[:functionals] += 1
      log.write(" - Error: Test file #{file} is missing\n")
      write_functional_test_file(class_name)
      log.write("   > Test file has been created: #{file}\n")
    end
    files.delete(file.to_s)
  end
  for file in files.sort
    errors[:functionals] += 1
    log.write(" - Error: Unexpected test files: #{file}\n")
  end
  if files.size > 0
    log.write("   > git rm #{files.join(' ')}\n")
  end

  puts " " + errors.collect{|k,v| "#{k.to_s.humanize}: #{v.to_s.rjust(3)} errors"}.join(", ")
  log.close
end

