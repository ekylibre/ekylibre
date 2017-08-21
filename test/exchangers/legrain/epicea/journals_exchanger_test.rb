require 'test_helper'

module Legrain
  module Epicea
    class JournalsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        Legrain::Epicea::JournalsExchanger.import(fixture_files_path.join('imports', 'legrain', 'epicea', 'journals.txt'))
      end
    end
  end
end
