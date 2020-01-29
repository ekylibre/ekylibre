require 'test_helper'

module Ekylibre
  class AnimalsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::AnimalsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'animals.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
