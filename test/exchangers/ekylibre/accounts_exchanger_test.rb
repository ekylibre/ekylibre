require 'test_helper'

module Ekylibre
  class AccountsExchangerTest < ::ActiveExchanger::TestCase
    test 'import' do
      ::ActiveExchanger::Base.import(:ekylibre_accounts, fixture_files_path.join('imports', 'ekylibre_accounts.csv'))
    end
  end
end
