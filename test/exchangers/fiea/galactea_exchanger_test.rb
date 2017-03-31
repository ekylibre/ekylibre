require 'test_helper'

module FIEA
  class GalacteaExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      FIEA::GalacteaExchanger.import(fixture_files_path.join('imports', 'fiea', 'galactea.csv'))
    end
  end
end
