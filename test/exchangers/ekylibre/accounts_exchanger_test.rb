require 'test_helper'

module Ekylibre
  class AccountsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::AccountsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'accounts.csv'))
    end
  end
end
