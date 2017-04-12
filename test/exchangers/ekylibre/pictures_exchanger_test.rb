require 'test_helper'

module Ekylibre
  class PicturesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::PicturesExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'pictures.zip'))
    end
  end
end
