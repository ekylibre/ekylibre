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
        code << modularize(klass, 'ActionSupport::TestCase') do |c|
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
        code << modularize(klass, 'ActionJob::TestCase') do |c|
          c << "# Add tests here...\n"
        end
        file = Rails.root.join('test', 'jobs', klass.underscore + '.rb')
        FileUtils.mkdir_p(file.dirname)
        File.open(file, 'wb') do |f|
          f.write(code)
        end
      end

      def print_stat(name, count, _first = false)
        # print ", " unless first
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
        code = "module #{mod}\n"
        code << content.dig
        code << 'end'
        code
      end
    end
  end
end
