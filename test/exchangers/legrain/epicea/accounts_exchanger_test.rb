require 'test_helper'

module Legrain
  module Epicea
    class AccountsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        Legrain::Epicea::AccountsExchanger.import(fixture_files_path.join('imports', 'legrain', 'epicea', 'accounts.txt'))
      end
    end
  end
end
