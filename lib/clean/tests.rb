module Clean
  module Tests
    class << self
      def write_controller_test_file(klass)
        code = ''
        code << "require 'test_helper'\n"
        code << "class #{klass} < ActionController::TestCase\n"
        code << "  test_restfully_all_actions\n"
        code << "end\n"
        file = Rails.root.join('test', 'controllers', klass.underscore + '.rb')
        FileUtils.mkdir_p(file.dirname)
        File.open(file, 'wb') do |f|
          f.write(code)
        end
      end

      def write_model_test_file(klass)
        code = ''
        code << "require 'test_helper'\n\n"
        code << "class #{klass} < ActiveSupport::TestCase\n"
        code << "  # Add tests here...\n"
        code << "end\n"
        file = Rails.root.join('test', 'models', klass.underscore + '.rb')
        FileUtils.mkdir_p(file.dirname)
        File.open(file, 'wb') do |f|
          f.write(code)
        end
      end

      def write_helper_test_file(klass)
        code = ''
        code << "require 'test_helper'\n\n"
        code << "class #{klass} < ActionView::TestCase\n\n"
        code << "  # Add tests here...\n"
        code << "end\n"
        file = Rails.root.join('test', 'helpers', klass.underscore + '.rb')
        FileUtils.mkdir_p(file.dirname)
        File.open(file, 'wb') do |f|
          f.write(code)
        end
      end

      def write_job_test_file(klass)
        code = ''
        code << "require 'test_helper'\n\n"
        code << "class #{klass} < ActiveJob::TestCase\n"
        code << "  # Add tests here...\n"
        code << "end\n"
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
    end
  end
end
