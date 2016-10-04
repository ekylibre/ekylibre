module Clean
  module Tests
    class << self
      def write_controller_test_file(klass)
        code = ''
        code << "require 'test_helper'\n"
        code << modularize(klass, 'ActionController::TestCase') do |c|
          c << "test_restfully_all_actions\n"
        end
        file = Rails.root.join('test', 'controllers', klass.underscore + '.rb')
        FileUtils.mkdir_p(file.dirname)
        File.open(file, 'wb') do |f|
          f.write(code)
        end
      end

      def write_model_test_file(klass)
        code = ''
        code << "require 'test_helper'\n\n"
        code << modularize(klass, 'ActiveSupport::TestCase') do |c|
          c << "# Add tests here...\n"
        end
        file = Rails.root.join('test', 'models', klass.underscore + '.rb')
        FileUtils.mkdir_p(file.dirname)
        File.open(file, 'wb') do |f|
          f.write(code)
        end
      end

      def write_helper_test_file(klass)
        code = ''
        code << "require 'test_helper'\n\n"
        code << modularize(klass, 'ActionView::TestCase') do |c|
          c << "# Add tests here...\n"
        end
        file = Rails.root.join('test', 'helpers', klass.underscore + '.rb')
        FileUtils.mkdir_p(file.dirname)
        File.open(file, 'wb') do |f|
          f.write(code)
        end
      end

      def write_job_test_file(klass)
        code = ''
        code << "require 'test_helper'\n\n"
        code << modularize(klass, 'ActiveJob::TestCase') do |c|
          c << "# Add tests here...\n"
        end
        file = Rails.root.join('test', 'jobs', klass.underscore + '.rb')
        FileUtils.mkdir_p(file.dirname)
        File.open(file, 'wb') do |f|
          f.write(code)
        end
      end

      # Check Class test for a dir in app/<name>
      # Check mirror test in test/<name>/
      def check_class_test(name, log, verbose = true)
        errors_count = 0
        tests_dir = Rails.root.join('test', name)
        files = Dir.glob(tests_dir.join('**', '*_test.rb')).map(&:to_s)
        write_method = "write_#{name.singularize}_test_file".to_sym
        log.write("> Search for #{name}...\n") if verbose
        classes = Clean::Support.send("#{name}_in_file")
        log.write("> Check #{classes.count} #{name}\n")
        classes.each do |class_name|
          class_name = class_name.name unless class_name.is_a?(String)
          log.write("> #{class_name}\n") if verbose
          test_class_name = (class_name + '_test').classify
          file = tests_dir.join((test_class_name + '.rb').underscore)
          file_label = file.relative_path_from(Rails.root).to_s
          if File.exist?(file)
            source = File.read(file)
            source.gsub!(/^\#[^\n]*\n/, '')
            if source.blank?
              Clean::Tests.send(write_method, test_class_name)
              errors_count += 1
              log.write("   > Empty test file has been writed: #{file}\n")
            elsif !Clean::Tests.check_class_presence(test_class_name, source)
              errors_count += 1
              log.write(" - Error: Test file #{file_label} seems to be invalid. Class name #{test_class_name} expected but not found\n")
            end
          else
            errors_count += 1
            log.write(" - Error: Test file #{file_label} is missing\n")
            # Create missing file
            Clean::Tests.send(write_method, test_class_name)
            log.write("   > Test file has been created: #{file_label}\n")
          end
          files.delete(file.to_s)
        end
        files.sort.each do |file|
          errors_count += 1
          log.write(" - Error: Unexpected test file: #{Pathname.new(file).relative_path_from(Rails.root)}\n")
        end
        log.write("   > git rm #{files.join(' ')}\n") if files.any?
        errors_count
      end

      # Read source to determine if class with given name is present
      def check_class_presence(class_name, source)
        # Look for raw
        return true if source =~ /class\ +#{class_name}\ +/

        # Look for clean
        compounds = class_name.split('::')
        if compounds.size > 1
          # TODO: More reliability shoud be appreciable
          compounds.each_with_index do |name, depth|
            return false unless source =~ /^#{'  ' * depth}(module|class)\s+#{name}(\s+|\s*\<|$)/
          end
          return true
        end

        false
      end

      def print_stat(name, count)
        count = count[name] if count.is_a?(Hash)
        puts "#{count.to_s.rjust(3, ' ')} errors on #{name}"
      end

      def modularize(class_name, parent = nil)
        modules = class_name.split('::')
        klass = modules.delete_at(-1)
        wrap_module(modules) do |c|
          c << "class #{klass}"
          c << " < #{parent}" if parent
          c << "\n"
          content = ''
          yield content
          c << content.dig
          c << 'end'
        end
      end

      def wrap_module(mods, &block)
        mod = mods.shift
        content = ''
        if mods.any?
          content = wrap_module(mods, &block)
        else
          yield content
        end
        return content if mod.nil?
        code = "module #{mod}\n"
        code << content.dig
        code << 'end'
        code
      end
    end
  end
end
