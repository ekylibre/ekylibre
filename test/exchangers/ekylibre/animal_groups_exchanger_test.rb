require 'test_helper'

module Ekylibre
  class AnimalGroupsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::AnimalGroupsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'animal_groups.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
