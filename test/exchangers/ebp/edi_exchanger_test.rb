require 'test_helper'

module EBP
  class EDIExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = EBP::EDIExchanger.build(fixture_files_path.join('imports', 'ebp', 'edi.edi')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
