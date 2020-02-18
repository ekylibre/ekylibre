require 'test_helper'

module Ekylibre
  class AccountsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::AccountsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'accounts.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
