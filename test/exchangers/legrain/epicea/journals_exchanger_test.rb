require 'test_helper'

module Legrain
  module Epicea
    class JournalsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        result = Legrain::Epicea::JournalsExchanger.build(fixture_files_path.join('imports', 'legrain', 'epicea', 'journals.txt')).run
        assert result.success?, [result.message, result.exception]
      end
    end
  end
end
