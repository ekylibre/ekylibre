require 'terminfo'

module Ekylibre
  module Testing
    class SpecReporter < Minitest::Reporters::SpecReporter
      attr_reader :test_size

      def initialize(options = {})
        super
        begin
          update_test_size
          Signal.trap('SIGWINCH', proc { update_test_size })
        rescue
          puts "No tty"
        end
      end

      def update_test_size
        @test_size = TermInfo.screen_columns - 20
      end

      def pad_test(str)
        pad("%-#{test_size}s" % str, TEST_PADDING)
      end
    end
  end
end
