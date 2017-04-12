require 'test_helper'

module UPRA
  class ReproductorsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      UPRA::ReproductorsExchanger.import(fixture_files_path.join('imports', 'upra', 'reproductors.txt'))
    end
  end
end
