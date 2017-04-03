require 'test_helper'

module Synel
  class AnimalsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Synel::AnimalsExchanger.import(fixture_files_path.join('imports', 'synel', 'animals.csv'))
    end
  end
end
