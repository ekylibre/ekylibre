require 'test_helper'

module Ekylibre
  class AnimalGroupsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::AnimalGroupsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'animal_groups.csv'))
    end
  end
end
