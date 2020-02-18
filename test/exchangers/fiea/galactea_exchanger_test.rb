require 'test_helper'

module FIEA
  class GalacteaExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = FIEA::GalacteaExchanger.build(fixture_files_path.join('imports', 'fiea', 'galactea.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
