require 'test_helper'

module LaGraineInformatique
  module Vinifera
    class EntitiesExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        LaGraineInformatique::Vinifera::EntitiesExchanger.import(fixture_files_path.join('imports', 'la_graine_informatique', 'vinifera', 'entities.zip'))
      end
    end
  end
end
