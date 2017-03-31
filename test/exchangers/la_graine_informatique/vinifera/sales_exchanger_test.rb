require 'test_helper'

module LaGraineInformatique
  module Vinifera
    class SalesExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        LaGraineInformatique::Vinifera::SalesExchanger.import(fixture_files_path.join('imports', 'la_graine_informatique', 'vinifera', 'sales.csv'))
      end
    end
  end
end
