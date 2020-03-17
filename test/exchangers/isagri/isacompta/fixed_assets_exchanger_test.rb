require 'test_helper'

module Isagri
  module Isacompta
    class FixedAssetsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        result = Isagri::Isacompta::FixedAssetsExchanger.build(fixture_files_path.join('imports', 'isagri', 'isacompta', 'fixed_assets.csv')).run
        assert result.success?, [result.message, result.exception]
      end

      test 'change account_number into allocation_account_number' do
        accounts = %w(20500000 13100000 21100000)
        allocation_accounts = accounts.map { |account| Isagri::Isacompta::FixedAssetsExchanger.to_allocation_account(account) }
        assert_equal 3, allocation_accounts.size
        assert allocation_accounts.first, "28050000"
        assert allocation_accounts[1], "13100000"
        assert allocation_accounts.last, "21100000"
      end
    end
  end
end
