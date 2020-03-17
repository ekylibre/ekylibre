require 'test_helper'

module Synel
  class AnimalsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Synel::AnimalsExchanger.build(fixture_files_path.join('imports', 'synel', 'animals.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
