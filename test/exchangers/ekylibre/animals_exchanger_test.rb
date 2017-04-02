require 'test_helper'

module Ekylibre
  class AnimalsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::AnimalsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'animals.csv'))
    end
  end
end
