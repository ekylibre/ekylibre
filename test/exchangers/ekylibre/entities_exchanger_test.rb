require 'test_helper'

module Ekylibre
  class EntitiesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::EntitiesExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'entities.csv'))
    end
  end
end
