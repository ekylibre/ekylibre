require 'test_helper'

module LaGraineInformatique
  module Vinifera
    class ProductsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        LaGraineInformatique::Vinifera::ProductsExchanger.import(fixture_files_path.join('imports', 'la_graine_informatique', 'vinifera', 'products.zip'))
      end
    end
  end
end
