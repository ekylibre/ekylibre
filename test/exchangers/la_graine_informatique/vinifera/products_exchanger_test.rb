require 'test_helper'

module LaGraineInformatique
  module Vinifera
    class ProductsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        result = LaGraineInformatique::Vinifera::ProductsExchanger.build(fixture_files_path.join('imports', 'la_graine_informatique', 'vinifera', 'products.zip')).run
        assert result.success?, [result.message, result.exception]
      end
    end
  end
end
