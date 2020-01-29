require 'test_helper'

module LaGraineInformatique
  module Vinifera
    class SalesExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        result = LaGraineInformatique::Vinifera::SalesExchanger.build(fixture_files_path.join('imports', 'la_graine_informatique', 'vinifera', 'sales.csv')).run
        assert result.success?, [result.message, result.exception]
      end
    end
  end
end
