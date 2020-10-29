require 'test_helper'

module Legrain
  module Epicea
    class AccountsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        result = Legrain::Epicea::AccountsExchanger.build(fixture_files_path.join('imports', 'legrain', 'epicea', 'accounts.txt')).run
        assert result.success?, [result.message, result.exception]
      end
    end
  end
end
