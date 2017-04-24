require 'test_helper'

module EBP
  class EDIExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      EBP::EDIExchanger.import(fixture_files_path.join('imports', 'ebp', 'edi.edi'))
    end
  end
end
