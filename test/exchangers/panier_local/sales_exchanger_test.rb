require 'test_helper'

module PanierLocal
  class SalesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      PanierLocal::SalesExchanger.import(fixture_files_path.join('imports', 'panier_local', 'panier_local_sales.csv'))
      assert_equal 45, SaleNature.find_by(name: "Vente en ligne - Panier Local").sales.count
    end
  end
end
