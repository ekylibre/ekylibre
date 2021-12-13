require 'test_helper'

module Telepac
  module V2020
    class CapStatementsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        result = Telepac::V2020::CapStatementsExchanger.build(fixture_files_path.join('imports', 'telepac', 'v2020', 'cap_statements.xml')).run
        assert result.success?, [result.message, result.exception]
      end
    end
  end
end
