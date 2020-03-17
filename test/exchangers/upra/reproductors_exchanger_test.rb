require 'test_helper'

module UPRA
  class ReproductorsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = UPRA::ReproductorsExchanger.build(fixture_files_path.join('imports', 'upra', 'reproductors.txt')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
