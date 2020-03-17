require 'test_helper'

module LaGraineInformatique
  module Vinifera
    class EntitiesExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        result = LaGraineInformatique::Vinifera::EntitiesExchanger.build(fixture_files_path.join('imports', 'la_graine_informatique', 'vinifera', 'entities.zip')).run
        assert result.success?, [result.message, result.exception]
      end
    end
  end
end
